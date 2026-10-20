dir.create('outputs/figures',showWarnings=FALSE)
dir.create('outputs/statistics',showWarnings=FALSE)
ee<-read.csv('outputs/physiology/fig2d_energy_expenditure.csv',stringsAsFactors=FALSE)
ee$group<-factor(ee$group,levels=c('Vehicle','GDF15','Pair-fed'))
cols<-c(Vehicle='#4682B4',GDF15='#E69F00','Pair-fed'='#009E73')
png('outputs/figures/Fig2d_energy_expenditure.png',width=1800,height=1100,res=180)
par(mfrow=c(1,2),mar=c(7,5,3,1));set.seed(6249)
tests<-list()
for(phase in c('light','dark')){
 z<-ee[ee$phase==phase,];group<-interaction(z$group,z$temperature,drop=TRUE,lex.order=FALSE)
 m<-tapply(z$EE_kcal_h,group,mean);se<-tapply(z$EE_kcal_h,group,function(v)sd(v)/sqrt(length(v)))
 colors<-rep(cols,2);x<-barplot(m,ylim=c(0,.6),col=colors,border=NA,ylab='Energy expenditure (kcal / h)',main=paste('Fig. 2d:',phase,'cycle'),las=2,names.arg=c('Vehicle RT','GDF15 RT','Pairfed RT','Vehicle TN','GDF15 TN','Pairfed TN'))
 arrows(x,m-se,x,m+se,angle=90,code=3,length=.04)
 for(j in seq_along(m))points(rep(x[j],sum(group==names(m)[j]))+runif(sum(group==names(m)[j]),-.13,.13),z$EE_kcal_h[group==names(m)[j]],pch=16,cex=.6)
 for(temp in c('RT','TN')){
  a<-z[z$temperature==temp,];fit<-lm(EE_kcal_h~group,a); mse<-sum(resid(fit)^2)/df.residual(fit)
  pairs<-combn(levels(a$group),2,simplify=FALSE)
  for(pair in pairs){u<-a$EE_kcal_h[a$group==pair[1]];v<-a$EE_kcal_h[a$group==pair[2]];t<-(mean(u)-mean(v))/sqrt(mse*(1/length(u)+1/length(v)));p<-2*pt(-abs(t),df.residual(fit));tests[[length(tests)+1]]<-data.frame(phase=phase,temperature=temp,group1=pair[1],group2=pair[2],difference=mean(u)-mean(v),df=df.residual(fit),p=p,p_sidak=1-(1-p)^3)}
 }
};dev.off()
write.csv(do.call(rbind,tests),'outputs/statistics/Fig2d_ANOVA_Sidak_contrasts.csv',row.names=FALSE)
ca<-read.csv('outputs/physiology/fig4i_calcium_respiration.csv',stringsAsFactors=FALSE)
ca$group<-factor(ca$group,levels=c('WT-Pair-fed','WT-GDF15'))
test<-t.test(CAF_minus_DAN~group,ca,var.equal=TRUE,alternative='two.sided')
write.csv(data.frame(test='two-sided unpaired Student t',t=unname(test$statistic),df=unname(test$parameter),p=test$p.value,mean_pairfed=mean(ca$CAF_minus_DAN[ca$group=='WT-Pair-fed']),mean_GDF15=mean(ca$CAF_minus_DAN[ca$group=='WT-GDF15'])),'outputs/statistics/Fig4i_t_test.csv',row.names=FALSE)
png('outputs/figures/Fig4i_calcium_respiration.png',width=1200,height=1100,res=180)
par(mar=c(5,6,4,1));m<-tapply(ca$CAF_minus_DAN,ca$group,mean);se<-tapply(ca$CAF_minus_DAN,ca$group,function(v)sd(v)/sqrt(length(v)))
x<-barplot(m,col=c(cols['Pair-fed'],cols['GDF15']),border=NA,ylim=c(0,7),names.arg=c('Pair-fed','GDF15'),ylab=expression(Ca^'2+'*'-dependent '*J[O[2]]*' (pmol '*s^-1*' '*mg^-1*' wet weight)'),main=sprintf('Fig. 4i: P = %.4f',test$p.value));arrows(x,m-se,x,m+se,angle=90,code=3,length=.05);for(i in 1:2){v<-ca$CAF_minus_DAN[ca$group==levels(ca$group)[i]];points(rep(x[i],length(v))+runif(length(v),-.13,.13),v,pch=21,bg='white',cex=1)};dev.off()
anc<-read.csv('outputs/physiology/fig2k_body_mass_and_EE.csv',stringsAsFactors=FALSE)
anc$condition<-ifelse(grepl('GDF15',anc$group),'GDF15',ifelse(grepl('pair-fed|PF',anc$group),'Pairfed','Vehicle'))
anc$genotype<-ifelse(grepl('KO',anc$group),'KO','WT')
anc$condition<-factor(anc$condition,levels=c('Pairfed','GDF15','Vehicle'))
fits<-list();anc_tests<-list()
for(g in c('WT','KO')){
 z<-droplevels(anc[anc$genotype==g,]); fit<-lm(dark_EE_kcal_h~body_mass_g+condition,z);fits[[g]]<-fit
 slopes<-lm(dark_EE_kcal_h~body_mass_g*condition,z)
 interaction_p<-anova(fit,slopes)$`Pr(>F)`[2]
 if(interaction_p<.05)fits[[g]]<-slopes
 co<-coef(summary(fit));comparison<-co['conditionGDF15',]
 anc_tests[[g]]<-data.frame(genotype=g,n=nrow(z),GDF15_minus_Pairfed_at_equal_mass=comparison[1],SE=comparison[2],t=comparison[3],df=df.residual(fit),p=comparison[4],slope_interaction_p=anova(fit,slopes)$`Pr(>F)`[2])
 writeLines(capture.output(summary(fit)),paste0('outputs/statistics/Fig2k_ANCOVA_',g,'.txt'))
}
write.csv(do.call(rbind,anc_tests),'outputs/statistics/Fig2k_ANCOVA_contrasts.csv',row.names=FALSE)
png('outputs/figures/Fig2k_ANCOVA.png',width=1800,height=1000,res=180);par(mfrow=c(1,2),mar=c(5,5,4,1))
for(g in c('WT','KO')){
 z<-droplevels(anc[anc$genotype==g,]);colors<-c(Vehicle=cols['Vehicle'],GDF15=cols['GDF15'],Pairfed=cols['Pair-fed']);names(colors)<-c('Vehicle','GDF15','Pairfed')
 plot(z$body_mass_g,z$dark_EE_kcal_h,col=colors[as.character(z$condition)],pch=19,xlab='Body mass (g)',ylab='Dark-cycle EE (kcal / h)',ylim=range(z$dark_EE_kcal_h)*c(.97,1.03),main=paste('Exploratory order-matched data:',g))
 mtext(if(anc_tests[[g]]$slope_interaction_p<.05)'Slopes differ; interaction model shown' else 'Common-slope model shown',side=3,line=.3,cex=.7)
 for(condition in levels(z$condition)){r<-range(z$body_mass_g[z$condition==condition]);grid<-data.frame(body_mass_g=seq(r[1],r[2],length.out=100),condition=factor(condition,levels=levels(z$condition)));lines(grid$body_mass_g,predict(fits[[g]],grid),col=colors[condition],lwd=2)}
 legend('topleft',legend=levels(z$condition),col=colors[levels(z$condition)],pch=19,bty='n')
};dev.off()
writeLines(c('Fig2d: source MOESM4 Fig.2d,e; means +/- SEM; 10/6 animals per group at RT/TN. Separate one-way ANOVAs within temperature and phase; pooled-residual pairwise t contrasts and Sidak for three pairwise comparisons within each fit. Author multiplicity family details not supplied.','Fig4i: source MOESM6 Fig.4i; 8 animals/group; two-sided unpaired Student t test; source values reconciled with CAF-DAN in MOESM15 ED.Fig10o within 0.001.','Fig2k: exploratory only. MOESM4 Fig.2j,k dark EE (row8) joined with MOESM11 ED.Fig6a mass by group label and within-group order. Individual mouse IDs are absent; matched source order is an unverified assumption.','Fig2k: common-slope estimates are retained solely as diagnostic output. KO interaction test rejects parallel slopes; KO plot uses interaction model and common-slope P must not be interpreted. No exact Fig2k reproduction is claimed.','Fig2e was not reproduced because matching individual body masses for the temperature experiment are absent from the located source data.',capture.output(sessionInfo())),'outputs/statistics/physiology_methods.txt')
cat('PHYSIOLOGY FIGURES COMPLETE\n');print(test);print(do.call(rbind,anc_tests))
