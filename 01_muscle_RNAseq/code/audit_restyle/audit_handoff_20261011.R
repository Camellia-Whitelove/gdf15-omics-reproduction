# Handoff audit 2026-10-11: author processed expression matrix vs current pipeline
# 1) Identify transformation of the author matrix (log2 / VST-family hypothesis)
# 2) Sample/gene correspondence between author columns and our samples
# 3) Compare fold changes (GDF15 vs Pairfed, GDF15 vs Vehicle)
# All outputs go to outputs/audit_20261011/ (no handoff files are overwritten)

out <- 'outputs/audit_20261011'
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sink(file.path(out, 'author_matrix_audit.txt'), split = TRUE)

author <- read.csv(gzfile('work/gdf15/data/GSE229794_CountsNormalizedByDESeq2.csv.gz'),
                   check.names = FALSE, row.names = 1)
am <- as.matrix(author)
storage.mode(am) <- 'numeric'
cat('=== Author matrix structure ===\n')
cat('dim:', nrow(am), 'genes x', ncol(am), 'samples\n')
cat('columns:', paste(colnames(am), collapse = ', '), '\n')
cat('value range:', sprintf('%.4f - %.4f\n', min(am), max(am)))
cat('any negative / zero:', any(am <= 0), '\n')
cat('fractional part of 2^x within 0.01 of integer:',
    mean(abs(2^am - round(2^am)) < 0.01), '\n')
cat('genes with duplicated rownames:', sum(duplicated(rownames(am))), '\n')

## Our normalized counts
norm <- read.csv('outputs/statistics/DESeq2_normalized_counts.csv',
                 check.names = FALSE, stringsAsFactors = FALSE)
rownames(norm) <- norm$gene_id; norm$gene_id <- NULL
nm <- as.matrix(norm)
meta <- read.csv('outputs/sample_metadata.csv', stringsAsFactors = FALSE)
meta <- meta[match(colnames(nm), meta$sample_alias), ]
ann <- read.csv('work/gdf15/data/reference/gene_annotation.csv', stringsAsFactors = FALSE)
sym <- ann$symbol[match(rownames(nm), ann$gene_id)]
cat('\n=== Our matrix ===\n')
cat('dim:', nrow(nm), 'x', ncol(nm), '; mapped symbols:', sum(!is.na(sym)), '\n')
for (g in c('Vehicle', 'GDF15', 'Pairfed'))
  cat(g, ':', paste(meta$sample_alias[meta$condition == g], collapse = ', '), '\n')

logour <- log2(nm + 1)
rownames(logour) <- sym

common <- intersect(rownames(am), sym[!is.na(sym)])
cat('\ncommon gene symbols (author vs ours):', length(common),
    '/', nrow(am), 'author genes\n')

## ---- 2) sample correspondence ----
cor_mat <- cor(am[common, ], logour[common, ], method = 'pearson')
best <- apply(cor_mat, 1, which.max)
author_group <- tolower(sub('\\..*$', '', colnames(am)))
best_group <- tolower(meta$condition[best])
agree <- sum(author_group == best_group)
cat('\n=== Sample correspondence (best-matching sample per author column) ===\n')
for (j in seq_len(ncol(am)))
  cat(sprintf('%-10s -> %-12s %-8s r=%.3f%s\n', colnames(am)[j],
              meta$sample_alias[best[j]], meta$condition[best[j]],
              cor_mat[j, best[j]],
              ifelse(author_group[j] == best_group[j], '', '  <-- GROUP MISMATCH')))
cat('group agreement for best match:', agree, '/', ncol(am), '\n')

## ---- 1) transformation check ----
cat('\n=== Transformation regression: author ~ a + b * log2(our norm counts + 1) ===\n')
for (j in seq_len(ncol(am))) {
  i <- best[j]
  if (tolower(meta$condition[i]) != author_group[j]) next
  fit <- lm(am[common, j] ~ logour[common, i])
  cat(sprintf('%-10s vs %-12s slope=%.4f intercept=%.4f r2=%.4f resid_sd=%.4f\n',
              colnames(am)[j], meta$sample_alias[i], coef(fit)[2], coef(fit)[1],
              summary(fit)$r.squared, sd(residuals(fit))))
}

mean_expr <- rowMeans(logour[common, ])
bins <- cut(mean_expr, breaks = quantile(mean_expr, seq(0, 1, 0.1)), include.lowest = TRUE)
cat('\n=== Local slope author ~ log2(our norm+1) by expression decile (Vehicle.1 vs GSM7177833) ===\n')
j <- 1; i <- best[1]
for (b in levels(bins)) {
  idx <- which(bins == b)
  fit <- lm(am[common, j][idx] ~ logour[common, i][idx])
  cat(sprintf('%-22s n=%5d mean_log2_our=%6.2f slope=%.3f r2=%.3f\n', b, length(idx),
              mean(mean_expr[idx]), coef(fit)[2], summary(fit)$r.squared))
}

## ---- 3) fold-change comparison ----
gdf_cols <- grep('^GDF15', colnames(am)); pair_cols <- grep('^PairFed', colnames(am)); veh_cols <- grep('^Vehicle', colnames(am))
lfc_gvp_author <- rowMeans(am[, gdf_cols]) - rowMeans(am[, pair_cols])
lfc_gvv_author <- rowMeans(am[, gdf_cols]) - rowMeans(am[, veh_cols])
names(lfc_gvp_author) <- rownames(am); names(lfc_gvv_author) <- rownames(am)

res_gp <- read.csv('outputs/statistics/GDF15_vs_Pairfed.csv', stringsAsFactors = FALSE)
res_gv <- read.csv('outputs/statistics/GDF15_vs_Vehicle.csv', stringsAsFactors = FALSE)
m1 <- match(names(lfc_gvp_author), res_gp$symbol)
m2 <- match(names(lfc_gvv_author), res_gv$symbol)
ok1 <- !is.na(m1) & !is.na(res_gp$log2FoldChange[ifelse(is.na(m1), 1L, m1)])
ok2 <- !is.na(m2) & !is.na(res_gv$log2FoldChange[ifelse(is.na(m2), 1L, m2)])
cat('\n=== Fold-change concordance (author matrix implied LFC vs our DESeq2 LFC) ===\n')
cat('GDF15 vs Pairfed : n =', sum(ok1), ' pearson r =',
    sprintf('%.3f', cor(lfc_gvp_author[ok1], res_gp$log2FoldChange[m1[ok1]])),
    ' spearman rho =', sprintf('%.3f', cor(lfc_gvp_author[ok1], res_gp$log2FoldChange[m1[ok1]], method = 'spearman')), '\n')
cat('GDF15 vs Vehicle : n =', sum(ok2), ' pearson r =',
    sprintf('%.3f', cor(lfc_gvv_author[ok2], res_gv$log2FoldChange[m2[ok2]])),
    ' spearman rho =', sprintf('%.3f', cor(lfc_gvv_author[ok2], res_gv$log2FoldChange[m2[ok2]], method = 'spearman')), '\n')

## implied DEGs on the author scale (|LFC|>0.6) and overlap with our DEGs
our_deg_symbols <- res_gp$symbol[which(res_gp$DEG)]
author_deg_gp <- names(lfc_gvp_author)[abs(lfc_gvp_author) > 0.6]
cat('\n=== DEG overlap, GDF15 vs Pairfed, threshold |LFC|>0.6 (author scale has no padj) ===\n')
cat('our DEGs (padj<0.1 & |LFC|>0.6):', length(our_deg_symbols), '\n')
cat('author-matrix genes with |LFC|>0.6:', length(author_deg_gp), '\n')
cat('overlap:', length(intersect(our_deg_symbols, author_deg_gp)), '\n')

write.csv(data.frame(symbol = names(lfc_gvp_author), author_lfc_gvp = lfc_gvp_author,
                     our_lfc_gvp = ifelse(is.na(m1), NA, res_gp$log2FoldChange[ifelse(is.na(m1), 1L, m1)]),
                     our_padj_gvp = ifelse(is.na(m1), NA, res_gp$padj[ifelse(is.na(m1), 1L, m1)]),
                     our_DEG = ifelse(is.na(m1), NA, res_gp$DEG[ifelse(is.na(m1), 1L, m1)])),
          file.path(out, 'author_vs_our_LFC_GDF15_vs_Pairfed.csv'), row.names = FALSE)
write.csv(data.frame(author_column = colnames(am), best_our_sample = meta$sample_alias[best],
                     best_condition = meta$condition[best], pearson_r = cor_mat[cbind(seq_len(ncol(am)), best)]),
          file.path(out, 'author_column_sample_matching.csv'), row.names = FALSE)
cat('\nAUDIT PART 1 COMPLETE\n')
sink()
