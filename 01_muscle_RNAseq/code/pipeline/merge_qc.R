source('01_muscle_RNAseq/code/common.R')
.libPaths(c(normalizePath('01_muscle_RNAseq/R-library', mustWork=FALSE),.libPaths()))
meta<-read.delim('01_muscle_RNAseq/data/ena_runs.tsv')
q<-do.call(rbind,lapply(1:4,function(w) read.csv(paste0('01_muscle_RNAseq/outputs/qc/raw_qc_summary_worker',w,'.csv'))))
cq<-do.call(rbind,lapply(1:4,function(w) read.csv(paste0('01_muscle_RNAseq/outputs/qc/raw_quality_by_cycle_worker',w,'.csv'))))
stopifnot(nrow(q)==32,length(unique(q$run))==16,all(q$id_mismatch==0),!anyDuplicated(paste(q$run,q$end)),all(q$pairs==meta$read_count[match(q$run,meta$run_accession)]))
q<-q[order(q$sample,q$end),]; cq<-cq[order(cq$sample,cq$end,cq$cycle),]
write.csv(q,'01_muscle_RNAseq/outputs/qc/raw_qc_summary.csv',row.names=FALSE)
write.csv(cq,'01_muscle_RNAseq/outputs/qc/raw_quality_by_cycle.csv',row.names=FALSE)
png('01_muscle_RNAseq/outputs/qc/raw_quality_by_cycle.png',width=1600,height=1000,res=150)
par(mfrow=c(1,2),mar=c(4,4,3,1))
groups<-ifelse(as.integer(sub('GSM','',q$sample))<=7177837,'Vehicle',ifelse(as.integer(sub('GSM','',q$sample))<=7177843,'GDF15','Pairfed'))
cols<-c(Vehicle='#4682B4',GDF15='#E69F00',Pairfed='#009E73')
for(e in 1:2){plot(NA,xlim=c(1,51),ylim=c(20,36),xlab='Read position (bp)',ylab='Mean Phred score',main=paste('Raw reads: end',e));for(s in unique(q$sample)){z<-cq[cq$sample==s & cq$end==e,];g<-groups[match(s,q$sample)];lines(z$cycle,z$mean_phred,col=cols[g])};legend('bottomleft',legend=names(cols),col=cols,lty=1,bty='n')}
dev.off()
writeLines(c('All 32 FASTQ files parsed in full; paired IDs match throughout; counts match ENA.','Quality statistics: reproducible 0.5% Bernoulli samples across each full file. These are estimates.','Exact adapter 13-mer frequency underestimates partial adapters. Raw files unchanged.',capture.output(sessionInfo())),'01_muscle_RNAseq/outputs/qc/raw_qc_methods.txt')
writeLines('passed','01_muscle_RNAseq/outputs/qc/raw_qc_passed.txt')
cat('QC PASS: 16 samples,',sum(q$pairs)/2,'paired fragments\n');print(summary(q[,c('Q30_pct','mean_phred','adapter_13mer_pct')]))

