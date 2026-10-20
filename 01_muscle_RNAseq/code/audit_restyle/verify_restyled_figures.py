# -*- coding: utf-8 -*-
# Sanity check of restyled figures by pixel analysis.
import sys, io, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from PIL import Image

base = r'C:\GDF15_核心图交接包_20261011\01_继续分析项目\outputs\figures\paper_style'

img = Image.open(base + r'\Fig4i_calcium_respiration_paperstyle.png').convert('RGB')
cnt = collections.Counter(img.getpixel((x, y)) for x in range(0, img.width, 3) for y in range(0, img.height, 3))
print('Fig4i paperstyle size:', img.size)
for c, n in cnt.most_common(10):
    print('#%02X%02X%02X' % c, n)
# locate red and blue bar columns: topmost red / blue pixel
def topmost(color_test):
    for y in range(img.height):
        for x in range(0, img.width, 2):
            if color_test(img.getpixel((x, y))):
                return x, y
    return None
red_top = topmost(lambda p: p[0] > 220 and p[1] < 60 and p[2] < 60)
blue_top = topmost(lambda p: p[2] > 200 and p[0] < 100 and p[1] < 100)
print('first red pixel (x,y):', red_top, ' first blue pixel:', blue_top)

img2 = Image.open(base + r'\Fig4b_sample_distance_paperstyle.png').convert('RGB')
cnt2 = collections.Counter(img2.getpixel((x, y)) for x in range(0, img2.width, 3) for y in range(0, img2.height, 3))
print('\nFig4b paperstyle size:', img2.size)
n_grey = sum(n for c, n in cnt2.items() if abs(c[0]-153) < 20 and abs(c[1]-153) < 20 and abs(c[2]-153) < 20)
n_blue = sum(n for c, n in cnt2.items() if c[2] > 150 and c[0] < 120 and c[1] < 120)
n_red = sum(n for c, n in cnt2.items() if c[0] > 180 and c[1] < 90 and c[2] < 90)
n_yellow = sum(n for c, n in cnt2.items() if c[0] > 200 and c[1] > 180 and c[2] < 140)
print('grey60-border pixels: %d, blue-family: %d, red-family: %d, yellow-family: %d' % (n_grey, n_blue, n_red, n_yellow))
