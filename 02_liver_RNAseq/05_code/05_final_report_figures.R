# Final report-style figures for liver Fig.1i / Fig.1j
# Reads from 04_plot_data; writes to 07_figures/final/.
extra <- Sys.getenv('GDF15_R_LIB')
if (nzchar(extra)) .libPaths(c(extra, .libPaths()))
suppressPackageStartupMessages({
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
})

outdir <- '07_figures/final'
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ---- colour scheme (close to paper / ggplot2 defaults) ----
cols <- c(GDF15 = '#F8766D', PairFed = '#00BA38', Vehicle = '#619CFF')

# ---- Fig.1i: PCA PC1 vs PC4 for both rlog and VST ----
make_1i <- function(transform) {
  z <- read.csv(paste0('04_plot_data/PCA_', transform, '_coordinates.csv'), stringsAsFactors = FALSE)
  pct <- read.csv(paste0('04_plot_data/PCA_', transform, '_variance.csv'), stringsAsFactors = FALSE)$variance_percent
  z$condition <- factor(z$condition, levels = c('GDF15', 'PairFed', 'Vehicle'))

  ggplot(z, aes(x = PC1, y = PC4, color = condition)) +
    geom_point(size = 2.2, stroke = 0, alpha = 0.95) +
    stat_ellipse(type = 't', level = 0.95, linewidth = 0.6) +
    scale_color_manual(values = cols, name = 'Group') +
    labs(
      x = sprintf('PC1: %.2f%% variance', pct[1]),
      y = sprintf('PC4: %.2f%% variance', pct[4])
    ) +
    coord_cartesian(clip = 'off') +
    theme_classic(base_size = 12) +
    theme(
      plot.margin = unit(c(1, 1, 1, 1), 'lines'),
      legend.position = 'right',
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10),
      axis.title = element_text(size = 12),
      axis.text = element_text(size = 10, color = 'black'),
      axis.line = element_line(color = 'black', linewidth = 0.4),
      axis.ticks = element_line(color = 'black', linewidth = 0.4)
    )
}

for (nm in c('rlog', 'VST')) {
  p <- make_1i(nm)
  ggsave(file.path(outdir, paste0('Fig1i_', nm, '_final.png')), p,
         width = 6.0, height = 5.0, dpi = 220, bg = 'white')
  ggsave(file.path(outdir, paste0('Fig1i_', nm, '_final.pdf')), p,
         width = 6.0, height = 5.0, device = cairo_pdf)
}

# ---- Fig.1j: raw-count Poisson sample-distance heatmap ----
m <- as.matrix(read.csv('04_plot_data/distance_raw_Poisson.csv',
                        row.names = 1, check.names = FALSE))
# nicer labels: "GDF15 1" etc.
nice_labels <- function(nm) {
  sub('GDF15\\.', 'GDF15 ', sub('PairFed\\.', 'PairFed ', sub('Vehicle\\.', 'Vehicle ', nm)))
}
rownames(m) <- nice_labels(rownames(m))
colnames(m) <- nice_labels(colnames(m))

# Match the published Fig.1j layout: no row labels, subtle grey90 cell borders,
# vertical bottom labels, comma-separated colour-bar ticks, and a rotated title.
hm <- pheatmap(m,
               clustering_distance_rows = as.dist(m),
               clustering_distance_cols = as.dist(m),
               color = colorRampPalette(rev(brewer.pal(n = 7, name = 'RdYlBu')))(100),
               border_color = 'grey90',
               show_rownames = FALSE,
               fontsize = 8.5,
               fontsize_col = 8,
               angle_col = 90,
               cellwidth = 12,
               cellheight = 12,
               main = NA,
               legend_breaks = c(0, 5000, 10000, 15000, 20000),
               legend_labels = c('0', '5,000', '10,000', '15,000', '20,000'))

# pheatmap wrote to a temporary device; re-open to capture with the legend title
png(file.path(outdir, 'Fig1j_raw_Poisson_final.png'),
    width = 1400, height = 1300, res = 220)
print(hm)
grid::grid.text('Sample distance', x = 0.87, y = 0.55, rot = 90,
                gp = grid::gpar(fontsize = 10))
dev.off()

pdf(file.path(outdir, 'Fig1j_raw_Poisson_final.pdf'),
    width = 6.4, height = 5.9)
print(hm)
grid::grid.text('Sample distance', x = 0.87, y = 0.55, rot = 90,
                gp = grid::gpar(fontsize = 10))
dev.off()

cat('Final report figures written to', outdir, '\n')
