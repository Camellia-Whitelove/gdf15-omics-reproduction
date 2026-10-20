# -*- coding: utf-8 -*-
# Final style details: panel i point colors, group colors from panels a/g bars, legend swatches.
import sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber
import pypdfium2 as pdfium

PDF = r'C:\GDF15_核心图交接包_20261011\04_论文与要求\s41586-023-06249-4.pdf'
SCALE = 300 / 72
plumb = pdfplumber.open(PDF)
page = plumb.pages[5]
pdf = pdfium.PdfDocument(PDF)
img = pdf[5].render(scale=SCALE).to_pil()

def rgb(c):
    if c is None: return None
    if isinstance(c, (int, float)): c = (c,)
    v = c[:3]
    return '#%02X%02X%02X' % tuple(int(x*255+0.5) for x in v)

print('=== panel a bars (noradrenaline): rects x 50-135, y 55-165 ===')
for r in page.rects:
    if 50 < r['x0'] < 135 and 55 < r['top'] < 170 and (r['x1']-r['x0']) > 2:
        print('RECT x=%.1f-%.1f y=%.1f-%.1f fill=%s' %
              (r['x0'], r['x1'], r['top'], r['bottom'], rgb(r.get('non_stroking_color'))))

print('\n=== panel g bars (Ca-ADP): rects x 95-175, y 375-465 ===')
for r in page.rects:
    if 95 < r['x0'] < 175 and 375 < r['top'] < 465 and (r['x1']-r['x0']) > 2:
        print('RECT x=%.1f-%.1f y=%.1f-%.1f fill=%s' %
              (r['x0'], r['x1'], r['top'], r['bottom'], rgb(r.get('non_stroking_color'))))

print('\n=== heatmap legend region rects: x 390-480, y 200-260 ===')
for r in page.rects:
    if 390 < r['x0'] < 480 and 200 < r['top'] < 260 and (r['x1']-r['x0']) < 30:
        print('RECT x=%.1f-%.1f y=%.1f-%.1f fill=%s' %
              (r['x0'], r['x1'], r['top'], r['bottom'], rgb(r.get('non_stroking_color'))))

print('\n=== panel i: red pixel locations (x 525-565, y 350-465) ===')
reds = []
for xi in range(int(525*SCALE), int(565*SCALE)):
    for yi in range(int(350*SCALE), int(465*SCALE)):
        r_, g_, b_ = img.getpixel((xi, yi))[:3]
        if r_ > 200 and g_ < 90 and b_ < 90:
            reds.append((xi/SCALE, yi/SCALE))
if reds:
    xs = [p[0] for p in reds]; ys = [p[1] for p in reds]
    print('red pixels:', len(reds), 'x range %.1f-%.1f y range %.1f-%.1f' %
          (min(xs), max(xs), min(ys), max(ys)))
    yc = collections.Counter(round(y, 0) for y in ys)
    print('red y-clusters:', sorted(yc.items())[:30])
else:
    print('no red pixels in panel i')

print('\n=== panel i: char colors (axis/P labels) ===')
cc = collections.Counter()
for ch in page.chars:
    if 515 < ch['x0'] < 580 and 330 < ch['top'] < 500:
        cc[(ch['text'], rgb(ch.get('non_stroking_color')))] += 1
for k, n in cc.most_common(30):
    print(k, n)

print('\n=== panel b: char colors in label strips ===')
cc2 = collections.Counter()
for ch in page.chars:
    if 40 < ch['x0'] < 130 and 40 < ch['top'] < 215:
        cc2[rgb(ch.get('non_stroking_color'))] += 1
print('left strip char colors:', cc2.most_common(8))
cc3 = collections.Counter()
for ch in page.chars:
    if 60 < ch['x0'] < 350 and 180 < ch['top'] < 215:
        cc3[rgb(ch.get('non_stroking_color'))] += 1
print('bottom strip char colors:', cc3.most_common(8))

# heatmap cell grid: rect size
cells = [r for r in page.rects if 60 < r['x0'] < 345 and 42 < r['top'] < 215 and r.get('fill')]
ws = collections.Counter(round(r['x1']-r['x0'], 1) for r in cells)
hs = collections.Counter(round(r['bottom']-r['top'], 1) for r in cells)
print('\nheatmap cell widths:', ws.most_common(5))
print('heatmap cell heights:', hs.most_common(5))
xs0 = sorted(set(round(r['x0']) for r in cells))
ys0 = sorted(set(round(r['top']) for r in cells))
print('heatmap x grid n=', len(xs0), 'first/last:', xs0[:3], xs0[-3:])
print('heatmap y grid n=', len(ys0), 'first/last:', ys0[:3], ys0[-3:])
