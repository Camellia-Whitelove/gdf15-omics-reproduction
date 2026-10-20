# Recalculate GO MF from the archived kallisto-derived input lists.
# This re-runs enrichment only; it does not re-run FASTQ quantification or DESeq2.
source('01_muscle_RNAseq/code/common.R')
suppressPackageStartupMessages({library(GOstats);library(org.Mm.eg.db);library(GO.db)})
input <- '01_muscle_RNAseq/evidence/fig4c_kallisto_20261011'
out <- '01_muscle_RNAseq/outputs/fig4c_mf_rerun'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
manifest <- read.csv(file.path(input,'file_manifest.csv'),stringsAsFactors=FALSE)
files <- file.path(input,manifest$path)
stopifnot(all(file.exists(files)),all(file.info(files)$size==manifest$bytes),
          identical(unname(tools::md5sum(files)),manifest$md5))
r <- read.csv(file.path(input,'paper_threshold_DEGs.csv'),colClasses=c(ENTREZID='character'))
bg <- read.csv(file.path(input,'padj_eligible_background.csv'),colClasses='character')$ENTREZID
target <- read.csv(file.path(input,'original_figure_terms.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(r)==31,all(r$padj<.1),all(abs(r$log2FoldChange)>.6),
          !anyDuplicated(bg),nrow(target)==10)
sig <- intersect(unique(r$ENTREZID),bg)
stopifnot(length(sig)==30,length(bg)==9380)
go <- AnnotationDbi::select(org.Mm.eg.db,keys=bg,keytype='ENTREZID',columns=c('GOALL','ONTOLOGYALL'))
go <- unique(go[!is.na(go$GOALL)&go$ONTOLOGYALL=='MF',c('ENTREZID','GOALL')])
params <- new('GOHyperGParams',geneIds=sig,universeGeneIds=bg,
              annotation='org.Mm.eg.db',ontology='MF',conditional=FALSE,
              pvalueCutoff=.05,testDirection='over')
hg <- hyperGTest(params)
pv <- pvalues(hg)
tab <- data.frame(GO=names(pv),pvalue=as.numeric(pv),padj=p.adjust(pv,'BH'))
tab$Count <- as.numeric(geneCounts(hg)[tab$GO])
tab$Size <- as.numeric(universeCounts(hg)[tab$GO])
tab$selected_n <- length(sig);tab$universe_N <- length(bg)
tr <- data.frame(GO=target$GOID,description=target$TERM)
tr$Count <- vapply(tr$GO,function(id)sum(sig %in% go$ENTREZID[go$GOALL==id]),0L)
tr$pvalue <- tab$pvalue[match(tr$GO,tab$GO)]
tr$padj <- tab$padj[match(tr$GO,tab$GO)]
tr$GeneRatio <- tr$Count/length(sig)
historical <- read.csv(file.path(input,'original_terms_comparison.csv'))
historical <- historical[historical$run=='padj_eligible_unconditional',]
tr$archived_Count <- historical$Count[match(tr$GO,historical$GO)]
tr$archived_padj <- historical$padj[match(tr$GO,historical$GO)]
write.csv(tab[order(tab$padj),],file.path(out,'all_MF_terms.csv'),row.names=FALSE)
write.csv(tr,file.path(out,'original_terms_comparison.csv'),row.names=FALSE)
status <- data.frame(selected_MF=length(sig),background=length(bg),tested_terms=length(pv),
                     significant_BH_01=sum(tab$padj<.1),
                     original_significant_BH_01=sum(tr$padj<.1,na.rm=TRUE),
                     original_zero_hits=sum(tr$Count==0),
                     archived_Counts_match=all(tr$Count==tr$archived_Count))
write.csv(status,file.path(out,'run_summary.csv'),row.names=FALSE)
writeLines(c('MF enrichment rerun from archived kallisto-derived IDs; not an upstream quantification rerun.',
             'GOstats unconditional overrepresentation; BH across the full pvalues() vector.',
             'Fixed eligible background and selected IDs. Database updates may change annotations and P values.',
             capture.output(sessionInfo())),file.path(out,'methods_session.txt'))
print(status)
cat('Original Fig.4c recovery is NOT claimed. Historical files were not overwritten.\n')
