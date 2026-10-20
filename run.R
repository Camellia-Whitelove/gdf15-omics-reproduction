# Usage: Rscript run.R check|liver|fig4c|fig4i|muscle-analysis|muscle-raw|muscle-resume
argfile <- grep('^--file=', commandArgs(FALSE), value=TRUE)
if (length(argfile)) setwd(dirname(normalizePath(sub('^--file=', '', argfile[1]))))
root <- normalizePath('.', winslash='/')
args <- commandArgs(TRUE)
mode <- if (length(args)) args[1] else 'check'
extra <- Sys.getenv('GDF15_R_LIB')
if (nzchar(extra)) .libPaths(c(extra, .libPaths()))
checked_source <- function(path) {
  cat('\nRUN', path, '\n'); flush.console()
  old <- getwd(); on.exit(setwd(old))
  source(file.path(root,path), chdir=FALSE, encoding='UTF-8')
}
run_r <- function(name, args=character()) {
  exe <- file.path(R.home('bin'), if(.Platform$OS.type=='windows') 'Rscript.exe' else 'Rscript')
  status <- system2(exe, c(shQuote(file.path(root,'01_muscle_RNAseq/code/pipeline',name)),args))
  if(status != 0) stop('Stage failed: ',name)
}
run_py <- function(name, args=character()) {
  exe <- Sys.getenv('GDF15_PYTHON', unset=Sys.which('python'))
  if(!nzchar(exe)) stop('Set GDF15_PYTHON to a Python 3.11+ executable.')
  status <- system2(exe, c(shQuote(file.path(root,'01_muscle_RNAseq/code/pipeline',name)),args))
  if(status != 0) stop('Stage failed: ',name)
}
if(mode=='check') {
  stopifnot(file.exists('01_muscle_RNAseq/data/ena_runs.tsv'),
            file.exists('02_liver_RNAseq/01_data/sample_metadata.csv'))
  m <- read.delim('01_muscle_RNAseq/data/ena_runs.tsv')
  stopifnot(nrow(m)==16, !anyDuplicated(m$run_accession),
            all(m$library_layout=='PAIRED'), all(lengths(strsplit(m$fastq_ftp,';'))==2))
  n <- read.csv('02_liver_RNAseq/01_data/sample_metadata.csv')
  stopifnot(nrow(n)==18,all(table(n$condition)==6))
  for(module in c('01_muscle_RNAseq','02_liver_RNAseq')) {
    manifest <- read.csv(file.path(module,'06_records/input_manifest.csv'))
    # The liver count file is downloaded by the prepare step. Check all present inputs now.
    present <- file.exists(file.path(module,manifest$path))
    files <- file.path(module,manifest$path[present])
    stopifnot(identical(unname(tools::md5sum(files)), manifest$md5[present]))
  }
  cat('PASS: bundled metadata and download manifest; no FASTQ downloaded.\n')
} else if(mode=='liver') {
  for(name in c('00_prepare_inputs.R','01_qc_model.R','02_plot.R','04_validate_models.R',
               '05_final_report_figures.R','06_verify_final_figures.R','03_verify_package.R'))
    checked_source(file.path('02_liver_RNAseq/code',name))
} else if(mode=='fig4c') {
  checked_source('01_muscle_RNAseq/code/audit_restyle/audit_fig4c_mf.R')
} else if(mode=='fig4i') {
  checked_source('01_muscle_RNAseq/code/fig4i.R')
} else if(mode %in% c('muscle-analysis','muscle-raw','muscle-resume')) {
  if(mode=='muscle-raw') {
    run_py('fetch_reference.py'); run_py('prepare_annotation.py'); run_r('build_index.R')
    run_py('download_segmented.py'); run_py('verify_downloads.py')
    for(w in 1:4)run_r('qc_raw.R',c(w,4))
    run_r('merge_qc.R');run_py('trim_samples.py')
    for(w in 1:4)run_r('qc_clean.R',c(w,4))
    run_r('merge_clean_qc.R')
  }
  if(mode %in% c('muscle-raw','muscle-resume')) {
    for(w in 1:2)run_r('align_count_worker.R',c(w,2))
    run_r('collect_counts.R');run_r('summarize_alignment.R')
  }
  for(name in c('export_gene_mapping.R','analyze.R','redraw_figures.R'))run_r(name)
} else stop('Unknown mode. Use check, liver, fig4c, fig4i, muscle-analysis, muscle-raw or muscle-resume.')
