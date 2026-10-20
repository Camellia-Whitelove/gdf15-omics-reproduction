source('01_muscle_RNAseq/code/common.R')
options(timeout=60, repos=c(CRAN="https://cloud.r-project.org"))
task_library <- normalizePath("01_muscle_RNAseq/R-library", mustWork=FALSE)
dir.create(task_library, recursive=TRUE, showWarnings=FALSE)
.libPaths(c(task_library, .libPaths()))
if (!requireNamespace("BiocManager", quietly=TRUE)) {
  install.packages("BiocManager", lib=task_library, type="binary")
}
if (!requireNamespace("BiocManager", quietly=TRUE)) stop("BiocManager installation failed; pause workflow.")
BiocManager::install("Rsubread", lib=task_library, ask=FALSE, update=FALSE, type="binary")
if (!requireNamespace("Rsubread", quietly=TRUE)) stop("Rsubread installation failed; pause workflow.")
cat("Rsubread version:", as.character(packageVersion("Rsubread")), "\n")
cat("Required functions:", all(c("buildindex","align","featureCounts") %in% getNamespaceExports("Rsubread")), "\n")
writeLines(capture.output(sessionInfo()), "01_muscle_RNAseq/environment_session.txt")

