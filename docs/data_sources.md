# 数据来源与可使用性

## 肝脏1i与1j

- 数据集：[GSE229708](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE229708)。小鼠肝脏bulk RNA-seq，18个独立样本，三组各6个。
- 输入：[GSE229708_Counts4allSamples.csv.gz](https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229708/suppl/GSE229708_Counts4allSamples.csv.gz)，507,141字节，16,245基因×18样本。
- 分组表随仓库提供，包含样本列名、条件和GEO编号。代码自动下载计数矩阵并验证固定大小和MD5。
- 可用于矩阵和样本质控、DESeq2、PCA及样本距离分析。没有作者转录本长度偏移量，不视为完整重现作者上游；本项目没有处理肝脏FASTQ。

## 肌肉4b与4c

- 数据集：[GSE229794](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE229794)；原始测序：[ENA PRJNA955831](https://www.ebi.ac.uk/ena/browser/view/PRJNA955831)。小鼠胫骨前肌bulk RNA-seq，共16个样本，三组为5、6、5。
- 下载清单 `01_muscle_RNAseq/data/ena_runs.tsv` 保留run编号、样本编号、两端URL、大小和ENA MD5；32个FASTQ.gz合计18,280,996,374字节。
- [公开表达表](https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229794/suppl/GSE229794_CountsNormalizedByDESeq2.csv.gz)约1.84 MB。它不是可直接重新拟合DESeq2的原始整数计数；仅凭其与VST高相关不能认定确切变换方式。
- 主流程参考为[UCSC mm10 FASTA](https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz)和[GENCODE M25](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M25/gencode.vM25.annotation.gtf.gz)，下载脚本保留官方文件MD5。
- 4b可从生成的计数或距离矩阵继续绘图。4c尚未恢复原图；提供的kallisto MF小型证据可重算富集，不含重新定量所需的全部abundance文件与参考。需重新定量时，不能把这些小文件当作完整上游数据。

## 耗氧4i

- 来源：[论文Source Data](https://www.nature.com/articles/s41586-023-06249-4)。原文件为 `41586_2023_6249_MOESM6_ESM.xlsx`，工作表 `Fig.4i`，A2:A9为Pair-fed、B2:B9为GDF15。
- 交叉核对：`41586_2023_6249_MOESM15_ESM.xlsx`，工作表 `ED.Fig10o`。按CAF-DAN计算的值与Fig.4i值之差均小于0.001，存在原表舍入差别。
- 仓库的 `01_muscle_RNAseq/evidence/fig4i_values.csv` 保存源单元格、原Fig.4i值和交叉核对值。统计使用原Fig.4i值，没有用重新相减的舍入值替换。
- 每组8只独立小鼠，可复核统计和图形；这是生理实验数据，不属于组学，也不代表独立重复动物实验。

## 引用与可访问性

论文：[10.1038/s41586-023-06249-4](https://doi.org/10.1038/s41586-023-06249-4)；作者代码：[10.5281/zenodo.7838970](https://doi.org/10.5281/zenodo.7838970)。公开代码PDF未提供完整肌肉差异分析及GO输入，不能把它称为可直接重跑全部面板的完整工程。

上述数据已在原分析中下载并读取。网络验证页、重定向或下载中断不代表数据没有公开；请保存实际错误和校验结果，不能将HTML验证页当作CSV、PDF或Excel。作者原文及公开代码的署名和材料使用条件应保留；本仓库中的再分析结果应注明方法差异。

所有新增CSV统一为UTF-8和LF换行，数值未改写。随附清单校验仓库内文件；它不替代ENA对测序原始文件的MD5校验。
