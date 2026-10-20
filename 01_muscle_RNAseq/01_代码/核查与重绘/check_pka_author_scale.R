# Quick check: PKA/calcium genes on the author VST scale
author <- read.csv(gzfile('work/gdf15/data/GSE229794_CountsNormalizedByDESeq2.csv.gz'),
                   check.names = FALSE, row.names = 1)
am <- as.matrix(author); storage.mode(am) <- 'numeric'
g <- grep('^GDF15', colnames(am)); p <- grep('^PairFed', colnames(am))
d <- rowMeans(am[, g]) - rowMeans(am[, p])
pka <- c('Ppargc1a', 'Ucp3', 'Atp2a1', 'Sln', 'Pln', 'Atp2a2', 'Ryr1', 'Ryr2',
         'Casr', 'Fkbp5', 'Sik1', 'Myo1e')
cat('PKA/calcium genes, author VST difference (GDF15 - PairFed):\n')
for (gn in pka)
  if (gn %in% rownames(am)) cat(sprintf('%-9s dVST=%+.3f\n', gn, d[gn])) else
    cat(sprintf('%-9s not in author matrix\n', gn))
cat('\nTop 15 positive dVST (author matrix):\n'); print(round(sort(d, decreasing = TRUE)[1:15], 3))
cat('\nTop 15 negative dVST (author matrix):\n'); print(round(sort(d)[1:15], 3))
