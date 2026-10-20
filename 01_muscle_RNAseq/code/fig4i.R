# Reanalyse the author's Fig.4i source values. This is not an independent experiment.
source('01_muscle_RNAseq/code/common.R')
input <- '01_muscle_RNAseq/evidence/fig4i_values.csv'
manifest <- read.csv('01_muscle_RNAseq/06_records/input_manifest.csv',stringsAsFactors=FALSE)
expected <- manifest[manifest$path=='evidence/fig4i_values.csv',]
stopifnot(nrow(expected)==1,unname(tools::md5sum(input))==expected$md5,
          file.info(input)$size==expected$bytes)
z <- read.csv(input,stringsAsFactors=FALSE)
z$group <- factor(z$group,levels=c('WT-Pair-fed','WT-GDF15'))
stopifnot(nrow(z)==16,all(table(z$group)==8),!anyNA(z$CAF_minus_DAN),
          max(abs(z$difference_from_fig4i))<.001)
test <- t.test(CAF_minus_DAN~group,z,var.equal=TRUE,alternative='two.sided')
out <- '01_muscle_RNAseq/outputs/fig4i'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
write.csv(data.frame(test='two-sided unpaired Student t',p=test$p.value,
                     mean_pairfed=mean(z$CAF_minus_DAN[z$group=='WT-Pair-fed']),
                     mean_GDF15=mean(z$CAF_minus_DAN[z$group=='WT-GDF15'])),
          file.path(out,'statistics.csv'),row.names=FALSE)
means <- tapply(z$CAF_minus_DAN,z$group,mean)
sem <- tapply(z$CAF_minus_DAN,z$group,function(v)sd(v)/sqrt(length(v)))
draw <- function() {
  par(mar=c(5,5,4,1));set.seed(6249)
  x <- barplot(means,ylim=c(0,7),col=c('#E76F51','#457B9D'),
               names.arg=c('Pair-fed','GDF15'),ylab='Calcium-dependent oxygen consumption',
               main=sprintf('Author source-data reanalysis: P = %.4f',test$p.value))
  arrows(x,means-sem,x,means+sem,angle=90,code=3,length=.05)
  for(i in seq_along(x)) {
    v <- z$CAF_minus_DAN[z$group==levels(z$group)[i]]
    points(rep(x[i],length(v))+runif(length(v),-.12,.12),v,pch=21,bg='white')
  }
  mtext('pmol / s / mg wet weight; mean +/- SEM; n = 8 per group',side=1,line=4,cex=.75)
}
png(file.path(out,'Fig4i.png'),width=1200,height=1100,res=180);draw();dev.off()
pdf(file.path(out,'Fig4i.pdf'),width=7,height=6);draw();dev.off()
writeLines(c('Fig.4i source values from Source Data Fig.4, sheet Fig.4i, A2:A9 and B2:B9.',
             'CAF-DAN values cross-checked against Source Data Extended Data Fig.10, sheet ED.Fig10o.',
             'Two-sided unpaired Student t test, equal variances; means with SEM.',
             'This output starts the axis at zero. The original styled chart used a truncated axis.',
             capture.output(sessionInfo())),file.path(out,'methods_session.txt'))
cat(sprintf('Fig.4i P = %.8f; original reports 0.0081.\n',test$p.value))
