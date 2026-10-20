# Sensitivity analysis (documented, separate from main analysis):
# DEG set = padj < 0.1 only (no |log2FC| threshold), GDF15 vs Pairfed.
# Purpose: locate where the paper's Fig.4c cAMP/PKA signal could come from.
.libPaths(c(normalizePath('work/gdf15/R-library'), .libPaths()))
suppressPackageStartupMessages({
  library(AnnotationDbi); library(org.Mm.eg.db); library(GOstats)
})
out <- 'outputs/audit_20261011'
sink(file.path(out, 'sensitivity_padj_only_GO.txt'), split = TRUE)

res_gp <- read.csv('outputs/statistics/GDF15_vs_Pairfed.csv', stringsAsFactors = FALSE)
deg <- res_gp[!is.na(res_gp$padj) & res_gp$padj < 0.1, ]
cat('DEGs by padj<0.1 only (no LFC filter):', nrow(deg), 'genes\n')
deg_entrez <- na.omit(unique(select(org.Mm.eg.db, keys = na.omit(deg$symbol),
                                    keytype = 'SYMBOL', columns = 'ENTREZID')$ENTREZID))
cat('mapped to ENTREZ:', length(deg_entrez), '\n')
cat('PKA/calcium genes in this set:',
    paste(intersect(c('Ppargc1a', 'Ucp3', 'Atp2a1', 'Sln', 'Pln', 'Atp2a2', 'Ryr1', 'Ryr2'),
                    deg$symbol), collapse = ', '), '\n')

ens <- sub('\\.[0-9]+$', '', res_gp$gene_id[!is.na(res_gp$pvalue)])
map_all <- select(org.Mm.eg.db, keys = unique(ens), keytype = 'ENSEMBL', columns = 'ENTREZID')
bg_expressed <- unique(na.omit(map_all$ENTREZID))
all_entrez <- keys(org.Mm.eg.db, keytype = 'ENTREZID')

run_hyperg <- function(universe, label) {
  params <- new('GOHyperGParams', geneIds = deg_entrez, universeGeneIds = universe,
                annotation = 'org.Mm.eg.db', ontology = 'BP',
                pvalueCutoff = 1, conditional = FALSE, testDirection = 'over')
  hg <- hyperGTest(params)
  df <- summary(hg, pvalue = 1)
  df$padj <- p.adjust(df$Pvalue, 'BH')
  df <- df[order(df$Pvalue), ]
  cat(sprintf('\n-- %s : BP terms tested = %d ; BH<0.1 = %d\n',
              label, nrow(df), sum(df$padj < 0.1)))
  print(head(df[, c('GOBPID', 'Term', 'Pvalue', 'padj', 'Count', 'Size')], 12), digits = 3)
  write.csv(df, file.path(out, paste0('GOstats_BP_padjOnly_', label, '.csv')), row.names = FALSE)
  key <- grep('cAMP|protein kinase A|adenylate cyclase', df$Term, ignore.case = TRUE)
  if (length(key)) { cat('cAMP/PKA-related terms:\n')
    print(df[key, c('GOBPID', 'Term', 'Pvalue', 'padj', 'Count', 'Size')], digits = 3)
  }
}
run_hyperg(bg_expressed, 'expressed_background')
run_hyperg(all_entrez, 'whole_database_background')
sink()
