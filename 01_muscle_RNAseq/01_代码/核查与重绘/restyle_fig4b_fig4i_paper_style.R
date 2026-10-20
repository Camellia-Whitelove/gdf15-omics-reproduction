# Restyle Fig 4b and Fig 4i to match the paper's Fig. 4 panels b and i (page 6).
# Style parameters extracted programmatically from the published PDF:
#   Fig 4b: pheatmap defaults -- RdYlBu(100) palette, grey60 cell borders, black
#           rotated sample labels "Vehicle 1..GDF15 6..Pair-fed 2-6", colorbar
#           labelled "Sample distance", Poisson-distance clustering.
#   Fig 4i: truncated y-axis starting at 3 (ticks 3,4,5,6), Pair-fed bar red
#           #FA0206, GDF15 bar blue #0000FF, black borders, black SEM error bars
#           with caps, points on bars, "P = 0.0081" above, diagonal x labels.
# Outputs go to outputs/figures/paper_style/ (handoff figures untouched).
.libPaths(c(normalizePath('work/gdf15/R-library'), .libPaths()))
suppressPackageStartupMessages({library(pheatmap); library(RColorBrewer); library(png)})
out <- 'outputs/figures/paper_style'
dir.create(out, recursive = TRUE, showWarnings = FALSE)

## ---------------- Fig 4b ----------------
distance <- as.matrix(read.csv('outputs/statistics/poisson_sample_distances.csv',
                               row.names = 1, check.names = FALSE))
grp <- function(gsm) {
  if (grepl('^GSM', gsm)) {
    n <- as.integer(sub('GSM', '', gsm))
    return(ifelse(n <= 7177837, sprintf('Vehicle %d', n - 7177832),
           ifelse(n <= 7177843, sprintf('GDF15 %d', n - 7177837),
                                   sprintf('Pair-fed %d', n - 7177842))))
  }
  # otherwise expect names like Vehicle_1, GDF15_1, Pairfed_2
  sub('_', ' ', sub('Pairfed', 'Pair-fed', gsm))
}
labs <- sapply(colnames(distance), grp)
rownames(distance) <- colnames(distance) <- labs
pal_rdylbu <- colorRampPalette(rev(brewer.pal(n = 7, name = 'RdYlBu')))(100)

pheatmap(distance,
         clustering_distance_rows = as.dist(distance),
         clustering_distance_cols = as.dist(distance),
         color = pal_rdylbu,
         border_color = 'grey60',
         fontsize = 7.5, fontsize_row = 6.5, fontsize_col = 6.5,
         cellwidth = 16, cellheight = 13,   # paper cell aspect 5.7 x 4.6 pt
         angle_col = '45',
         filename = file.path(out, 'Fig4b_sample_distance_paperstyle.png'))
pheatmap(distance,
         clustering_distance_rows = as.dist(distance),
         clustering_distance_cols = as.dist(distance),
         color = pal_rdylbu,
         border_color = 'grey60',
         fontsize = 7.5, fontsize_row = 6.5, fontsize_col = 6.5,
         cellwidth = 16, cellheight = 13,
         angle_col = '45',
         filename = file.path(out, 'Fig4b_sample_distance_paperstyle.pdf'))

# annotate the png/pdf: add the "Sample distance" colour-bar title only (no group legend)
add_colbar_title <- function(png_in, outfile) {
  p <- readPNG(png_in)
  W <- dim(p)[2]; H <- dim(p)[1]
  if (grepl('pdf$', outfile)) {
    # aspect ratio in inches: W/H with extra 120 px at 200 dpi
    width_in <- (W + 120) / 200
    height_in <- H / 200
    pdf(outfile, width = width_in, height = height_in)
  } else {
    png(outfile, width = W + 120, height = H, res = 200)
  }
  par(mar = rep(0, 4)); plot.new()
  rasterImage(p, 0, 0, W / (W + 120), 1)
  # colour-bar title (rotated), in the pad zone right of the bar
  text(W / (W + 120) + 0.07, 0.62, 'Sample distance', srt = 90, cex = 0.85, adj = 0.5)
  dev.off()
}
add_colbar_title(file.path(out, 'Fig4b_sample_distance_paperstyle.png'),
                 file.path(out, 'Fig4b_sample_distance_paperstyle.png'))
add_colbar_title(file.path(out, 'Fig4b_sample_distance_paperstyle.png'),
                 file.path(out, 'Fig4b_sample_distance_paperstyle.pdf'))

## ---------------- Fig 4i ----------------
ca <- read.csv('outputs/physiology/fig4i_calcium_respiration.csv', stringsAsFactors = FALSE)
ca$group <- factor(ca$group, levels = c('WT-Pair-fed', 'WT-GDF15'))
test <- t.test(CAF_minus_DAN ~ group, ca, var.equal = TRUE, alternative = 'two.sided')
m <- tapply(ca$CAF_minus_DAN, ca$group, mean)
se <- tapply(ca$CAF_minus_DAN, ca$group, function(v) sd(v) / sqrt(length(v)))
pval <- sprintf('P = %.4f', test$p.value)

draw4i <- function() {
  par(mar = c(5.6, 5.5, 2.6, 1))
  # NOTE: base barplot() does not clip bar rectangles to ylim[1] on a truncated
  # axis, so bars run below y = 3 into the bottom margin. Draw bars manually
  # with rect() instead (rectangles are clipped to the plot region).
  plot.new()
  plot.window(xlim = c(0.4, 2.35), ylim = c(3, 6))
  hw <- 0.275                      # half bar width (total 0.55, as before)
  b <- c(0.75, 1.75)               # bar centre positions
  rect(b[1] - hw, 3, b[1] + hw, m[1], col = '#FA0206', border = 'black')
  rect(b[2] - hw, 3, b[2] + hw, m[2], col = '#0000FF', border = 'black')
  title(ylab = expression(Delta * J[O[2]] * ' (CAF-DAN) (pmol s' ^ -1 * ' mg' ^ -1 * ' wet weight)'))
  axis(2, at = 3:6, labels = 3:6, las = 1)
  arrows(b, m - se, b, m + se, angle = 90, code = 3, length = 0.06, lwd = 1)
  set.seed(4)
  v1 <- ca$CAF_minus_DAN[ca$group == 'WT-Pair-fed']
  v2 <- ca$CAF_minus_DAN[ca$group == 'WT-GDF15']
  points(b[1] + runif(length(v1), -0.13, 0.13), v1, pch = 16, cex = 0.75)
  points(b[2] + runif(length(v2), -0.13, 0.13), v2, pch = 21, bg = 'white', cex = 0.75)
  # bracket + P value at top
  bracket_y <- 5.88
  segments(b[1], bracket_y, b[2], bracket_y, lwd = 0.9)
  segments(b[1], bracket_y - 0.08, b[1], bracket_y, lwd = 0.9)
  segments(b[2], bracket_y - 0.08, b[2], bracket_y, lwd = 0.9)
  text(mean(b), bracket_y + 0.10, pval, adj = c(0.5, 0), cex = 0.95, xpd = TRUE)
  # x-axis group labels below the bars (slanted, centred under each bar)
  text(b[1], 2.45, 'Pair-fed', srt = 38, adj = c(0.5, 1), cex = 0.9, xpd = TRUE)
  text(b[2], 2.45, 'GDF15', srt = 38, adj = c(0.5, 1), cex = 0.9, xpd = TRUE)
}
png(file.path(out, 'Fig4i_calcium_respiration_paperstyle.png'),
    width = 900, height = 980, res = 220)
draw4i(); dev.off()
pdf(file.path(out, 'Fig4i_calcium_respiration_paperstyle.pdf'),
    width = 4.1, height = 4.45)
draw4i(); dev.off()

cat('P value used on figure:', pval, '\n')
cat('PAPER-STYLE FIGURES WRITTEN TO', out, '\n')
