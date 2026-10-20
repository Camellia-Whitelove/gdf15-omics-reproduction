# -*- coding: utf-8 -*-
# Ground-truth pixel scan of panel i (narrow bar chart) on rendered page 6.
import sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pypdfium2 as pdfium

PDF = r'C:\GDF15_核心图交接包_20261011\04_论文与要求\s41586-023-06249-4.pdf'
SCALE = 300 / 72
pdf = pdfium.PdfDocument(PDF)
img = pdf[5].render(scale=SCALE).to_pil()
W, H = img.size

def classify(p):
    r, g, b = p[:3]
    if r > 235 and g > 235 and b > 235: return 'white'
    if r < 60 and g < 60 and b < 60: return 'black'
    if b > 140 and r < 100 and g < 100: return 'blue'
    if r > 180 and g < 100 and b < 100: return 'red'
    if r > 180 and g > 180 and b < 190: return 'yellow'
    return 'other'

# scan wide region bottom half of page, right side: x 500-590, y 330-560
print('column profile (x_pt: topmost colored pixel y_pt and class):')
for xpt in range(500, 592, 2):
    x = int(xpt * SCALE)
    tops = []
    for ypt10 in range(3300, 5600, 2):
        y = ypt10 // 10
        c = classify(img.getpixel((x, int(ypt10 / 10 * SCALE))))
        if c != 'white':
            tops.append((ypt10 / 10, c))
    if tops:
        # summarize contiguous bands
        bands = []
        cur = [tops[0]]
        for t in tops[1:]:
            if t[0] - cur[-1][0] < 1.2:
                cur.append(t)
            else:
                bands.append(cur); cur = [t]
        bands.append(cur)
        desc = []
        for b in bands[:6]:
            cnt = collections.Counter(c for _, c in b)
            desc.append('%.0f-%.0f:%s' % (b[0][0], b[-1][0], cnt.most_common(1)[0][0]))
        print('x=%d -> %s' % (xpt, ' | '.join(desc)))

# Also find the exact y-axis tick label texts via crop OCR-free approach: print pixel rows near ticks
# Instead: measure bar tops precisely at bar centers
for name, xpt in [('bar1(left)', 536), ('bar2(right)', 547)]:
    x = int(xpt * SCALE)
    col = []
    for ypt in [330 + i * 0.5 for i in range(360)]:
        col.append((ypt, classify(img.getpixel((x, int(ypt * SCALE))))))
    first_nonwhite = next((y for y, c in col if c != 'white'), None)
    # find band from bottom: lowest non-white before y=470
    bands = []
    cur = None
    for y, c in col:
        if c != 'white':
            if cur is None: cur = [y, y, collections.Counter()]
            cur[1] = y; cur[2][c] += 1
        else:
            if cur is not None and cur[1] - cur[0] > 3:
                bands.append(cur)
            cur = None
    if cur is not None: bands.append(cur)
    print(name, 'bands:', [(round(b[0],1), round(b[1],1), b[2].most_common(2)) for b in bands])
