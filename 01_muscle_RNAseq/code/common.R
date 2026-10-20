# All muscle R scripts run from the repository root.
if (!dir.exists('01_muscle_RNAseq/code')) {
  stop('Run from the repository root, preferably with Rscript run.R <mode>.')
}
extra <- Sys.getenv('GDF15_R_LIB')
if (nzchar(extra)) .libPaths(c(extra, .libPaths()))
for (d in c('outputs', 'outputs/qc', 'outputs/alignment', 'outputs/statistics',
            'outputs/figures', 'outputs/physiology', 'data/raw', 'data/clean')) {
  dir.create(file.path('01_muscle_RNAseq', d), recursive=TRUE, showWarnings=FALSE)
}
