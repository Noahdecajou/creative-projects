from pathlib import Path
from PIL import Image
import colorsys
import json
from collections import Counter

root = Path(__file__).resolve().parent
results = []
for path in sorted((root / 'Design - Ref').iterdir()):
    if path.suffix.lower() not in {'.png', '.jpg', '.jpeg'}:
        continue
    with Image.open(path) as source:
        size = source.size
        metadata = {k: str(v)[:300] for k, v in source.info.items() if k in {'Software', 'software', 'Description', 'description', 'Comment', 'comment'}}
        im = source.convert('RGB')
        im.thumbnail((270, 480))
        counts = Counter()
        for r, g, b in im.getdata():
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if v < 0.45:
                group = 'fond_sombre_et_petrole'
            elif s <= 0.18 and v >= 0.70:
                group = 'blanc_et_gris_clair'
            elif 0.43 <= h <= 0.60 and s > 0.35:
                group = 'cyan_et_bleu_lumineux'
            else:
                group = 'tons_intermediaires'
            counts[group] += 1
        total = sum(counts.values())
        palette = im.quantize(colors=8).convert('RGB').getcolors(im.width * im.height)
        results.append({'file': path.name, 'dimensions': list(size), 'metadata': metadata,
                        'pixel_distribution_percent': {k: round(counts[k] / total * 100, 1) for k in ['fond_sombre_et_petrole', 'cyan_et_bleu_lumineux', 'blanc_et_gris_clair', 'tons_intermediaires']},
                        'dominant_quantized_colors': [{'hex': '#%02X%02X%02X' % rgb, 'percent': round(n / total * 100, 1)} for n, rgb in sorted(palette, reverse=True)]})
output = {'method': 'RGB thumbnail maximum 270x480; HSV exclusive buckets. Dark V<0.45; light neutral S<=0.18,V>=0.70; bright cyan/blue H 0.43..0.60,S>0.35; remainder intermediate. These are approximate raster surface proportions, not original design tokens or layer measurements.', 'images': results}
(root / 'Design - Ref' / 'analyse-couleurs.json').write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(output, ensure_ascii=False, indent=2))
