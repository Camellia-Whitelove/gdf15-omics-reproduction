extra <- Sys.getenv('GDF15_R_LIB'); if(nzchar(extra)) .libPaths(c(extra,.libPaths()))
if (dir.exists('02_liver_RNAseq/code')) setwd('02_liver_RNAseq')
# Run from the handoff root. Optional GDF15_R_LIB points to a local R library.
extra <- Sys.getenv('GDF15_R_LIB')
if(nzchar(extra)) .libPaths(c(extra,.libPaths()))
suppressPackageStartupMessages({library(DESeq2);library(PoiClaClu)})
for(d in c('02_qc','03_models','04_plot_data','06_records'))dir.create(d,recursive=TRUE,showWarnings=FALSE)
write_matrix <- function(m,path) {
 con <- gzfile(path,'wt');on.exit(close(con))
 write.csv(data.frame(gene_id=rownames(m),m,check.names=FALSE),con,row.names=FALSE)
}
write_table <- function(x,path) {
 con<-gzfile(path,'wt');on.exit(close(con));write.csv(x,con,row.names=FALSE)
}
x <- read.csv(gzfile('01_data/GSE229708_Counts4allSamples.csv.gz'),row.names=1,check.names=FALSE)
ct <- as.matrix(x)
stopifnot(nrow(ct)==16245,ncol(ct)==18,!anyDuplicated(rownames(ct)),!anyDuplicated(colnames(ct)),all(is.finite(ct)),all(ct>=0),all(ct==round(ct)))
meta <- read.csv('01_data/sample_metadata.csv',stringsAsFactors=FALSE)
stopifnot(identical(meta$sample,colnames(ct)),all(table(meta$condition)==6),!anyNA(meta))
meta$condition <- factor(meta$condition,levels=c('Vehicle','PairFed','GDF15'));rownames(meta)<-meta$sample
keep <- rowSums(ct)>=5
write.csv(data.frame(gene_id=rownames(ct),total_count=rowSums(ct),retained=keep),'02_qc/gene_filter.csv',row.names=FALSE)
dds <- DESeqDataSetFromMatrix(ct,meta,~condition);dds<-dds[keep,]
dds <- DESeq(dds)
saveRDS(dds,'03_models/DESeq2_fitted_model.rds')
sf <- sizeFactors(dds)
qc <- data.frame(meta,library_count=colSums(ct),detected_genes=colSums(ct>0),zero_fraction=colMeans(ct==0),size_factor=sf)
qc$library_ratio_to_median <- qc$library_count/median(qc$library_count)
qc$library_review_flag <- qc$library_ratio_to_median<.5|qc$library_ratio_to_median>2
write.csv(qc,'02_qc/sample_qc.csv',row.names=FALSE)
write_matrix(counts(dds,normalized=TRUE),'03_models/DESeq2_normalized_counts.csv.gz')
write_table(data.frame(gene_id=rownames(dds),as.data.frame(mcols(dds))),'03_models/gene_model_diagnostics.csv.gz')
ncooks <- assays(dds)[['cooks']]
write.csv(data.frame(sample=colnames(dds),max_cooks=apply(ncooks,2,max,na.rm=TRUE)),'02_qc/Cooks_diagnostic.csv',row.names=FALSE)
cat('Fitted DESeq2; starting VST and rlog.\n');flush.console()
v <- varianceStabilizingTransformation(dds,blind=FALSE);rl <- rlog(dds,blind=FALSE)
saveRDS(list(VST=assay(v),rlog=assay(rl),metadata=meta),'03_models/transformed_matrices.rds')
write_matrix(assay(v),'04_plot_data/VST_matrix.csv.gz');write_matrix(assay(rl),'04_plot_data/rlog_matrix.csv.gz')
pv <- list()
for(nm in c('VST','rlog')) {
 a <- if(nm=='VST')assay(v) else assay(rl)
 selected <- head(order(apply(a,1,var),decreasing=TRUE),500)
 pc <- prcomp(t(a[selected,]));saveRDS(pc,paste0('03_models/PCA_',nm,'_top500.rds'))
 pct <- 100*pc$sdev^2/sum(pc$sdev^2)
 write.csv(data.frame(sample=rownames(pc$x),condition=meta$condition,pc$x),paste0('04_plot_data/PCA_',nm,'_coordinates.csv'),row.names=FALSE)
 write.csv(data.frame(PC=seq_along(pct),variance_percent=pct),paste0('04_plot_data/PCA_',nm,'_variance.csv'),row.names=FALSE)
 write.csv(data.frame(gene_id=rownames(a)[selected]),paste0('04_plot_data/PCA_',nm,'_top500_genes.csv'),row.names=FALSE)
 pv[[nm]] <- data.frame(transform=nm,PC1=pct[1],PC4=pct[4],original_PC1=55.38,original_PC4=5.08)
}
write.csv(do.call(rbind,pv),'06_records/PCA_original_comparison.csv',row.names=FALSE)
distances <- list(VST_Euclidean=dist(t(assay(v))),rlog_Euclidean=dist(t(assay(rl))),raw_Poisson=PoissonDistance(t(counts(dds)))$dd)
original <- c('GDF15.4','GDF15.2','GDF15.1','GDF15.3','GDF15.5','GDF15.6','PairFed.2','PairFed.1','Vehicle.1','Vehicle.2','PairFed.4','PairFed.5','PairFed.3','Vehicle.4','Vehicle.5','Vehicle.6','Vehicle.3','PairFed.6')
summary <- list()
for(nm in names(distances)) {
 d <- distances[[nm]];attr(d,'Labels')<-meta$sample
 h <- hclust(d,method='complete');saveRDS(h,paste0('03_models/cluster_',nm,'.rds'))
 write.csv(as.matrix(d),paste0('04_plot_data/distance_',nm,'.csv'))
 write.csv(data.frame(position=seq_along(h$order),sample=meta$sample[h$order],condition=meta$condition[h$order]),paste0('04_plot_data/order_',nm,'.csv'),row.names=FALSE)
 summary[[nm]] <- data.frame(method=nm,max_distance=max(d),original_leaf_positions_matched=sum(meta$sample[h$order]==original),all_original_leaf_positions_match=identical(meta$sample[h$order],original))
}
write.csv(do.call(rbind,summary),'06_records/distance_original_comparison.csv',row.names=FALSE)
# Exploratory differential results are supplied for reporting, not claimed as Fig1i/j.
for(pair in list(c('GDF15','Vehicle'),c('GDF15','PairFed'),c('PairFed','Vehicle'))) {
 z <- as.data.frame(results(dds,contrast=c('condition',pair),alpha=.05))
 z$gene_id<-rownames(z);z$paper_liver_DEG<-!is.na(z$padj)&z$padj<.05&abs(z$log2FoldChange)>1
 write_table(z,paste0('03_models/DESeq2_',paste(pair,collapse='_vs_'),'.csv.gz'))
}
pkgs <- c('DESeq2','PoiClaClu','ggplot2','pheatmap')
write.csv(data.frame(package=pkgs,version=vapply(pkgs,function(p)as.character(packageVersion(p)),'')),'06_records/package_versions.csv',row.names=FALSE)
writeLines(c('Source-count matrix QC, filtering, DESeq2 fitting, VST/rlog, PCA and three distance methods completed.',paste('Retained genes:',sum(keep)), 'No samples automatically removed. Library flags and Cooks distances are diagnostic only.', 'No liver FASTQ quality control, alignment, Salmon tximport lengths or offsets were performed/supplied.', 'PCA top500; centered, unscaled; PC1/PC4. Clustering: complete linkage.',capture.output(sessionInfo())),'06_records/session_and_methods.txt')
writeLines('success','06_records/modeling_complete.txt')
cat('MODELING COMPLETE\n');print(do.call(rbind,pv));print(do.call(rbind,summary))

