source('01_muscle_RNAseq/code/common.R')
# Historical diagnostic: (A) compare rlog/VST scales, without identifying the author's transform.
#                       (B) GO BP sensitivity, not the original Fig.4c MF analysis.
# Use audit_fig4c_mf.R for the archived MF enrichment inputs and full-P-value BH correction.
.libPaths(c(normalizePath('01_muscle_RNAseq/R-library', mustWork=FALSE), .libPaths()))
suppressPackageStartupMessages({
  library(DESeq2); library(AnnotationDbi); library(org.Mm.eg.db)
  library(GO.db); library(GOstats)
})
out <- '01_muscle_RNAseq/outputs/audit_20261011'
sink(file.path(out, 'transform_and_GOstats_audit.txt'), split = TRUE)

author <- read.csv(gzfile('01_muscle_RNAseq/data/GSE229794_CountsNormalizedByDESeq2.csv.gz'),
                   check.names = FALSE, row.names = 1)
am <- as.matrix(author); storage.mode(am) <- 'numeric'

dds <- readRDS('01_muscle_RNAseq/outputs/statistics/deseq2_model.rds')
meta <- read.csv('01_muscle_RNAseq/outputs/sample_metadata.csv', stringsAsFactors = FALSE)
meta <- meta[match(colnames(dds), meta$sample_alias), ]
ann <- read.csv('01_muscle_RNAseq/data/reference/gene_annotation.csv', stringsAsFactors = FALSE)
sym <- ann$symbol[match(rownames(dds), ann$gene_id)]

## ---- A) which variance-stabilising transform is the author matrix? ----
cat('=== A) author matrix vs our rlog / vst (same genes, matched samples) ===\n')
rld <- assay(rlog(dds, blind = FALSE))
vsd <- assay(vst(dds, blind = FALSE))
rownames(rld) <- sym; rownames(vsd) <- sym
common <- intersect(rownames(am), sym[!is.na(sym)])
acols <- c(paste0('Vehicle.', 1:5), paste0('GDF15.', 1:6), paste0('PairFed.', 2:6))
samples <- c(meta$sample_alias[meta$condition == 'Vehicle'],
             meta$sample_alias[meta$condition == 'GDF15'],
             meta$sample_alias[meta$condition == 'Pairfed'])
report <- data.frame()
for (j in seq_along(acols)) {
  i <- samples[j]
  ra <- cor(am[common, j], rld[common, i])
  va <- cor(am[common, j], vsd[common, i])
  fr <- lm(am[common, j] ~ rld[common, i]); fv <- lm(am[common, j] ~ vsd[common, i])
  report <- rbind(report, data.frame(author_col = acols[j], our_sample = i,
    r_author_rlog = ra, r_author_vst = va,
    slope_rlog = coef(fr)[2], slope_vst = coef(fv)[2],
    r2_rlog = summary(fr)$r.squared, r2_vst = summary(fv)$r.squared))
}
print(report, digits = 3)
write.csv(report, file.path(out, 'author_vs_rlog_vst.csv'), row.names = FALSE)
cat('mean cor author~rlog:', sprintf('%.4f', mean(report$r_author_rlog)),
    ' mean cor author~vst:', sprintf('%.4f', mean(report$r_author_vst)), '\n')
cat('mean slope rlog:', sprintf('%.4f', mean(report$slope_rlog)),
    ' mean slope vst:', sprintf('%.4f', mean(report$slope_vst)), '\n')

## ---- B) GOstats-style enrichment on our GDF15 vs Pairfed DEGs ----
cat('\n=== B) GOstats re-run on our 35 DEGs (GDF15 vs Pairfed) ===\n')
res_gp <- read.csv('01_muscle_RNAseq/outputs/statistics/GDF15_vs_Pairfed.csv', stringsAsFactors = FALSE)
deg <- res_gp[which(res_gp$DEG), ]
cat('DEG symbols:', nrow(deg), '; with symbol:', sum(!is.na(deg$symbol)), '\n')
deg_entrez <- na.omit(unique(select(org.Mm.eg.db, keys = na.omit(deg$symbol),
                                    keytype = 'SYMBOL', columns = 'ENTREZID')$ENTREZID))
cat('DEG ENTREZ ids:', length(deg_entrez), '\n')

## background 1: all tested genes in our model (expressed background)
ens <- sub('\\.[0-9]+$', '', res_gp$gene_id[!is.na(res_gp$pvalue)])
map_all <- select(org.Mm.eg.db, keys = unique(ens), keytype = 'ENSEMBL', columns = 'ENTREZID')
bg_expressed <- unique(na.omit(map_all$ENTREZID))
cat('expressed background ENTREZ:', length(bg_expressed), '\n')

## background 2: GOstats default = whole annotation database
all_entrez <- keys(org.Mm.eg.db, keytype = 'ENTREZID')
cat('whole-database background ENTREZ:', length(all_entrez), '\n')

run_hyperg <- function(universe, label) {
  params <- new('GOHyperGParams', geneIds = deg_entrez, universeGeneIds = universe,
                annotation = 'org.Mm.eg.db', ontology = 'BP',
                pvalueCutoff = 1, conditional = FALSE, testDirection = 'over')
  hg <- hyperGTest(params)
  df <- summary(hg, pvalue = 1)
  df$padj <- p.adjust(df$Pvalue, 'BH')
  df <- df[order(df$Pvalue), ]
  cat(sprintf('\n-- %s : BP terms tested = %d ; terms with raw P<0.05 = %d ; BH<0.1 = %d\n',
              label, nrow(df), sum(df$Pvalue < 0.05), sum(df$padj < 0.1)))
  print(head(df[, c('GOBPID', 'Term', 'Pvalue', 'padj', 'Count', 'Size')], 10), digits = 3)
  write.csv(df, file.path(out, paste0('GOstats_BP_', label, '.csv')), row.names = FALSE)
  ## cAMP / PKA related terms
  key <- grep('cAMP|protein kinase A|adenylate cyclase', df$Term, ignore.case = TRUE)
  if (length(key)) { cat('cAMP/PKA-related terms:\n')
    print(df[key, c('GOBPID', 'Term', 'Pvalue', 'padj', 'Count', 'Size')], digits = 3)
  } else cat('no cAMP/PKA-related terms tested with >0 overlap\n')
}
run_hyperg(bg_expressed, 'expressed_background')
run_hyperg(all_entrez, 'whole_database_background')

cat('\nGOstats version:', as.character(packageVersion('GOstats')),
    '; org.Mm.eg.db:', as.character(packageVersion('org.Mm.eg.db')),
    '; GO.db:', as.character(packageVersion('GO.db')), '\n')
cat('AUDIT PART 2 COMPLETE\n')
sink()

