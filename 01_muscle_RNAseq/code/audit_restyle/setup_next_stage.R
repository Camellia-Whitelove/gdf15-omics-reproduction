source('01_muscle_RNAseq/code/common.R')
dir.create('01_muscle_RNAseq/R-library',recursive=TRUE,showWarnings=FALSE)
.libPaths(c(normalizePath('01_muscle_RNAseq/R-library', mustWork=FALSE),.libPaths()))
options(repos=c(CRAN='https://cloud.r-project.org'))
cran<-c('BiocManager','pheatmap','PoiClaClu')
missing<-cran[!vapply(cran,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing))install.packages(missing,lib=.libPaths()[1])
bioc<-c('DESeq2','AnnotationDbi','org.Mm.eg.db','GO.db')
missing<-bioc[!vapply(bioc,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing))BiocManager::install(missing,lib=.libPaths()[1],ask=FALSE,update=FALSE)
print(sessionInfo())

