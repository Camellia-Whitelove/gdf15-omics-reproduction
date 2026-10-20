.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
suppressPackageStartupMessages(library(Rsubread))
meta<-read.delim('work/gdf15/data/ena_runs.tsv',stringsAsFactors=FALSE);meta<-meta[order(meta$sample_alias),]
stopifnot(file.exists('outputs/qc/raw_qc_passed.txt'))
index<-'work/gdf15/data/reference/index/mm10'
while(!file.exists(paste0(index,'.ready')))Sys.sleep(5)
while(!all(file.exists(paste0('work/gdf15/data/clean/',meta$run_accession,'.qc_passed'))))Sys.sleep(5)
gtf<-'work/gdf15/data/reference/gencode.vM25.exons.gtf'
dir.create('work/gdf15/data/bam_unique',recursive=TRUE,showWarnings=FALSE)
dir.create('outputs/alignment',recursive=TRUE,showWarnings=FALSE)
count_one<-function(bam,strand) featureCounts(files=bam,annot.ext=gtf,isGTFAnnotationFile=TRUE,GTF.featureType='exon',GTF.attrType='gene_id',useMetaFeatures=TRUE,isPairedEnd=TRUE,countReadPairs=TRUE,requireBothEndsMapped=TRUE,countChimericFragments=FALSE,countMultiMappingReads=FALSE,allowMultiOverlap=FALSE,strandSpecific=strand,nthreads=12)
for(i in seq_len(nrow(meta))){
 run<-meta$run_accession[i];bam<-paste0('work/gdf15/data/bam_unique/',run,'.bam');result<-paste0('work/gdf15/data/bam_unique/',run,'_counts.rds')
 if(file.exists(result))next
 fastq<-paste0('work/gdf15/data/clean/',run,'_',1:2,'.fastq.gz')
 if(!all(file.exists(fastq)))stop('Clean FASTQ not ready: ',run)
 if(!file.exists(paste0(bam,'.ready'))){
  cat(format(Sys.time()),'ALIGN START',run,'\n');flush.console()
  mapping<-align(index=index,readfile1=fastq[1],readfile2=fastq[2],type='rna',unique=TRUE,nBestLocations=1,input_format='gzFASTQ',output_file=paste0(bam,'.part'),output_format='BAM',nthreads=12,useAnnotation=TRUE,annot.ext=gtf,isGTF=TRUE,GTF.featureType='exon',GTF.attrType='gene_id',sortReadsByCoordinates=FALSE,readGroupID=meta$sample_alias[i])
  if(!file.exists(paste0(bam,'.part')) || file.info(paste0(bam,'.part'))$size<1000)stop('BAM missing or empty')
  stopifnot(file.rename(paste0(bam,'.part'),bam))
  saveRDS(mapping,paste0(bam,'_mapping.rds'))
  header<-Rsamtools::scanBamHeader(bam); record_count<-Rsamtools::countBam(bam)$records
  if(record_count!=2*mapping[1,1])stop('BAM record count differs from expected paired records')
  if(mapping[4,1]!=0)stop('unique=TRUE still reports multimapping fragments')
  writeLines('complete',paste0(bam,'.ready'))
 }
 if(!file.exists('outputs/alignment/selected_strand.txt')){
  tests<-lapply(0:2,function(s)count_one(bam,s));assigned<-vapply(tests,function(z)sum(z$counts),numeric(1))
  write.csv(data.frame(strand=0:2,assigned_fragments=assigned),'outputs/alignment/strand_validation.csv',row.names=FALSE)
  if(assigned[3]>5*max(assigned[2],1)){strand<-2L}else if(assigned[2]>5*max(assigned[3],1)){strand<-1L}else stop('Strandedness ambiguous; inspect assignment and metadata before counting')
  writeLines(as.character(strand),'outputs/alignment/selected_strand.txt')
  counts<-tests[[strand+1]]
 }else{strand<-as.integer(readLines('outputs/alignment/selected_strand.txt'));counts<-count_one(bam,strand)}
 if(sum(counts$counts)>readRDS(paste0(bam,'_mapping.rds'))[3,1])stop('Assigned fragments exceed uniquely mapped fragments')
 saveRDS(counts,result)
 write.csv(counts$stat,paste0('outputs/alignment/',run,'_assignment.csv'),row.names=FALSE)
 cat(format(Sys.time()),'COUNT PASS',run,'assigned',sum(counts$counts),'strand',strand,'\n');flush.console()
}
fc<-lapply(meta$run_accession,function(run)readRDS(paste0('work/gdf15/data/bam_unique/',run,'_counts.rds')))
stopifnot(all(vapply(fc,function(z)identical(rownames(z$counts),rownames(fc[[1]]$counts)),logical(1))))
matrix<-do.call(cbind,lapply(fc,function(z)z$counts[,1]));colnames(matrix)<-meta$sample_alias
write.csv(data.frame(gene_id=rownames(matrix),matrix,check.names=FALSE),'outputs/gene_fragment_counts.csv',row.names=FALSE)
saveRDS(matrix,'outputs/gene_fragment_counts.rds')
write.csv(meta,'outputs/sample_metadata.csv',row.names=FALSE)
writeLines(capture.output(sessionInfo()),'outputs/alignment/sessionInfo.txt')
writeLines('complete','outputs/alignment/counting_complete.txt')
cat('ALL ALIGNMENT AND COUNTING COMPLETE\n')
