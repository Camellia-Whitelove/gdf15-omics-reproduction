# Fetch the public count matrix; the sample sheet and immutable input hashes are bundled.
if (dir.exists('02_liver_RNAseq/code')) setwd('02_liver_RNAseq')
manifest <- read.csv('06_records/input_manifest.csv', stringsAsFactors=FALSE)
url <- 'https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229708/suppl/GSE229708_Counts4allSamples.csv.gz'
target <- '01_data/GSE229708_Counts4allSamples.csv.gz'
dir.create('01_data',showWarnings=FALSE)
expected <- manifest[manifest$path==target,]
if(!file.exists(target)) {
  options(timeout=max(600,getOption('timeout')))
  temporary <- paste0(target,'.part')
  download.file(url,temporary,mode='wb',method='libcurl',quiet=FALSE)
  if(file.info(temporary)$size!=expected$bytes ||
     unname(tools::md5sum(temporary))!=expected$md5)
    stop('Download checksum mismatch; partial file kept for diagnosis. No model was fitted.')
  if(!file.rename(temporary,target))stop('Cannot move validated download into place.')
}
stopifnot(all(file.exists(manifest$path)),
          identical(unname(tools::md5sum(manifest$path)),manifest$md5),
          all(file.info(manifest$path)$size==manifest$bytes))
# Keep the original package-verification entry point usable after a fresh checkout.
write.csv(manifest,'06_records/file_manifest.csv',row.names=FALSE)
cat('PASS: public liver counts and sample metadata verified.\n')
