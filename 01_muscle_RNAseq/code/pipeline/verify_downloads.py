import csv, hashlib, pathlib, json
base=pathlib.Path(__file__).resolve().parents[2]
rows=[]
with (base/'data/ena_runs.tsv').open(encoding='utf-8-sig',newline='') as f:
    runs=list(csv.DictReader(f,delimiter='\t'))
for run in runs:
    for url,size,expected in zip(run['fastq_ftp'].split(';'),run['fastq_bytes'].split(';'),run['fastq_md5'].split(';')):
        name=url.rsplit('/',1)[-1]; p=base/'data/raw'/name
        actual_size=p.stat().st_size if p.exists() else 0
        actual_hash=''
        if p.exists() and actual_size==int(size):
            with p.open('rb') as stream: actual_hash=hashlib.file_digest(stream,'md5').hexdigest()
        status='PASS' if actual_size==int(size) and actual_hash==expected else 'FAIL'
        rows.append(dict(sample=run['sample_alias'],run=run['run_accession'],file=name,expected_bytes=size,actual_bytes=actual_size,expected_md5=expected,actual_md5=actual_hash,status=status))
        print(f'{status}: {name}',flush=True)
out=base/'outputs/download_verification.csv'
out.parent.mkdir(parents=True,exist_ok=True)
with out.open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=rows[0].keys());writer.writeheader();writer.writerows(rows)
print(json.dumps({'files':len(rows),'passed':sum(r['status']=='PASS' for r in rows),'bytes':sum(r['actual_bytes'] for r in rows)}),flush=True)
raise SystemExit(0 if all(r['status']=='PASS' for r in rows) else 1)

