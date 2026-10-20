extra <- Sys.getenv('GDF15_R_LIB'); if(nzchar(extra)) .libPaths(c(extra,.libPaths()))
if (dir.exists('02_liver_RNAseq/code')) setwd('02_liver_RNAseq')
# Can render from the provided CSV files without loading the DESeq2 models.
extra <- Sys.getenv('GDF15_R_LIB');if(nzchar(extra)).libPaths(c(extra,.libPaths()))
suppressPackageStartupMessages({library(ggplot2);library(pheatmap)})
dir.create('07_figures',showWarnings=FALSE)
cols<-c(GDF15='#F8766D',PairFed='#00BA38',Vehicle='#619CFF')
for(nm in c('rlog','VST')) {
 z<-read.csv(paste0('04_plot_data/PCA_',nm,'_coordinates.csv'))
 pct<-read.csv(paste0('04_plot_data/PCA_',nm,'_variance.csv'))$variance_percent
 p<-ggplot(z,aes(PC1,PC4,color=condition))+geom_point(size=3)+stat_ellipse(type='t',level=.95,linewidth=.6)+scale_color_manual(values=cols)+labs(title=paste('Fig.1i reproduction candidate:',nm),subtitle='Author-deposited liver counts; top 500 variable genes',x=sprintf('PC1: %.2f%% variance',pct[1]),y=sprintf('PC4: %.2f%% variance',pct[4]),color='Group')+theme_classic(base_size=12)
 ggsave(paste0('07_figures/Fig1i_',nm,'.png'),p,width=7.5,height=5.5,dpi=220)
}
for(nm in c('VST_Euclidean','rlog_Euclidean','raw_Poisson')) {
 m<-as.matrix(read.csv(paste0('04_plot_data/distance_',nm,'.csv'),row.names=1,check.names=FALSE));d<-as.dist(m)
 label<-if(nm=='raw_Poisson')'Diagnostic alternative: raw Poisson; differs from VST caption' else nm
 png(paste0('07_figures/Fig1j_',nm,'.png'),width=1800,height=1500,res=180)
 pheatmap(m,clustering_distance_rows=d,clustering_distance_cols=d,border_color=NA,fontsize=9,main=paste('Fig.1j reproduction candidate\n',label));dev.off()
}

