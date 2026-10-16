"""Check the shipped files and reproduce the RGB pixels of all seven approved PNGs."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
from urllib.parse import unquote

import numpy as np
from PIL import Image

from export import ROOT, SIZE, render_pixels


class GalleryLinks(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src') and value and not value.startswith(('http:', 'https:', '#')):
                if not (ROOT / unquote(value)).is_file():
                    raise ValueError(f'Broken gallery link: {value}')


def main():
    manifest = json.loads((ROOT / 'manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['slides']) == 7
    assert len(list((ROOT / 'final/PNG').glob('*.png'))) == 7
    assert len(list((ROOT / 'final/JPEG').glob('*.jpg'))) == 7
    for entry in manifest['slides']:
        for kind in ['png', 'jpeg', 'master']:
            path = ROOT / entry[kind]
            assert hashlib.sha256(path.read_bytes()).hexdigest() == entry[kind + '_sha256'], path
            with Image.open(path) as image:
                assert image.size == SIZE, path
                image.verify()
        expected = render_pixels(ROOT / entry['master'], entry['seed'])
        with Image.open(ROOT / entry['png']) as image:
            actual = np.asarray(image.convert('RGB'))
        assert np.array_equal(expected, actual), f"Unexpected pixel changes on slide {entry['slide']}"
        print(f"Slide {entry['slide']:02}: hashes, dimensions and exact grain pixels OK", flush=True)
    GalleryLinks().feed((ROOT / 'Galerie.html').read_text(encoding='utf-8'))
    for prompt_file in (ROOT / 'prompts').glob('*.json'):
        for job in json.loads(prompt_file.read_text(encoding='utf-8')):
            for ref in job['reference_inputs']:
                assert (ROOT / ref).is_file(), ref
            if job.get('generated_source'):
                assert (ROOT / job['generated_source']).is_file(), job['generated_source']
    print('PASS: seven approved slides, gallery links, and all prompt references.')


if __name__ == '__main__':
    main()
