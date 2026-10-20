.libPaths(c(normalizePath('work/gdf15/R-library'), .libPaths()))
suppressPackageStartupMessages(library(ShortRead))
dir.create('outputs/qc', recursive=TRUE, showWarnings=FALSE)
meta <- read.delim('work/gdf15/data/ena_runs.tsv', stringsAsFactors=FALSE)
meta <- meta[order(meta$sample_alias), ]
args <- commandArgs(trailingOnly=TRUE)
worker <- if(length(args)) as.integer(args[1]) else 1L
workers <- if(length(args)>1) as.integer(args[2]) else 1L
meta <- meta[(seq_len(nrow(meta))-1) %% workers == worker-1, ,drop=FALSE]
suffix <- if(workers>1) paste0('_worker',worker) else ''
set.seed(955831)
results <- list(); cycles <- list()
if(workers>1 && worker==1 && file.exists('outputs/qc/raw_qc_summary.csv')) {
  previous<-read.csv('outputs/qc/raw_qc_summary.csv')
  previous_cycles<-read.csv('outputs/qc/raw_quality_by_cycle.csv')
  for(key in unique(paste0(previous$run,'_',previous$end))) {
    results[[key]]<-previous[paste0(previous$run,'_',previous$end)==key,]
    cycles[[key]]<-previous_cycles[paste0(previous_cycles$run,'_',previous_cycles$end)==key,]
  }
}
for (i in seq_len(nrow(meta))) {
  run <- meta$run_accession[i]
  if(paste0(run,'_1') %in% names(results) && paste0(run,'_2') %in% names(results)) next
  cat(format(Sys.time()), 'START', run, meta$sample_alias[i], '\n'); flush.console()
  streams <- lapply(1:2, function(e) FastqStreamer(file.path('work/gdf15/data/raw', paste0(run, '_', e, '.fastq.gz')), n=250000))
  total <- 0; mismatch <- 0; sample_n <- c(0,0)
  qsum <- q20 <- q30 <- bases <- gc <- ns <- adapters <- c(0,0)
  cyc_sum <- cyc_n <- matrix(0, 2, 300)
  minlen <- c(Inf,Inf); maxlen <- c(0,0)
  repeat {
    fq <- lapply(streams, yield)
    lens <- vapply(fq,length,integer(1))
    if (all(lens==0)) break
    if (lens[1]!=lens[2]) stop(run, ' unequal paired chunk lengths')
    ids <- lapply(fq,function(z) sub('/[12]$', '', sub(' .*$', '', as.character(id(z)))))
    mismatch <- mismatch + sum(ids[[1]] != ids[[2]])
    if (mismatch>0) stop(run, ' read IDs do not match')
    total <- total+lens[1]
    take <- which(runif(lens[1]) < 0.005)
    for (e in 1:2) {
      w <- width(sread(fq[[e]])); minlen[e]<-min(minlen[e],w); maxlen[e]<-max(maxlen[e],w)
      if (!length(take)) next
      z <- fq[[e]][take]; q <- as(quality(z),'matrix')
      sample_n[e]<-sample_n[e]+length(z)
      qsum[e]<-qsum[e]+sum(q,na.rm=TRUE); q20[e]<-q20[e]+sum(q>=20,na.rm=TRUE); q30[e]<-q30[e]+sum(q>=30,na.rm=TRUE)
      bases[e]<-bases[e]+sum(width(sread(z)))
      af <- alphabetFrequency(sread(z),baseOnly=TRUE)
      gc[e]<-gc[e]+sum(af[,c('G','C')]); ns[e]<-ns[e]+sum(vcountPattern('N',sread(z),fixed=TRUE))
      adapters[e]<-adapters[e]+sum(vcountPattern('AGATCGGAAGAGC',sread(z),fixed=TRUE)>0)
      ncolq<-ncol(q); if(ncolq>300) stop('Unexpected read length >300')
      cyc_sum[e,seq_len(ncolq)]<-cyc_sum[e,seq_len(ncolq)]+colSums(q,na.rm=TRUE)
      cyc_n[e,seq_len(ncolq)]<-cyc_n[e,seq_len(ncolq)]+colSums(!is.na(q))
    }
    if(total %% 2500000 == 0) {cat(run,total,'pairs inspected\n');flush.console()}
  }
  lapply(streams,close)
  if(total != meta$read_count[i]) stop(run,' ENA pair count mismatch: ',total,' vs ',meta$read_count[i])
  for(e in 1:2) {
    key<-paste0(run,'_',e)
    results[[key]]<-data.frame(sample=meta$sample_alias[i],run=run,end=e,pairs=total,id_mismatch=mismatch,min_length=minlen[e],max_length=maxlen[e],sampled_reads=sample_n[e],mean_phred=qsum[e]/bases[e],Q20_pct=100*q20[e]/bases[e],Q30_pct=100*q30[e]/bases[e],GC_pct=100*gc[e]/bases[e],N_pct=100*ns[e]/bases[e],adapter_13mer_pct=100*adapters[e]/sample_n[e])
    used<-which(cyc_n[e,]>0)
    cycles[[key]]<-data.frame(sample=meta$sample_alias[i],run=run,end=e,cycle=used,mean_phred=cyc_sum[e,used]/cyc_n[e,used])
  }
  write.csv(do.call(rbind,results),paste0('outputs/qc/raw_qc_summary',suffix,'.csv'),row.names=FALSE)
  write.csv(do.call(rbind,cycles),paste0('outputs/qc/raw_quality_by_cycle',suffix,'.csv'),row.names=FALSE)
  cat(format(Sys.time()),'PASS',run,total,'pairs\n');flush.console()
  rm(fq);gc()
}
png(paste0('outputs/qc/raw_quality_by_cycle',suffix,'.png'),width=1600,height=900,res=150)
par(mfrow=c(1,2),mar=c(4,4,3,1))
for(e in 1:2) {
 plot(NA,xlim=c(1,maxlen[e]),ylim=c(0,40),xlab='Read position (bp)',ylab='Mean Phred score',main=paste('Raw reads: end',e))
 for(i in seq_len(nrow(meta))) {z<-cycles[[paste0(meta$run_accession[i],'_',e)]];lines(z$cycle,z$mean_phred,col=i)}
 abline(h=20,lty=2,col='grey50')
}
dev.off()
writeLines(c('All reads parsed and paired IDs checked. Quality metrics use a reproducible Bernoulli sample (p=0.005) across every chunk, not just the first reads.','Adapter metric detects the exact 13-base motif only; it does not measure all partial adapters.','Raw files are unchanged.',capture.output(sessionInfo())), 'outputs/qc/raw_qc_methods.txt')
cat('WORKER COMPLETE:',nrow(meta),'SAMPLES PASS STRUCTURAL QC\n')
