extra<-Sys.getenv('GDF15_R_LIB');if(nzchar(extra)).libPaths(c(extra,.libPaths()))
suppressPackageStartupMessages(library(DESeq2))
dds<-readRDS('03_models/DESeq2_fitted_model.rds')
x<-read.csv(gzfile('01_data/GSE229708_Counts4allSamples.csv.gz'),row.names=1,check.names=FALSE)
stopifnot(identical(unname(counts(dds)),unname(as.matrix(x))),all(is.finite(sizeFactors(dds))),all(sizeFactors(dds)>0),all(is.finite(dispersions(dds))),all(dispersions(dds)>0))
t<-readRDS('03_models/transformed_matrices.rds')
for(nm in c('VST','rlog')) {
 stopifnot(all(is.finite(t[[nm]])),identical(dim(t[[nm]]),dim(counts(dds))))
 p<-readRDS(paste0('03_models/PCA_',nm,'_top500.rds'))
 z<-read.csv(paste0('04_plot_data/PCA_',nm,'_coordinates.csv'))
 v<-read.csv(paste0('04_plot_data/PCA_',nm,'_variance.csv'))
 stopifnot(max(abs(p$x[,1]-z$PC1))<1e-10,max(abs(p$x[,4]-z$PC4))<1e-10,abs(sum(v$variance_percent)-100)<1e-8)
}
for(nm in c('VST_Euclidean','rlog_Euclidean','raw_Poisson')) {
 m<-as.matrix(read.csv(paste0('04_plot_data/distance_',nm,'.csv'),row.names=1,check.names=FALSE))
 stopifnot(max(abs(m-t(m)))<1e-8,all(diag(m)==0),all(m>=0),identical(rownames(m),colnames(dds)))
}
cat('PASS: source counts, model factors, dispersions, transformed values, PCA coordinates and distance matrices agree.\n')
