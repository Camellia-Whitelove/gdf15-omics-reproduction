.libPaths(c(normalizePath('work/gdf15/R-library'),.libPaths()))
suppressPackageStartupMessages(library(Rsamtools))
bam<-BamFile('work/gdf15/data/bam/SRR24179000.bam',yieldSize=500000)
open(bam);total<-0;nh<-integer();mq<-integer();flags<-integer()
accumulate<-function(a,x){x<-as.character(x);x[is.na(x)]<-'<missing>';t<-table(x);keys<-union(names(a),names(t));out<-setNames(rep(0,length(keys)),keys);out[names(a)]<-a;out[names(t)]<-out[names(t)]+as.numeric(t);out}
repeat{
 z<-scanBam(bam,param=ScanBamParam(what=c('qname','flag','mapq'),tag=c('NH','HI')))[[1]]
 if(!length(z$qname))break
 total<-total+length(z$qname)
 nh<-accumulate(nh,if(is.null(z$tag$NH))rep(NA_integer_,length(z$qname)) else z$tag$NH)
 mq<-accumulate(mq,z$mapq);flags<-accumulate(flags,z$flag)
 if(total %% 5000000==0){cat(total,'records checked\n');flush.console()}
}
close(bam)
for(pair in list(list('NH',nh),list('MAPQ',mq),list('FLAGS',flags)))write.csv(data.frame(value=names(pair[[2]]),records=as.numeric(pair[[2]])),paste0('outputs/alignment/first_BAM_',pair[[1]],'.csv'),row.names=FALSE)
cat('ALL RECORDS',total,'\nNH:\n');print(nh);cat('MAPQ:\n');print(mq)
