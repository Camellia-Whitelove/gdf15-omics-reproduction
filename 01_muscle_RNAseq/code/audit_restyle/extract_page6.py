# -*- coding: utf-8 -*-
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber

p = r'C:\GDF15_核心图交接包_20261011\04_论文与要求\s41586-023-06249-4.pdf'
with pdfplumber.open(p) as pdf:
    print('pages:', len(pdf.pages))
    t = pdf.pages[5].extract_text() or ''
    print('--- PAGE 6 TEXT ---')
    print(t)
