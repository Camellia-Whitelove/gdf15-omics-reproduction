import pathlib, re, csv, hashlib
root=pathlib.Path(__file__).resolve().parent/'data'/'reference'
gtf=root/'gencode.vM25.annotation.gtf'
genes=[]; exon_n=0; chroms=set(); annotated=set()
with (root/'mm10.fa').open() as inp:
    for line in inp:
        if line.startswith('>'):chroms.add(line[1:].split()[0])
with gtf.open() as inp,(root/'gencode.vM25.exons.gtf').open('w') as out:
    for line in inp:
        if line.startswith('#'):out.write(line);continue
        f=line.rstrip().split('\t')
        if f[0] not in chroms:raise RuntimeError('Annotation chromosome absent from FASTA: '+f[0])
        annotated.add(f[0])
        if f[2]=='exon':out.write(line);exon_n+=1
        if f[2]=='gene':
            d=dict(re.findall(r'(\w+) "([^"]*)"',f[8]))
            genes.append(dict(gene_id=d['gene_id'],ensembl_gene=d['gene_id'].split('.')[0],symbol=d.get('gene_name',''),gene_type=d.get('gene_type',''),chromosome=f[0],start=f[3],end=f[4],strand=f[6]))
with (root/'gene_annotation.csv').open('w',newline='',encoding='utf-8') as out:
    w=csv.DictWriter(out,fieldnames=list(genes[0]));w.writeheader();w.writerows(genes)
for fname,expected in [('mm10.fa.gz','db005b65828db31735f384e4c5787be5'),('gencode.vM25.annotation.gtf.gz','0c38fc4ccbc731a2708fc91e7f1c2efd')]:
    with (root/fname).open('rb') as inp:actual=hashlib.file_digest(inp,'md5').hexdigest()
    if actual!=expected:raise RuntimeError('Reference MD5 mismatch: '+fname)
    print('OFFICIAL MD5 PASS',fname,actual,flush=True)
print('Annotation READY',len(genes),'genes,',exon_n,'exons,',len(annotated),'annotated chromosomes,',len(chroms),'FASTA sequences',flush=True)
