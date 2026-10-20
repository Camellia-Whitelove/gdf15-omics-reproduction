source('01_muscle_RNAseq/code/common.R')
.libPaths(c(normalizePath('01_muscle_RNAseq/R-library', mustWork=FALSE),.libPaths()))
suppressPackageStartupMessages(library(org.Mm.eg.db))
ann<-read.csv('01_muscle_RNAseq/data/reference/gene_annotation.csv')
mapping<-AnnotationDbi::select(org.Mm.eg.db,keys=unique(ann$ensembl_gene),keytype='ENSEMBL',columns=c('ENTREZID','SYMBOL'))
write.csv(mapping,'01_muscle_RNAseq/outputs/statistics/ENSEMBL_ENTREZ_SYMBOL_mapping.csv',row.names=FALSE)
writeLines(c('Exported for handoff, not a new differential-expression analysis.',paste('org.Mm.eg.db version:',packageVersion('org.Mm.eg.db')),'Many-to-many mapping is retained. Missing/duplicate symbols must be handled explicitly when comparing the author expression table.'),'01_muscle_RNAseq/outputs/statistics/gene_mapping_methods.txt')

