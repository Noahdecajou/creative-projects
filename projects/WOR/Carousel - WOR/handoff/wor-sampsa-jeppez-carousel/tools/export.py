"""Export seven clean masters with the approved deterministic 3% grain."""
from pathlib import Path
import argparse
import json

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SIZE = (1080, 1440)


class SeededRandom:
    """Compatibility sequence used by seeded System.Random in the original export."""
    def __init__(self, seed):
        limit = 2147483647
        mj = (161803398 - abs(seed)) % limit
        self.state = [0] * 56
        self.state[55] = mj
        mk = 1
        for i in range(1, 55):
            ii = (21 * i) % 55
            self.state[ii] = mk
            mk = (mj - mk) % limit
            mj = self.state[ii]
        for _ in range(4):
            for i in range(1, 56):
                self.state[i] = (self.state[i] - self.state[1 + (i + 30) % 55]) % limit
        self.index = 0
        self.other = 21

    def samples(self, count):
        state = self.state
        index, other = self.index, self.other
        for _ in range(count):
            index = index + 1 if index < 55 else 1
            other = other + 1 if other < 55 else 1
            value = state[index] - state[other]
            if value == 2147483647:
                value -= 1
            if value < 0:
                value += 2147483647
            state[index] = value
            yield value * (1.0 / 2147483647)
        self.index, self.other = index, other


def render_pixels(master, seed):
    with Image.open(master) as image:
        if image.size != SIZE:
            raise ValueError(f'{master.name}: expected {SIZE}, found {image.size}')
        rgb = np.asarray(image.convert('RGB'), dtype=np.int16)
    width, height = SIZE
    random = np.fromiter(SeededRandom(seed).samples(width * height), dtype=np.float64, count=width * height)
    raw = (random * 2.0 - 1.0) * 255.0 * 0.03
    noise = (np.sign(raw) * np.floor(np.abs(raw) + 0.5)).astype(np.int16).reshape(height, width, 1)
    return np.clip(rgb + noise, 0, 255).astype(np.uint8)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--masters', type=Path, default=ROOT / 'masters/clean')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    masters, output = args.masters.resolve(), args.output.resolve()
    if output.exists():
        parser.error('Output already exists; choose a new version directory.')
    for protected in ['final', 'masters', 'references', 'history', 'fonts']:
        if output.is_relative_to(ROOT / protected):
            parser.error('Choose an output outside the shipped source directories.')
    inputs = [masters / f'Slide-{i:02}-before-grain.png' for i in range(1, 8)]
    for path in inputs:
        with Image.open(path) as image:
            if image.size != SIZE:
                parser.error(f'{path}: incorrect dimensions')
    (output / 'PNG').mkdir(parents=True)
    (output / 'JPEG').mkdir()
    for i, source in enumerate(inputs, 1):
        image = Image.fromarray(render_pixels(source, 20261013 + i))
        image.save(output / f'PNG/Slide-{i:02}.png')
        image.save(output / f'JPEG/Slide-{i:02}.jpg', quality=96, subsampling=0)
        print(f'Slide {i:02} exported', flush=True)
    (output / 'export.json').write_text(json.dumps({
        'count': 7, 'dimensions': SIZE, 'grain_percent': 3,
        'method': 'uniform monochrome, one pass', 'seeds': list(range(20261014, 20261021))
    }, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
