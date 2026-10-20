from pathlib import Path
MODULE = Path(__file__).resolve().parents[2]
# -*- coding: utf-8 -*-
# Final: heatmap colorbar location, legend swatches, top annotation, panel i y-axis label text.
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

def is_rdylbu(p):
    r, g, b = p[:3]
    # saturated colors of the RdYlBu family (blue..red, incl. yellow/orange)
    if r > 235 and g > 235 and b > 235: return False
    sat = max(r, g, b) - min(r, g, b)
    if sat < 40: return False
    # exclude pure blue 0000FF group-legend color and red FA0206
    if b > 200 and r < 100: return False
    if r > 230 and g < 60 and b < 60: return False
    return True

print('=== scan page for RdYlBu-family colored pixel clusters outside heatmap body ===')
# heatmap body approx x 75-290, y 45-215. Scan rest of top-left quadrant.
regions = collections.Counter()
for xi in range(int(30*SCALE), int(480*SCALE), 3):
    for yi in range(int(35*SCALE), int(280*SCALE), 3):
        xpt, ypt = xi/SCALE, yi/SCALE
        if 70 < xpt < 300 and 40 < ypt < 220:  # inside heatmap
            continue
        if is_rdylbu(img.getpixel((xi, yi))):
            regions[(int(xpt//10)*10, int(ypt//10)*10)] += 1
for k, n in sorted(regions.items(), key=lambda kv: -kv[1])[:25]:
    print('block x~%d y~%d : %d px' % (k[0], k[1], n))

print('\n=== precise swatch scan around legend text (x 395-460, y 210-245) ===')
for ypt in range(210, 246, 2):
    row = []
    for xpt in range(395, 462, 1):
        p = img.getpixel((int(xpt*SCALE), int(ypt*SCALE)))[:3]
        if not (p[0] > 235 and p[1] > 235 and p[2] > 235):
            row.append((xpt, '#%02X%02X%02X' % p))
    if row:
        # compress consecutive
        comp = []
        for x, c in row:
            if comp and comp[-1][1] == c and x - comp[-1][0][-1] <= 1:
                comp[-1][0].append(x)
            else:
                comp.append(([x], c))
        print('y=%d:' % ypt, ' '.join('%d-%d:%s' % (c[0][0], c[0][-1], c[1]) for c in comp))

print('\n=== heatmap top annotation strip check (x 75-290, y 38-52) ===')
cnt = collections.Counter()
for xi in range(int(75*SCALE), int(290*SCALE), 2):
    for yi in range(int(38*SCALE), int(52*SCALE), 2):
        cnt[img.getpixel((xi, yi))[:3]] += 1
print(cnt.most_common(8))

print('\n=== panel i y-axis rotated label chars (x 500-527, y 340-520) ===')
chars = [c for c in page.chars if 500 < c['x0'] < 527 and 340 < c['top'] < 520]
chars.sort(key=lambda c: (-c['top'], c['x0']))
print(''.join(c['text'] for c in chars))

print('\n=== panel i x-axis label positions ===')
for c in page.chars:
    if 528 < c['x0'] < 580 and 458 < c['top'] < 475:
        print(repr(c['text']), 'x=%.1f y=%.1f' % (c['x0'], c['top']), 'upright=', c.get('upright'))

print('\n=== tick label chars (x 515-530, y 350-460) ===')
for c in page.chars:
    if 514 < c['x0'] < 530 and 350 < c['top'] < 460:
        print(repr(c['text']), 'x=%.1f y=%.1f' % (c['x0'], c['top']))

