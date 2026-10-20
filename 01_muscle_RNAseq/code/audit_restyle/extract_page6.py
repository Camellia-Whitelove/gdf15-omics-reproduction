from pathlib import Path
MODULE = Path(__file__).resolve().parents[2]
# -*- coding: utf-8 -*-
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pdfplumber

p = str(MODULE/'data/paper.pdf')
with pdfplumber.open(p) as pdf:
    print('pages:', len(pdf.pages))
    t = pdf.pages[5].extract_text() or ''
    print('--- PAGE 6 TEXT ---')
    print(t)

