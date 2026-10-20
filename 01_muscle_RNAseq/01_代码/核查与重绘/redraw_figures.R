.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
suppressPackageStartupMessages({library(DESeq2);library(pheatmap)})
dds<-readRDS('outputs/statistics/deseq2_model.rds')
meta<-read.csv('outputs/sample_metadata.csv');meta<-meta[match(colnames(dds),meta$sample_alias),]
labs<-paste0(meta$condition,'_',meta$original_sample_number)
cols<-c(Vehicle='#4682B4',GDF15='#E69F00',Pairfed='#009E73')
distance<-as.matrix(read.csv('outputs/statistics/poisson_sample_distances.csv',row.names=1,check.names=FALSE))
ann<-data.frame(Group=meta$condition);rownames(ann)<-labs
for(extension in c('png','pdf'))pheatmap(distance,clustering_distance_rows=as.dist(distance),clustering_distance_cols=as.dist(distance),annotation_row=ann,annotation_col=ann,annotation_colors=list(Group=cols),color=colorRampPalette(c('white','#B6C7D6','#184566'))(100),main='Poisson sample distances',fontsize=9,border_color=NA,filename=paste0('outputs/figures/Fig4b_sample_distance.',extension),width=12,height=10)
v<-vst(dds,blind=FALSE);pc<-prcomp(t(assay(v)));explained<-100*pc$sdev^2/sum(pc$sdev^2)
draw_pca<-function(){
 par(mar=c(5,5,3,1));rx<-range(pc$x[,1]);ry<-range(pc$x[,2])
 plot(pc$x[,1],pc$x[,2],pch=19,col=cols[meta$condition],cex=1.3,xlim=rx+c(-1,1)*diff(rx)*.12,ylim=ry+c(-1,1)*diff(ry)*.12,xlab=sprintf('PC1 (%.1f%%)',explained[1]),ylab=sprintf('PC2 (%.1f%%)',explained[2]),main='Muscle RNA-seq: VST PCA')
 text(pc$x[,1],pc$x[,2],labels=labs,pos=3,cex=.65)
 legend('bottomleft',legend=names(cols),col=cols,pch=19,bty='n',cex=.8)
}
png('outputs/figures/RNAseq_PCA.png',width=1600,height=1200,res=180);draw_pca();dev.off()
pdf('outputs/figures/RNAseq_PCA.pdf',width=9,height=7);draw_pca();dev.off()
write.csv(data.frame(sample=meta$sample_alias,label=labs,condition=meta$condition,PC1=pc$x[,1],PC2=pc$x[,2]),'outputs/statistics/PCA_coordinates.csv',row.names=FALSE)
cat('FIGURES REDRAWN WITH COMPLETE LEGENDS AND LABELS\n')
