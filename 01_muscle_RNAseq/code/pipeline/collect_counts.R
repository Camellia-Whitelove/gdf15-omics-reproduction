.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
suppressPackageStartupMessages(library(Rsubread))
meta<-read.delim('work/gdf15/data/ena_runs.tsv',stringsAsFactors=FALSE);meta<-meta[order(meta$sample_alias),]
fc<-lapply(meta$run_accession,function(run)readRDS(paste0('work/gdf15/data/bam_unique/',run,'_counts.rds')))
stopifnot(all(vapply(fc,function(z)identical(rownames(z$counts),rownames(fc[[1]]$counts)),logical(1))))
matrix<-do.call(cbind,lapply(fc,function(z)z$counts[,1]));colnames(matrix)<-meta$sample_alias
stopifnot(ncol(matrix)==16,all(is.finite(matrix)),all(matrix>=0),all(matrix==round(matrix)),!anyDuplicated(rownames(matrix)),!anyDuplicated(colnames(matrix)))
trim<-read.csv('outputs/qc/trimming_summary.csv')
for(i in seq_len(nrow(meta))){mapping<-readRDS(paste0('work/gdf15/data/bam_unique/',meta$run_accession[i],'.bam_mapping.rds'));stopifnot(mapping[1,1]==trim$output_pairs[match(meta$run_accession[i],trim$run)],mapping[4,1]==0,sum(matrix[,i])<=mapping[3,1])}
write.csv(data.frame(gene_id=rownames(matrix),matrix,check.names=FALSE),'outputs/gene_fragment_counts.csv',row.names=FALSE)
saveRDS(matrix,'outputs/gene_fragment_counts.rds')
gsm<-as.integer(sub('GSM','',meta$sample_alias));meta$condition<-ifelse(gsm<=7177837,'Vehicle',ifelse(gsm<=7177843,'GDF15','Pairfed'));meta$original_sample_number<-ifelse(gsm<=7177837,gsm-7177832,ifelse(gsm<=7177843,gsm-7177837,gsm-7177842))
write.csv(meta,'outputs/sample_metadata.csv',row.names=FALSE)
writeLines(capture.output(sessionInfo()),'outputs/alignment/sessionInfo.txt')
writeLines('complete','outputs/alignment/counting_complete.txt')
cat('ALL ALIGNMENT AND COUNTING COMPLETE\n')
