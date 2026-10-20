# Explicit installation only; run.R never installs software automatically.
extra <- Sys.getenv('GDF15_R_LIB')
if (nzchar(extra)) {
  dir.create(extra, recursive=TRUE, showWarnings=FALSE)
  .libPaths(c(extra, .libPaths()))
}
options(repos=c(CRAN='https://cloud.r-project.org'), timeout=600)
cran <- c('BiocManager','ggplot2','pheatmap','PoiClaClu','RColorBrewer','png','jsonlite')
need <- cran[!vapply(cran, requireNamespace, logical(1), quietly=TRUE)]
if (length(need)) install.packages(need)
bioc <- c('DESeq2','Rsubread','ShortRead','Rsamtools','AnnotationDbi',
          'org.Mm.eg.db','GO.db','GOstats','tximport')
need <- bioc[!vapply(bioc, requireNamespace, logical(1), quietly=TRUE)]
if (length(need)) BiocManager::install(need, ask=FALSE, update=FALSE)
cat('Dependencies available. Record actual versions with sessionInfo().\n')
print(sessionInfo())
