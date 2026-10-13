from pathlib import Path
from collections import Counter
import colorsys
import json
from PIL import Image

folder = Path(__file__).resolve().parent / 'Design - Ref - Futures'
results = []
for path in sorted(folder.glob('*.png')):
    with Image.open(path) as source:
        im = source.convert('RGB')
        im.thumbnail((360, 640))
        groups = Counter()
        yellow = Counter()
        green = Counter()
        for rgb in im.getdata():
            h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
            if v < 0.45:
                group = 'dark'
            elif s <= 0.18 and v >= 0.70:
                group = 'white_and_light_grey'
            elif 0.09 <= h <= 0.18 and s > 0.40 and v >= 0.65:
                group = 'yellow_gold'
                yellow[rgb] += 1
            elif 0.28 <= h <= 0.46 and s > 0.40 and v >= 0.65:
                group = 'green_mint'
                green[rgb] += 1
            else:
                group = 'intermediate_and_other'
            groups[group] += 1
        total = sum(groups.values())
        palette = im.quantize(colors=12).convert('RGB').getcolors(im.width * im.height)
        def median_color(counter):
            if not counter:
                return None
            channels = []
            for channel in range(3):
                values = sorted(c[channel] for c, count in counter.items() for _ in range(count))
                channels.append(values[len(values) // 2])
            return '#%02X%02X%02X' % tuple(channels)
        results.append({
            'file': path.name,
            'dimensions': list(source.size),
            'metadata': {k: str(v)[:500] for k, v in source.info.items() if k.lower() in {'software', 'description', 'comment', 'author'}},
            'surface_percent': {key: round(groups[key] / total * 100, 2) for key in ['dark', 'yellow_gold', 'white_and_light_grey', 'green_mint', 'intermediate_and_other']},
            'median_bright_yellow': median_color(yellow),
            'median_bright_green': median_color(green),
            'quantized_palette': [{'hex': '#%02X%02X%02X' % rgb, 'percent': round(count / total * 100, 2)} for count, rgb in sorted(palette, reverse=True)]
        })
data = {
    'analysed_on': '2026-10-06',
    'method': 'RGB thumbnails up to 360x640; mutually exclusive HSV buckets. Dark V<0.45; light neutrals S<=0.18,V>=0.70; yellow H 0.09..0.18,S>0.40,V>=0.65; green H 0.28..0.46,S>0.40,V>=0.65; remainder other. Pixel proportions and channel medians describe flattened exports, not official brand tokens or source layer proportions.',
    'images': results
}
(folder / 'futures-colour-analysis.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
print(json.dumps({'images': [{k: v for k, v in item.items() if k != 'quantized_palette'} for item in results]}, indent=2))
