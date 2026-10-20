# Run from the unzipped package root. No extra R packages required.
manifest <- read.csv('06_records/file_manifest.csv',stringsAsFactors=FALSE)
stopifnot(all(file.exists(manifest$path)))
got <- unname(tools::md5sum(manifest$path))
stopifnot(!anyNA(got),identical(tolower(got),tolower(manifest$md5)))
stopifnot(all(file.info(manifest$path)$size==manifest$bytes))
x<-read.csv(gzfile('01_data/GSE229708_Counts4allSamples.csv.gz'),row.names=1,check.names=FALSE)
m<-read.csv('01_data/sample_metadata.csv')
stopifnot(nrow(x)==16245,ncol(x)==18,identical(names(x),m$sample))
for(nm in c('VST','rlog')) {
 pc<-read.csv(paste0('04_plot_data/PCA_',nm,'_coordinates.csv'))
 stopifnot(nrow(pc)==18,identical(pc$sample,m$sample),all(is.finite(pc$PC1)),all(is.finite(pc$PC4)))
}
stopifnot(readLines('06_records/modeling_complete.txt')=='success')
cat('PASS: complete files, checksums, sample identities and plotting coordinates verified.\n')
