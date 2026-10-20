from pathlib import Path
MODULE = Path(__file__).resolve().parents[2]
# -*- coding: utf-8 -*-
# Extract vector graphic colors (panel i bars) and heatmap palette (panel b) from Fig. 4 page.
import sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber
import pypdfium2 as pdfium
from PIL import Image

PDF = str(MODULE/'data/paper.pdf')
SCALE = 300 / 72

plumb = pdfplumber.open(PDF)
page = plumb.pages[5]

print('--- images on page (bbox in pt) ---')
for im in page.images:
    print('image bbox x0=%.1f top=%.1f x1=%.1f bottom=%.1f' %
          (im['x0'], im['top'], im['x1'], im['bottom']))

print('\n--- filled rects with colors, panel-i region (x>420, top>330, bottom<680) ---')
seen = collections.Counter()
for r in page.rects:
    if r['x0'] > 415 and r['top'] > 330 and r['bottom'] < 690 and r.get('fill'):
        key = (round(r['x0']), round(r['top']), round(r['x1']), round(r['bottom']),
               str(r.get('non_stroking_color')))
        if seen[key] == 0:
            print(key)
        seen[key] += 1

print('\n--- filled rects, panel-b heatmap region (x 100-360, top 40-230) ---')
cntb = collections.Counter()
for r in page.rects:
    if 100 < r['x0'] < 360 and 40 < r['top'] < 230 and r.get('fill'):
        cntb[str(r.get('non_stroking_color'))] += 1
for c, n in cntb.most_common(15):
    print(c, n)

pdf = pdfium.PdfDocument(PDF)
img = pdf[5].render(scale=SCALE).to_pil()

def sample(name, x0, y0, x1, y1, step=3):
    cnt = collections.Counter()
    for xi in range(int(x0 * SCALE), int(x1 * SCALE), step):
        for yi in range(int(y0 * SCALE), int(y1 * SCALE), step):
            p = img.getpixel((xi, yi))[:3]
            cnt[p] += 1
    print(f'--- {name} dominant colors ---')
    for c, n in cnt.most_common(10):
        print('#%02X%02X%02X' % c, n)

# panel i plot region: bars. Scan strip at several y to find bar fill colors.
sample('panel i area (x 425-565, y 340-520)', 425, 340, 565, 520)
# heatmap body: find where. labels at x~60-120; heatmap likely x 120-350, y 45-215
sample('panel b heatmap body (x 125-345, y 45-215)', 125, 45, 345, 215)
# heatmap colorbar region guess (right of heatmap, "Sample distance" label)
sample('panel b right legend (x 340-420, y 45-215)', 340, 45, 420, 215)

