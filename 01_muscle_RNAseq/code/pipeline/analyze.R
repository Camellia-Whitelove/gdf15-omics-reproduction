source('01_muscle_RNAseq/code/common.R')
.libPaths(c(normalizePath('01_muscle_RNAseq/R-library', mustWork=FALSE),.libPaths()))
suppressPackageStartupMessages({library(DESeq2);library(PoiClaClu);library(pheatmap);library(AnnotationDbi);library(org.Mm.eg.db);library(GO.db)})
if(!file.exists('01_muscle_RNAseq/outputs/alignment/counting_complete.txt'))stop('Alignment/counting incomplete')
dir.create('01_muscle_RNAseq/outputs/figures',showWarnings=FALSE);dir.create('01_muscle_RNAseq/outputs/statistics',showWarnings=FALSE)
counts<-readRDS('01_muscle_RNAseq/outputs/gene_fragment_counts.rds')
meta<-read.csv('01_muscle_RNAseq/outputs/sample_metadata.csv',stringsAsFactors=FALSE)
meta<-meta[match(colnames(counts),meta$sample_alias),]
gsm<-as.integer(sub('GSM','',meta$sample_alias))
meta$condition<-factor(ifelse(gsm<=7177837,'Vehicle',ifelse(gsm<=7177843,'GDF15','Pairfed')),levels=c('Vehicle','Pairfed','GDF15'))
rownames(meta)<-meta$sample_alias
dds<-DESeqDataSetFromMatrix(round(counts),meta,~condition)
dds<-dds[rowSums(counts(dds))>=5,]
dds<-DESeq(dds)
saveRDS(dds,'01_muscle_RNAseq/outputs/statistics/deseq2_model.rds')
write.csv(data.frame(gene_id=rownames(dds),counts(dds,normalized=TRUE),check.names=FALSE),'01_muscle_RNAseq/outputs/statistics/DESeq2_normalized_counts.csv',row.names=FALSE)
write.csv(data.frame(sample=colnames(dds),condition=meta$condition,size_factor=sizeFactors(dds)),'01_muscle_RNAseq/outputs/statistics/DESeq2_size_factors.csv',row.names=FALSE)
annotation<-read.csv('01_muscle_RNAseq/data/reference/gene_annotation.csv',stringsAsFactors=FALSE)
for(contrast in list(c('GDF15','Pairfed'),c('GDF15','Vehicle'),c('Pairfed','Vehicle'))){
 res<-as.data.frame(results(dds,contrast=c('condition',contrast),alpha=0.1))
 res$gene_id<-rownames(res);res$symbol<-annotation$symbol[match(res$gene_id,annotation$gene_id)]
 res$DEG<-!is.na(res$padj)&res$padj<0.1&abs(res$log2FoldChange)>0.6
 write.csv(res,paste0('01_muscle_RNAseq/outputs/statistics/',paste(contrast,collapse='_vs_'),'.csv'),row.names=FALSE)
 cat(paste(contrast,collapse=' vs '),sum(res$DEG),'DEGs\n');flush.console()
}
res<-read.csv('01_muscle_RNAseq/outputs/statistics/GDF15_vs_Pairfed.csv',stringsAsFactors=FALSE)
write.csv(res[res$symbol %in% c('Sln','Atp2a1','Atp2a2','Ryr1','Ryr2','Pln','Ucp1','Ucp3','Ppargc1a'),],'01_muscle_RNAseq/outputs/statistics/calcium_cycling_gene_results.csv',row.names=FALSE)
poisd<-PoissonDistance(t(counts(dds)))
distance<-as.matrix(poisd$dd)
group_index<-ave(seq_len(nrow(meta)),meta$condition,FUN=seq_along)
group_index[meta$condition=='Pairfed']<-group_index[meta$condition=='Pairfed']+1
labs<-paste0(meta$condition,'_',group_index);rownames(distance)<-colnames(distance)<-labs
ann<-data.frame(Group=meta$condition);rownames(ann)<-labs
cols<-c(Vehicle='#4682B4',GDF15='#E69F00',Pairfed='#009E73')
png('01_muscle_RNAseq/outputs/figures/Fig4b_sample_distance.png',width=1800,height=1600,res=200)
pheatmap(distance,clustering_distance_rows=poisd$dd,clustering_distance_cols=poisd$dd,annotation_row=ann,annotation_col=ann,annotation_colors=list(Group=cols),color=colorRampPalette(c('white','#B6C7D6','#184566'))(100),main='Fig. 4b reproduction: Poisson sample distances',fontsize=10,border_color=NA)
dev.off()
pdf('01_muscle_RNAseq/outputs/figures/Fig4b_sample_distance.pdf',width=9,height=8)
pheatmap(distance,clustering_distance_rows=poisd$dd,clustering_distance_cols=poisd$dd,annotation_row=ann,annotation_col=ann,annotation_colors=list(Group=cols),color=colorRampPalette(c('white','#B6C7D6','#184566'))(100),main='Poisson sample distances',fontsize=10,border_color=NA)
dev.off()
write.csv(distance,'01_muscle_RNAseq/outputs/statistics/poisson_sample_distances.csv')
v<-vst(dds,blind=FALSE);pc<-prcomp(t(assay(v)));explained<-100*pc$sdev^2/sum(pc$sdev^2)
png('01_muscle_RNAseq/outputs/figures/RNAseq_PCA.png',width=1400,height=1100,res=180)
par(mar=c(5,5,3,1));plot(pc$x[,1],pc$x[,2],pch=19,col=cols[as.character(meta$condition)],cex=1.5,xlab=sprintf('PC1 (%.1f%%)',explained[1]),ylab=sprintf('PC2 (%.1f%%)',explained[2]),main='Muscle RNA-seq: VST PCA');text(pc$x[,1],pc$x[,2],labels=labs,pos=3,cex=.65);legend('topright',legend=names(cols),col=cols,pch=19,bty='n');dev.off()
png('01_muscle_RNAseq/outputs/figures/GDF15_vs_Pairfed_volcano.png',width=1400,height=1100,res=180)
plot(res$log2FoldChange,-log10(pmax(res$padj,1e-300)),col=ifelse(res$DEG,'#C44E52','#B0B0B0'),pch=16,cex=.5,xlab='log2 fold change (GDF15 / Pairfed)',ylab='-log10 BH adjusted P',main='Muscle differential expression');abline(v=c(-.6,.6),h=1,lty=2,col='grey50');focus<-which(res$symbol %in% c('Sln','Atp2a1','Atp2a2','Ryr1','Ryr2'));text(res$log2FoldChange[focus],-log10(pmax(res$padj[focus],1e-300)),labels=res$symbol[focus],pos=3,cex=.7);dev.off()
# Unconditional overrepresentation test, MF, expressed/testable gene background.
# GOALL includes propagated ancestor annotations. Database version is recorded.
ens<-sub('\\.[0-9]+$','',res$gene_id)
mapping<-AnnotationDbi::select(org.Mm.eg.db,keys=unique(ens),keytype='ENSEMBL',columns='ENTREZID')
tested_ens<-ens[!is.na(res$pvalue)]
bg<-unique(na.omit(mapping$ENTREZID[mapping$ENSEMBL %in% tested_ens]))
sig<-unique(na.omit(mapping$ENTREZID[mapping$ENSEMBL %in% ens[res$DEG]]))
go<-AnnotationDbi::select(org.Mm.eg.db,keys=bg,keytype='ENTREZID',columns=c('GOALL','ONTOLOGYALL'))
go<-unique(go[!is.na(go$GOALL)&go$ONTOLOGYALL=='MF',c('ENTREZID','GOALL')])
bg<-intersect(bg,unique(go$ENTREZID));sig<-intersect(sig,bg)
sets<-split(go$ENTREZID,go$GOALL);N<-length(bg);n<-length(sig)
enrichment<-do.call(rbind,lapply(names(sets),function(term){genes<-unique(sets[[term]]);K<-length(genes);k<-sum(genes %in% sig);data.frame(GO=term,N=N,n=n,K=K,k=k,pvalue=phyper(k-1,K,N-K,n,lower.tail=FALSE),gene_ids=paste(intersect(genes,sig),collapse=';'))}))
enrichment$padj<-p.adjust(enrichment$pvalue,'BH')
enrichment$gene_ratio<-enrichment$k/pmax(enrichment$n,1)
terms<-AnnotationDbi::select(GO.db,keys=enrichment$GO,keytype='GOID',columns='TERM')
enrichment$description<-terms$TERM[match(enrichment$GO,terms$GOID)]
enrichment<-enrichment[order(enrichment$padj,enrichment$pvalue),]
write.csv(enrichment,'01_muscle_RNAseq/outputs/statistics/GO_MF_enrichment.csv',row.names=FALSE)
top<-head(enrichment[enrichment$k>0 & enrichment$padj<0.1,],12)
png('01_muscle_RNAseq/outputs/figures/Fig4c_GO_MF_enrichment.png',width=2000,height=1300,res=180)
if(nrow(top)){
 par(mar=c(5,22,4,7));top<-top[nrow(top):1,]
 palette<-colorRampPalette(c('#2166AC','#B2182B'))(100)
 strength<--log10(pmax(top$padj,1e-300));rg<-range(strength)
 idx<-if(diff(rg)>0) 1+floor(99*(strength-rg[1])/diff(rg)) else rep(50,nrow(top))
 size<-1+2*sqrt(top$k/max(top$k))
 plot(top$k/top$n,seq_len(nrow(top)),pch=19,cex=size,col=palette[idx],yaxt='n',ylab='',xlab='Gene ratio (DEGs in term / mapped DEGs)',main='Fig. 4c: GDF15 vs Pairfed, GO molecular function',ylim=c(.5,nrow(top)+.5))
 axis(2,at=seq_len(nrow(top)),labels=top$description,las=1,cex.axis=.8)
 legend('bottomright',legend=paste('Count',unique(as.integer(quantile(top$k,c(0,.5,1))))),pch=19,pt.cex=1+2*sqrt(unique(as.integer(quantile(top$k,c(0,.5,1))))/max(top$k)),bty='n',cex=.75)
 mtext(sprintf('Color: -log10 adjusted P, blue %.2f to red %.2f',rg[1],rg[2]),side=3,line=.3,cex=.7)
}else{plot.new();text(.5,.5,'No GO MF terms pass BH adjusted P < 0.1\nunder the recorded alternative pipeline')};dev.off()
write.csv(data.frame(universe_entrez=bg),'01_muscle_RNAseq/outputs/statistics/GO_background_genes.csv',row.names=FALSE)
write.csv(data.frame(significant_entrez=sig),'01_muscle_RNAseq/outputs/statistics/GO_input_DEGs.csv',row.names=FALSE)
write.csv(data.frame(input_genes=nrow(res),testable_genes=sum(!is.na(res$pvalue)),DEGs=sum(res$DEG),GO_background_entrez=N,GO_DEG_entrez=n,MF_terms_tested=nrow(enrichment),MF_terms_padj_lt_01=sum(enrichment$padj<.1)),'01_muscle_RNAseq/outputs/statistics/GO_mapping_summary.csv',row.names=FALSE)
writeLines(c('DESeq2: design ~ condition; gene total count >=5; DEGs abs(log2FC)>0.6 and BH padj<0.1.','Fig4b: author PoissonDistance on prefiltered fragment counts; complete linkage pheatmap default.','GO: unconditional hypergeometric overrepresentation on MF GOALL annotations; BH across all MF terms in expressed/testable annotated background. This is an explicit implementation alternative to GOstats and is not claimed to recreate unpublished author settings exactly.',paste('GO background:',N,'DEGs mapped:',n),capture.output(sessionInfo())),'01_muscle_RNAseq/outputs/statistics/methods.txt')
cat('RNA STATISTICS AND FIGURES COMPLETE\n')
writeLines('complete','01_muscle_RNAseq/outputs/statistics/RNA_statistics_complete.txt')

