.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
meta<-read.delim('work/gdf15/data/ena_runs.tsv',stringsAsFactors=FALSE)
meta<-meta[order(meta$sample_alias),]
rows<-list()
for(i in seq_len(nrow(meta))){
 run<-meta$run_accession[i];prefix<-paste0('work/gdf15/data/bam_unique/',run)
 if(!file.exists(paste0(prefix,'_counts.rds')))next
 mapping<-readRDS(paste0(prefix,'.bam_mapping.rds'))
 fc<-readRDS(paste0(prefix,'_counts.rds'))
 total<-mapping[1,1];unique<-mapping[3,1];assigned<-sum(fc$counts)
 stopifnot(mapping[4,1]==0,assigned<=unique,file.exists(paste0(prefix,'.bam.ready')))
 rows[[length(rows)+1]]<-data.frame(GSM=meta$sample_alias[i],run=run,input_pairs=total,unique_pairs=unique,multimap_output_pairs=mapping[4,1],unmapped_pairs=mapping[5,1],assigned_pairs=assigned,unique_pct=100*unique/total,assigned_pct=100*assigned/total,bam_bytes=file.info(paste0(prefix,'.bam'))$size)
}
if(length(rows))write.csv(do.call(rbind,rows),'outputs/alignment/alignment_summary.csv',row.names=FALSE)
cat('VALIDATED',length(rows),'/',nrow(meta),'completed samples\n')
if(file.exists('work/gdf15/data/bam/SRR24179000_counts.rds')&&file.exists('work/gdf15/data/bam_unique/SRR24179000_counts.rds')){
 old<-sum(readRDS('work/gdf15/data/bam/SRR24179000_counts.rds')$counts)
 new<-sum(readRDS('work/gdf15/data/bam_unique/SRR24179000_counts.rds')$counts)
 write.csv(data.frame(run='SRR24179000',old_assigned=old,unique_assigned=new,difference=old-new),'outputs/alignment/multimap_strategy_comparison.csv',row.names=FALSE)
}
