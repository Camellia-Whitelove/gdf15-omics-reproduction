# -*- coding: utf-8 -*-
# Render paper page 6 (Fig. 4) and programmatically extract style of panels b and i.
import sys, io, json, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber
import pypdfium2 as pdfium
from PIL import Image

PDF = r'C:\GDF15_核心图交接包_20261011\04_论文与要求\s41586-023-06249-4.pdf'
SCALE = 300 / 72  # render at 300 dpi

plumb = pdfplumber.open(PDF)
page = plumb.pages[5]
W, H = page.width, page.height
print('page size (pt):', W, H)

# locate panel letters and key labels via words
words = page.extract_words()
def find(txt):
    return [(w['x0'], w['top'], w['x1'], w['bottom']) for w in words if w['text'] == txt]

for t in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
          'Sample', 'distance', 'Vehicle', 'GDF15', 'Pair-fed',
          'Soleus', 'muscle', 'P', '0.0081']:
    print(t, find(t)[:6])

pdf = pdfium.PdfDocument(PDF)
img = pdf[5].render(scale=SCALE).to_pil()
img.save(r'C:\GDF15_核心图交接包_20261011\01_继续分析项目\outputs\audit_20261011\paper_page6_300dpi.png')
print('rendered:', img.size)

def px(x_pt, y_pt):
    return img.getpixel((int(x_pt * SCALE), int(y_pt * SCALE)))

def region_colors(x0, y0, x1, y1, topn=12):
    cnt = collections.Counter()
    for xi in range(int(x0 * SCALE), int(x1 * SCALE), 2):
        for yi in range(int(y0 * SCALE), int(y1 * SCALE), 2):
            r, g, b = img.getpixel((xi, yi))[:3]
            cnt[(r // 8 * 8, g // 8 * 8, b // 8 * 8)] += 1
    return cnt.most_common(topn)
