# Run once only if required packages are missing. Requires Internet.
cran <- c('ggplot2','pheatmap','BiocManager')
need <- cran[!vapply(cran,requireNamespace,TRUE,quietly=TRUE)]
if(length(need))install.packages(need,repos='https://cloud.r-project.org')
bioc <- c('DESeq2','PoiClaClu')
need <- bioc[!vapply(bioc,requireNamespace,TRUE,quietly=TRUE)]
if(length(need))BiocManager::install(need,ask=FALSE,update=FALSE)
