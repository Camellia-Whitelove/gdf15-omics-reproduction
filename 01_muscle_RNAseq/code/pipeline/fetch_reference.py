import concurrent.futures as cf, hashlib, pathlib, subprocess, time, gzip, shutil, json
root=pathlib.Path(__file__).resolve().parents[2]/'data'/'reference'
root.mkdir(parents=True,exist_ok=True)
files=[('https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz',870141360),('https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M25/gencode.vM25.annotation.gtf.gz',28542432)]
expected_md5={'mm10.fa.gz':'db005b65828db31735f384e4c5787be5','gencode.vM25.annotation.gtf.gz':'0c38fc4ccbc731a2708fc91e7f1c2efd'}
def piece(task):
    url,start,end,path=task
    for attempt in range(5):
        p=subprocess.run(['curl.exe','-L','--fail','--silent','--show-error','--connect-timeout','15','--max-time','90','--range',f'{start}-{end}','-o',str(path),url],capture_output=True,text=True)
        if p.returncode==0 and path.exists() and path.stat().st_size==end-start+1:return path
        print('Retry',path.name,attempt+1,p.stderr.strip(),flush=True)
        time.sleep(min(2**attempt,10))
    raise RuntimeError('Persistent reference transfer failure: '+str(path))
records=[]
for url,size in files:
    target=root/url.rsplit('/',1)[-1]
    if not target.exists() or target.stat().st_size!=size:
        chunks=root/(target.name+'.chunks');chunks.mkdir(parents=True,exist_ok=True)
        tasks=[]
        for start in range(0,size,4194304):
            end=min(size-1,start+4194303);path=chunks/f'{start:012d}.part'
            if not path.exists() or path.stat().st_size!=end-start+1:tasks.append((url,start,end,path))
        print('Downloading',target.name,len(tasks),'segments',flush=True)
        with cf.ThreadPoolExecutor(max_workers=8) as pool:
            for n,f in enumerate(cf.as_completed([pool.submit(piece,t) for t in tasks]),1):
                f.result()
                if n%16==0:print(target.name,n,'/',len(tasks),flush=True)
        with target.with_suffix(target.suffix+'.part').open('wb') as out:
            for part in sorted(chunks.glob('*.part')):
                with part.open('rb') as inp:shutil.copyfileobj(inp,out)
        target.with_suffix(target.suffix+'.part').replace(target)
    with target.open('rb') as inp:digest=hashlib.file_digest(inp,'md5').hexdigest()
    if digest!=expected_md5[target.name]:raise RuntimeError('Reference MD5 mismatch: '+target.name)
    destination=target.with_suffix('')
    print('Validating gzip and extracting',target.name,flush=True)
    with gzip.open(target,'rb') as inp, destination.with_suffix(destination.suffix+'.part').open('wb') as out:shutil.copyfileobj(inp,out)
    destination.with_suffix(destination.suffix+'.part').replace(destination)
    with target.open('rb') as inp:digest=hashlib.file_digest(inp,'md5').hexdigest()
    records.append(dict(url=url,bytes=target.stat().st_size,local_md5=digest,extracted_bytes=destination.stat().st_size,gzip_crc_pass=True))
    print('READY',destination.name,records[-1],flush=True)
(root/'reference_manifest.json').write_text(json.dumps(records,indent=2),encoding='utf-8')

