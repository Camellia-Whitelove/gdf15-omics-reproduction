# Default Fig.4i uses the original paper-style renderer, including the truncated axis.
# Statistical values are unchanged; no independent animal experiment is claimed.
source('01_muscle_RNAseq/code/common.R')
input <- '01_muscle_RNAseq/evidence/fig4i_values.csv'
manifest <- read.csv('01_muscle_RNAseq/06_records/input_manifest.csv',stringsAsFactors=FALSE)
expected <- manifest[manifest$path=='evidence/fig4i_values.csv',]
stopifnot(nrow(expected)==1,unname(tools::md5sum(input))==expected$md5,
          file.info(input)$size==expected$bytes)
ca <- read.csv(input,stringsAsFactors=FALSE)
stopifnot(nrow(ca)==16,all(table(ca$group)==8),!anyNA(ca$CAF_minus_DAN),
          max(abs(ca$difference_from_fig4i))<.001)
out <- '01_muscle_RNAseq/outputs/figures/paper_style'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
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


stats_out <- '01_muscle_RNAseq/outputs/fig4i'
dir.create(stats_out,recursive=TRUE,showWarnings=FALSE)
write.csv(data.frame(test='two-sided unpaired Student t',p=test$p.value,
                     mean_pairfed=unname(m[1]),mean_GDF15=unname(m[2])),
          file.path(stats_out,'statistics.csv'),row.names=FALSE)
writeLines(c('Fig.4i default: original paper-style draw4i renderer, y-axis 3 to 6; red Pair-fed and blue GDF15.',
             'Input: original Fig.4i source values; CAF-DAN rounding differences retained for verification only.',
             'Two-sided unpaired Student t test, equal variance; means +/- SEM.',
             'Truncated range is preserved as requested; values are not changed or removed from the statistical test.',
             capture.output(sessionInfo())),file.path(stats_out,'methods_session.txt'))
cat(sprintf('Fig.4i P = %.8f; original paper style restored.\n',test$p.value))
