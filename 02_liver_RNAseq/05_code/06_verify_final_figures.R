# Verify final figures against original leaf order / variance expectations.
suppressPackageStartupMessages(library(pheatmap))

# ---- Fig.1i variance labels ----
for (nm in c('rlog', 'VST')) {
  pct <- read.csv(paste0('04_plot_data/PCA_', nm, '_variance.csv'))$variance_percent
  cat(sprintf('Fig.1i %s: PC1=%.2f%%, PC4=%.2f%%\n', nm, pct[1], pct[4]))
}

# ---- Fig.1j leaf order vs original ----
m <- as.matrix(read.csv('04_plot_data/distance_raw_Poisson.csv',
                        row.names = 1, check.names = FALSE))
orig_order <- read.csv('04_plot_data/order_raw_Poisson.csv', stringsAsFactors = FALSE)$sample
hm <- pheatmap(m, clustering_distance_rows = as.dist(m),
               clustering_distance_cols = as.dist(m), silent = TRUE)
# pheatmap tree order may include dendrogram flip; leaf order must equal original.
leaf <- rownames(m)[hm$tree_row$order]
cat('Fig.1j raw Poisson leaf order match:', identical(leaf, orig_order), '\n')
if (!identical(leaf, orig_order)) {
  cat('Got:', paste(leaf, collapse = ','), '\n')
  cat('Expected:', paste(orig_order, collapse = ','), '\n')
}
