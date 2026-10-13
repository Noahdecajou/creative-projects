PFT — RAZVAN CAROUSEL — VERSION 07 (V05 DESIGN RESTORED)

REVISION
V05 typography, layout, daylight direction, copy, charts and candlestick restored as the production baseline. The cover receives a corrective texture pass. Portraits 2, 3 and 6 are freshly rebuilt with actual episode photographs as the only image inputs, avoiding propagation of V05's etched face texture. Built-in ImageGen was used. Fine photographic grain and normal camera softness are requested only in photo plates, before typography and chart overlays. Exact rooms and photographic poses vary slightly from V05. Slide 3 uses a uniform layout crop to keep the portrait high and right.
These remain generatively edited photographic composites, not untouched camera photographs. The grain treatment improves visual integration; it does not certify photographic authenticity.
Grey-green boxes removed. Body copy sits directly over the photographs with local feathered neutral shading. Charts use neutral matte black, slimmer contours and smaller corner radii. The footer has no flat bar: a soft neutral fade supports the logo and transparent swipe outline.
Slide 1: corrected hand/wrist grip with luminous glass edge glints, localized green bloom and fingertip reflections on the OHLC sculpture.
Slide 2: three-quarter portrait, looking down toward a notebook.
Slide 3: rebuilt seated portrait from a real Razvan identity reference; anatomically continuous shoulders, torso, arms and lap, with no shelf severing the chest.
Slide 4: softly lifted dark background with subtle #37FE03 gradient; no photographic background.
Slide 5: overhead walnut desk photograph, notebook, keyboard and mouse hand.
Slide 6: tighter portrait with face raised, leaving the checklist clear.
Green is reserved for selected headlines, chart references, candle glow and small branding accents. Chart panels are neutral matte black. The closing CTA uses a white fill with a thin green outline.
Copy, chart geometry and the real episode screenshot are retained from V01; line breaks were adjusted for readability.
V01 through V06 remain available separately. V06 is the original-capture alternative; V07 follows the user's request to return to V05 design.

DELIVERY
slides/01.png to slides/06.png — six RGB PNGs, 1080 x 1350 px, in order.
apercu_global.png — six-slide overview.
source/01_editable.svg to source/06_editable.svg — editable text and chart geometry, embedded images and fonts.
source/render.py — editable production source, Pillow + NumPy, 2x rendering and downsampling.
source/preview.html — local slide index and editable SVG links.
source/imagegen_prompts_v07.json — V07 photographic texture prompts and recorded trials.
source/comparison_skin_native.png — V05/V07 portrait details at native pixels, no enlargement.
source/compare_skin.py — QA crop contact sheet creation.
source/imagegen_prompts_v05.json — inherited V05 photographic correction prompts.
source/imagegen_prompts_v04.json — inherited V04 daylight photo edit prompts.
source/imagegen_prompts_v03.json — inherited V03 photo generation/edit prompts.
source/imagegen_repair_v03.json — slide 3 background repair prompt.
source/imagegen_prompts.json — inherited V02 prompt history.
source/layout_verification.json and source/delivery_verification.json — dimensions, bounds, checksums and package validation.
source/qa_mobile_360.png — 360 px wide mobile preview for each slide.

PHOTOGRAPHIC ASSETS
Built-in ImageGen edited the V05 cover and created three fresh portraits using actual Razvan episode photographs as references. Slide 5 retains the V05 overhead desk illustration. These are styled composites and photographic illustrations, not newly captured episode stills. Selected and discarded generation prompts are documented in source/imagegen_prompts_v07.json.
The identity source photos are retained in assets/portrait_front_source.jpg and assets/portrait_gesture_source.jpg.
The real slide 4 episode chart and source still are retained in assets/episode_chart_crop.png and assets/episode_chart_source.jpg.
PFT logo extracted from the real episode still; brand name separately typeset.

TYPOGRAPHY
Poppins Regular/Medium/SemiBold; PPEiko Thin for serif contrast. Fonts used for local rendering are in source/fonts/.
PFT bright green #37FE03 is retained from the supplied design reference sampling.

SOURCE CHECKS INHERITED FROM V01
Episode transcript in source/transcript_source.txt.
$158,000 and two weeks: host's episode opening, 00:00-01:01. No independent payout document supplied.
Levels and overlap: 02:24-06:39.
Five-minute inversion and one-minute execution: 08:47-10:20.
Inversion/close-back-through-level confirmation sequence: 13:09-15:14.
Short trade target, one-minute trailing and weekly P&L statement: 16:18-18:15.
Slides 2, 3 and 5 are labelled illustrative. Slide 4 uses the real Nasdaq five-minute episode screenshot.

REVISIONS
Edit text, colors and coordinates in source/render.py. Photographic backgrounds remain separate in assets/.
For a later revision, copy this folder before editing and update the two scripts' ZIP filenames.
