from pathlib import Path
MODULE = Path(__file__).resolve().parents[2]
# -*- coding: utf-8 -*-
# Focused style extraction: panel i bars/points, panel b heatmap palette + legend swatches.
import sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber
import pypdfium2 as pdfium

PDF = str(MODULE/'data/paper.pdf')
SCALE = 300 / 72
plumb = pdfplumber.open(PDF)
page = plumb.pages[5]
pdf = pdfium.PdfDocument(PDF)
img = pdf[5].render(scale=SCALE).to_pil()

def rgb(c):
    if c is None: return None
    if isinstance(c, (int, float)): c = (c,)
    if len(c) == 1:
        v = int(c[0]*255); return '#%02X%02X%02X' % (v, v, v)
    if len(c) == 3: return '#%02X%02X%02X' % tuple(int(v*255) for v in c)
    if len(c) == 4:
        v = c[:3]; return '#%02X%02X%02X' % tuple(int(x*255) for x in v)
    return str(c)

print('=== PANEL i: all vector objects (x>518, 345<top<475) ===')
for r in page.rects:
    if r['x0'] > 518 and 345 < r['top'] < 475 and r['x1'] < 580:
        w, h = r['x1']-r['x0'], r['bottom']-r['top']
        if w >= 1 and h >= 1:
            print('RECT x=%.1f-%.1f y=%.1f-%.1f fill=%s stroke=%s' %
                  (r['x0'], r['x1'], r['top'], r['bottom'],
                   rgb(r.get('non_stroking_color')), rgb(r.get('stroking_color'))))
for l in page.lines:
    if l['x0'] > 518 and 345 < l['top'] < 475 and l['x1'] < 580:
        print('LINE x=%.1f-%.1f y=%.1f-%.1f stroke=%s w=%.2f' %
              (l['x0'], l['x1'], l['top'], l['bottom'],
               rgb(l.get('stroking_color')), l.get('linewidth') or 0))
ncurve = 0
for c in page.curves:
    if c['x0'] > 518 and 345 < c['top'] < 475 and c['x1'] < 580:
        ncurve += 1
        if ncurve <= 20:
            print('CURVE bbox x=%.1f-%.1f y=%.1f-%.1f fill=%s stroke=%s' %
                  (c['x0'], c['x1'], c['top'], c['bottom'],
                   rgb(c.get('non_stroking_color')), rgb(c.get('stroking_color'))))
print('curves total in panel i:', ncurve)

def sample(name, x0, y0, x1, y1, step=2):
    cnt = collections.Counter()
    for xi in range(int(x0*SCALE), int(x1*SCALE), step):
        for yi in range(int(y0*SCALE), int(y1*SCALE), step):
            cnt[img.getpixel((xi, yi))[:3]] += 1
    print('---', name, '---')
    for c, n in cnt.most_common(12):
        print('#%02X%02X%02X' % c, n)

sample('panel i bars region (x 530-560, y 355-460)', 530, 355, 560, 460)

print('\n=== PANEL b heatmap: unique rect fill colors (x 60-345, y 42-215) ===')
pal = collections.Counter()
for r in page.rects:
    if 60 < r['x0'] < 345 and 42 < r['top'] < 215 and r.get('fill'):
        pal[rgb(r.get('non_stroking_color'))] += 1
for c, n in sorted(pal.items(), key=lambda kv: -kv[1]):
    print(c, n)

sample('panel b legend swatches (x 400-470, y 208-250)', 400, 208, 470, 250, 3)

# colorbar: find vertical strip of many distinct colors right of heatmap
print('\n=== colorbar scan: unique colors per thin vertical strip x=346-380 ===')
for xc in range(346, 381, 4):
    cnt = collections.Counter()
    for yi in range(int(45*SCALE), int(215*SCALE), 2):
        cnt[img.getpixel((int(xc*SCALE), yi))[:3]] += 1
    tops = [('#%02X%02X%02X' % c, n) for c, n in cnt.most_common(3)]
    print('x=%d' % xc, tops)

# sample label text color (rotated sample labels left of heatmap)
sample('panel b left label strip (x 55-125, y 45-215)', 55, 45, 125, 215, 3)
sample('panel b bottom label strip (x 60-345, y 185-215)', 60, 185, 345, 215, 3)

