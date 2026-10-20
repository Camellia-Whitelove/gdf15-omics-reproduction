.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
suppressPackageStartupMessages(library(ShortRead))
args<-commandArgs(trailingOnly=TRUE);worker<-as.integer(args[1]);workers<-as.integer(args[2])
meta<-read.delim('work/gdf15/data/ena_runs.tsv');meta<-meta[order(meta$sample_alias),];meta<-meta[(seq_len(nrow(meta))-1)%%workers==worker-1,,drop=FALSE]
results<-list();cycles<-list();lengths<-list()
for(i in seq_len(nrow(meta))){
 run<-meta$run_accession[i];paths<-paste0('work/gdf15/data/clean/',run,'_',1:2,'.fastq.gz')
 while(!all(file.exists(paths)))Sys.sleep(5)
 cat(format(Sys.time()),'CLEAN QC START',run,'\n');flush.console()
 ids<-list();total<-c(0,0)
 for(e in 1:2){
  set.seed(955831+as.integer(sub('SRR','',run)))
  sampler<-FastqSampler(paths[e],n=100000,ordered=TRUE)
  z<-yield(sampler);total[e]<-sampler$status()[['total']];close(sampler)
  ids[[e]]<-sub('/[12]$','',sub(' .*$','',as.character(id(z))))
  w<-width(sread(z)); qsum<-q20<-q30<-bases<-0;cs<-cn<-rep(0,300)
  for(len in sort(unique(w))){
   if(len<20 ||len>51)stop('Unexpected clean read length')
   q<-as(quality(z[w==len]),'matrix')
   qsum<-qsum+sum(q);q20<-q20+sum(q>=20);q30<-q30+sum(q>=30);bases<-bases+length(q)
   cs[seq_len(len)]<-cs[seq_len(len)]+colSums(q);cn[seq_len(len)]<-cn[seq_len(len)]+nrow(q)
  }
  af<-alphabetFrequency(sread(z),baseOnly=TRUE)
  key<-paste0(run,'_',e)
  results[[key]]<-data.frame(sample=meta$sample_alias[i],run=run,end=e,clean_pairs=total[e],sampled_reads=length(z),min_length=min(w),max_length=max(w),mean_phred=qsum/bases,Q20_pct=100*q20/bases,Q30_pct=100*q30/bases,GC_pct=100*sum(af[,c('G','C')])/bases,N_pct=100*sum(vcountPattern('N',sread(z),fixed=TRUE))/bases,adapter_13mer_pct=100*mean(vcountPattern('AGATCGGAAGAGC',sread(z),fixed=TRUE)>0))
  used<-which(cn>0);cycles[[key]]<-data.frame(sample=meta$sample_alias[i],run=run,end=e,cycle=used,mean_phred=cs[used]/cn[used])
  tab<-table(w);lengths[[key]]<-data.frame(sample=meta$sample_alias[i],run=run,end=e,length=as.integer(names(tab)),sampled_reads=as.integer(tab))
 }
 expected<-jsonlite::fromJSON(paste0('outputs/qc/trimming/',run,'.json'))$read_counts$output
 if(total[1]!=total[2] || total[1]!=expected)stop('Clean pair count differs from Cutadapt output: ',run)
 if(total[1]>meta$read_count[i] || total[1]<0.95*meta$read_count[i])stop('Unexpected retention: ',run)
 write.csv(do.call(rbind,results),paste0('outputs/qc/clean_qc_summary_worker',worker,'.csv'),row.names=FALSE)
 write.csv(do.call(rbind,cycles),paste0('outputs/qc/clean_quality_by_cycle_worker',worker,'.csv'),row.names=FALSE)
 write.csv(do.call(rbind,lengths),paste0('outputs/qc/clean_length_distribution_worker',worker,'.csv'),row.names=FALSE)
 cat(format(Sys.time()),'CLEAN QC PASS',run,total[1],'pairs\n');flush.console()
 writeLines('passed',paste0('work/gdf15/data/clean/',run,'.qc_passed'))
}
cat('CLEAN QC WORKER COMPLETE\n')
