# Fig.4c 的已运行证据

这些CSV来自2026年10月11日实际运行的 kallisto → tximport → DESeq2 → GOstats MF 分析，不是作者提供的基因名单。

- `paper_threshold_DEGs.csv`：GDF15 对 Pair-fed，按 |log2FC| > 0.6、BH padj < 0.1 筛出的31个基因。其中30个进入MF检验。
- `padj_eligible_background.csv`：9380个具有MF注释的有效校正P值背景基因。
- `original_figure_terms.csv`：原图10个功能的GO编号；它是核查目标，不是显著条目的筛选结果。
- `GOstats_run_summary.csv` 和 `original_terms_comparison.csv`：两种表达背景、条件与非条件检验的历史结果。原图10个功能均未达到BH < 0.1，其中7个零命中。
- `padj_eligible_unconditional_all_terms.csv`：主分析的完整检验表，保留不显著条目。
- `quantification_summary_R.csv`：16个样本的定量核查汇总。原始 abundance 文件和参考序列未随这些小文件上传。
- `file_manifest.csv`：上述文件的大小和MD5，用于检查传输或编辑是否改变了历史证据。

从仓库根目录运行 `Rscript run.R fig4c` 可以重新计算这套固定输入的 **MF富集**。该命令不会重新定量FASTQ，也不会重新拟合DESeq2；新的运行结果另存于 `01_muscle_RNAseq/outputs/fig4c_mf_rerun/`。注释数据库版本不同，结果可能改变，实际版本会随新结果保存。

原作者使用Salmon；本轮使用kallisto 0.46.1、UCSC knownGene TxDb 3.10.0派生参考和tximport长度校正，属于替代流程。此前featureCounts路线筛出35个差异基因，两条路线均未完整恢复原图。不能把BP敏感性分析或放宽阈值后的信号称为原图MF复现。
