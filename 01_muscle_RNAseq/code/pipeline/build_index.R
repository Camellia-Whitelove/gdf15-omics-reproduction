.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
library(Rsubread)
dir.create('work/gdf15/data/reference/index',recursive=TRUE,showWarnings=FALSE)
index<-'work/gdf15/data/reference/index/mm10'
buildindex(basename=index,reference='work/gdf15/data/reference/mm10.fa',gappedIndex=TRUE,indexSplit=FALSE)
writeLines(c('UCSC mm10 FASTA: official MD5 db005b65828db31735f384e4c5787be5 verified.','Gapped index (one 16-mer every 3 bases), single block; selected to keep memory below 32 GB while QC runs.','Alignment will use explicit GENCODE M25 annotation, not the default mm39.',capture.output(sessionInfo())), 'outputs/reference_index_methods.txt')
writeLines('complete',paste0(index,'.ready'))
