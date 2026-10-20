import csv, hashlib, json, os, pathlib, subprocess, time
from concurrent.futures import ThreadPoolExecutor, as_completed

base = pathlib.Path(__file__).resolve().parent / 'data'
raw = base / 'raw'
raw.mkdir(exist_ok=True)
tasks=[]
with (base/'ena_runs.tsv').open(encoding='utf-8-sig', newline='') as f:
    for r in sorted(csv.DictReader(f,delimiter='\t'),key=lambda x:x['sample_alias']):
        for u,s,h in zip(r['fastq_ftp'].split(';'),r['fastq_bytes'].split(';'),r['fastq_md5'].split(';')):
            tasks.append((u,int(s),h,r['sample_alias']))

chunk_size=4*1024*1024
def fetch_segment(task):
    url,start,end,target=task
    command=['curl.exe','--noproxy','*','-L','--fail','--connect-timeout','15','--max-time','60','--range',f'{start}-{end}','--silent','--show-error','--output',str(target),'https://'+url]
    p=subprocess.run(command,capture_output=True,text=True,errors='replace')
    expected=end-start+1
    if p.returncode or not target.exists() or target.stat().st_size != expected:
        raise RuntimeError(f'{target.name}: expected {expected} bytes, received {target.stat().st_size if target.exists() else 0}; curl exit {p.returncode}; {p.stderr.strip()}')
    return target

try:
    for number,(url,size,md5,sample) in enumerate(tasks,1):
        name=url.rsplit('/',1)[-1]
        final=raw/name
        if final.exists():
            actual=hashlib.file_digest(final.open('rb'),'md5').hexdigest()
            if actual != md5 or final.stat().st_size != size: raise RuntimeError('Existing file failed validation: '+name)
            print(f'Verified existing {number}/32: {name}',flush=True)
            continue
        pieces=raw/(name+'.chunks')
        pieces.mkdir(exist_ok=True)
        segments=[]
        for start in range(0,size,chunk_size):
            end=min(size-1,start+chunk_size-1)
            target=pieces/f'{start:012d}.chunk'
            if not target.exists() or target.stat().st_size != end-start+1: segments.append((url,start,end,target))
        print(f'Downloading {number}/32 {sample} {name}: {len(segments)} remaining segments',flush=True)
        with ThreadPoolExecutor(max_workers=16) as pool:
            pending={pool.submit(fetch_segment,t):t for t in segments}
            done=0
            try:
                for future in as_completed(pending):
                    future.result()
                    done+=1
                    if done%8==0 or done==len(segments): print(f'{name}: segments {done}/{len(segments)}',flush=True)
            except Exception:
                for future in pending: future.cancel()
                raise
        temporary=raw/(name+'.part')
        digest=hashlib.md5()
        with temporary.open('wb') as out:
            for part in sorted(pieces.glob('*.chunk')):
                with part.open('rb') as f:
                    while block:=f.read(1024*1024):
                        out.write(block); digest.update(block)
        if temporary.stat().st_size != size or digest.hexdigest()!=md5: raise RuntimeError('Assembled file failed size/MD5 check: '+name)
        temporary.replace(final)
        for part in pieces.glob('*.chunk'): part.unlink()
        pieces.rmdir()
        print(f'Verified {number}/32: {name}',flush=True)
    print('Data download stage COMPLETE: 32 files verified.',flush=True)
except Exception as error:
    (base/'download_failure.txt').write_text(str(error),encoding='utf-8')
    print('PAUSED: '+str(error),flush=True)
    raise SystemExit(1)
