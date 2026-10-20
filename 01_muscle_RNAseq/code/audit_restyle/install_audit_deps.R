# Install handoff dependencies for the audit (into project-local R-library)
.libPaths(c(normalizePath('work/gdf15/R-library'), .libPaths()))
options(repos = c(CRAN = 'https://cloud.r-project.org'))
cran <- c('BiocManager', 'pheatmap', 'PoiClaClu')
missing <- cran[!vapply(cran, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = .libPaths()[1])
bioc <- c('DESeq2', 'AnnotationDbi', 'org.Mm.eg.db', 'GO.db', 'GOstats')
missing <- bioc[!vapply(bioc, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) BiocManager::install(missing, lib = .libPaths()[1], ask = FALSE, update = FALSE)
for (p in c(cran, bioc)) cat(p, ':', requireNamespace(p, quietly = TRUE), '\n')
