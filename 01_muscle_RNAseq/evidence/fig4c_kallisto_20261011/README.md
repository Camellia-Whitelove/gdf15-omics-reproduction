# Fig.4c ��������֤��

��ЩCSV����2026��10��11��ʵ�����е� kallisto �� tximport �� DESeq2 �� GOstats MF ���������������ṩ�Ļ���������

- `paper_threshold_DEGs.csv`��GDF15 �� Pair-fed���� |log2FC| > 0.6��BH padj < 0.1 ɸ����31����������30������MF���顣
- `padj_eligible_background.csv`��9380������MFע�͵���ЧУ��Pֵ��������
- `original_figure_terms.csv`��ԭͼ10�����ܵ�GO��ţ����Ǻ˲�Ŀ�꣬����������Ŀ��ɸѡ�����
- `GOstats_run_summary.csv` �� `original_terms_comparison.csv`�����ֱ��ﱳ����������������������ʷ�����ԭͼ10�����ܾ�δ�ﵽBH < 0.1������7�������С�
- `padj_eligible_unconditional_all_terms.csv`���������������������������������Ŀ��
- `quantification_summary_R.csv`��16�������Ķ����˲���ܡ�ԭʼ abundance �ļ��Ͳο�����δ����ЩС�ļ��ϴ���
- `file_manifest.csv`�������ļ��Ĵ�С��MD5�����ڼ�鴫���༭�Ƿ�ı�����ʷ֤�ݡ�

�Ӳֿ��Ŀ¼���� `Rscript run.R fig4c` �������¼������׹̶������ **MF����**������������¶���FASTQ��Ҳ�����������DESeq2���µ����н�������� `01_muscle_RNAseq/outputs/fig4c_mf_rerun/`��ע�����ݿ�汾��ͬ��������ܸı䣬ʵ�ʰ汾�����½�����档

ԭ����ʹ��Salmon������ʹ��kallisto 0.46.1��UCSC knownGene TxDb 3.10.0�����ο���tximport����У��������������̡���ǰfeatureCounts·��ɸ��35�������������·�߾�δ�����ָ�ԭͼ�����ܰ�BP�����Է�����ſ���ֵ����źų�ΪԭͼMF���֡�
