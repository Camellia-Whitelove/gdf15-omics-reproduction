import pathlib, csv, subprocess, concurrent.futures as cf, json, os, shutil
root=pathlib.Path(__file__).resolve().parents[2]
clean=root/'data'/'clean';clean.mkdir(parents=True,exist_ok=True)
logs=(pathlib.Path(__file__).resolve().parents[2]/'outputs/qc/trimming');logs.mkdir(parents=True,exist_ok=True)
with (root/'data'/'ena_runs.tsv').open(encoding='utf-8-sig') as inp:meta=sorted(csv.DictReader(inp,delimiter='\t'),key=lambda x:x['sample_alias'])
cutadapt=os.environ.get('GDF15_CUTADAPT') or shutil.which('cutadapt') or str(root/'tools'/'cutadapt.exe')
if not pathlib.Path(cutadapt).is_file():
    raise SystemExit('Cutadapt is missing. Set GDF15_CUTADAPT to its executable path.')
def trim(m):
    run=m['run_accession']; report=logs/(run+'.json')
    outputs=[clean/(run+f'_{e}.fastq.gz') for e in (1,2)]
    if report.exists() and all(p.exists() for p in outputs):return run
    args=[cutadapt,'-j','4','-q','20','-a','AGATCGGAAGAGCACACGTCTGAACTCCAGTCA','-A','AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT','-O','3','-e','0.1','-m','20','--pair-filter=any','--json',str(report),'-o',str(outputs[0])+'.part.gz','-p',str(outputs[1])+'.part.gz',str(root/'data'/'raw'/(run+'_1.fastq.gz')),str(root/'data'/'raw'/(run+'_2.fastq.gz'))]
    print('TRIM START',run,flush=True)
    (logs/(run+'_command.txt')).write_text(subprocess.list2cmdline(args),encoding='utf-8')
    environment=dict(os.environ,PYTHONIOENCODING='utf-8',PYTHONUTF8='1')
    with (logs/(run+'.log')).open('w',encoding='utf-8') as log:result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,env=environment)
    if result.returncode:raise RuntimeError('Cutadapt failed: '+run+'; see log')
    info=json.loads(report.read_text())
    if info['read_counts']['input']!=int(m['read_count']):raise RuntimeError('Input count differs from ENA: '+run)
    for p in outputs:pathlib.Path(str(p)+'.part.gz').replace(p)
    print('TRIM PASS',run,info['read_counts'],flush=True)
    return run
with cf.ThreadPoolExecutor(max_workers=3) as pool:
    for f in cf.as_completed([pool.submit(trim,m) for m in meta]):f.result()
print('ALL TRIMMING COMPLETE',flush=True)

