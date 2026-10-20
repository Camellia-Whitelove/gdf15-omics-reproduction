# GDF15 论文图表复现代码

本仓库 Fork 自 [xyxdjz/gdf15-omics-reproduction](https://github.com/xyxdjz/gdf15-omics-reproduction)，保留上游提交历史。本副本补齐了运行输入、统一文件路径，并修正了4c核查和方法说明；不将上游代码称为本账号独立原创。

课程为《组学数据分析和可视化》。论文为 Wang 等发表于 Nature 2023 的 [GDF15 promotes weight loss by enhancing energy expenditure in muscle](https://doi.org/10.1038/s41586-023-06249-4)。

本项目用公开数据进行R语言统计和绘图。最初目标是肌肉 **Fig.4b和4c**，后来补做肝脏 **Fig.1i、1j** 和耗氧实验 **Fig.4i**。下面区分实际计算结果和与论文尚未对齐的部分。

| 图 | 数据和实际完成情况 |
|---|---|
| 1i | 肝脏计数矩阵重新建模、PCA；rlog和VST结果均保留，解释率与原图有差别。 |
| 1j | 肝脏样本距离热图；原始计数Poisson方法得到相同的18样本顺序，但未经作者确认。 |
| 4b | 肌肉FASTQ经质控、比对、基因计数后绘图；聚类未完全恢复原文。 |
| 4c | 按公开阈值的两条替代路线均未完整恢复原图10个MF功能。已提供实际MF输入和完整检验表用于核查。 |
| 4i | 重算作者耗氧表，P=0.00810363，四位小数与原文一致。这是功能实验图，不是组学图。 |

## 首次使用

下载仓库后，在含 `run.R` 的文件夹打开终端。只检查必要小文件，不会下载FASTQ：

```sh
Rscript run.R check
```

需要缺失的R包时，单独执行：

```sh
Rscript install_dependencies.R
```

R脚本可通过环境变量 `GDF15_R_LIB` 使用已有包目录。安装步骤需要联网；分析入口不会自动安装软件。历史运行环境为Windows 11、R 4.6.1、DESeq2 1.52.0、Rsubread 2.26.0、GOstats 2.78.0、org.Mm.eg.db 3.23.0；每次新运行另存实际 `sessionInfo()`。没有声称已在所有R版本和操作系统测试。

## 肝脏1i和1j

```sh
Rscript run.R liver
```

该命令下载约0.51 MB的GSE229708公开计数矩阵，核验大小和MD5，然后完成矩阵质控、DESeq2建模、VST/rlog、PCA、距离矩阵、绘图和校验。**不下载肝脏FASTQ，也不做肝脏测序读段质控或比对。**

三组各6只小鼠，共18个样本、16,245个基因。分组表已保存在 `02_liver_RNAseq/01_data/sample_metadata.csv`。输出在该模块的 `02_qc/`、`03_models/`、`04_plot_data/`、`06_records/`、`07_figures/`；输入校验清单随仓库提供，运行时生成 `06_records/file_manifest.csv`。若只想重画已生成的图，可在肝脏目录执行 `source('code/05_final_report_figures.R')`。

模型为 `~ condition`、Vehicle为参考，总计数至少5。PCA每种变换各取变异最高500基因，中心化、不按基因标准差缩放，展示PC1/PC4。作者图注写VST而PCA代码使用rlog，两版不能合并为已确认的同一方法。未获得作者Salmon/tximport长度偏移量，本项目采用直接计数模型。

## 肌肉4b

数据为GSE229794 / PRJNA955831，共16只小鼠，Vehicle 5、GDF15 6、Pair-fed 5；32个双端FASTQ压缩文件合计18.28 GB。Pair-fed原编号为S2至S6。

下载清单及其完整性可先单独检查，不会传输FASTQ：

```sh
python 01_muscle_RNAseq/code/pipeline/download_segmented.py --check-only
```

完整上游流程会下载大文件、构建参考索引，耗时和磁盘占用较多。它需要Windows、Python 3.11及以上、`curl.exe`、Cutadapt 4及R依赖。把Python放入PATH，或设置 `GDF15_PYTHON`；把Cutadapt放入PATH，或设置 `GDF15_CUTADAPT` 为可执行文件路径。然后运行：

```sh
Rscript run.R muscle-raw
```

顺序为参考下载及MD5检查 → 注释整理 → Rsubread索引 → FASTQ下载及MD5检查 → 原始质控 → Cutadapt清理 → 清理后质控 → 唯一比对与featureCounts → DESeq2 → 可视化。质控按4个工作分片顺序运行，比对按2个工作分片顺序运行；分片编号和汇总脚本对应。主流程任何阶段报错都会退出。

肌肉数据统一放在 `01_muscle_RNAseq/data/`，结果统一放在 `01_muscle_RNAseq/outputs/`。已有合格清理结果和索引时可用 `muscle-resume` 从比对继续；已有计数、分组和注释时可用 `muscle-analysis` 从统计分析继续。不能只下载GEO标准化表就跳到DESeq2计数模型。

计数采用反向链双端片段计数。差异阈值为 `|log2FC| > 0.6` 且 `BH padj < 0.1`。作者使用Trim Galore、Salmon/tximport和UCSC knownGene，本路线使用Cutadapt、featureCounts和GENCODE M25。替代流程的结果不能写成逐数值精确复现。

## 4c核查

```sh
Rscript run.R fig4c
```

该入口对 **MF分子功能** 运行GOstats，不是BP生物过程。它读取 `01_muscle_RNAseq/evidence/fig4c_kallisto_20261011/` 中真实保存的基因名单和背景，重新计算富集；**不重新运行kallisto或DESeq2**。新的结果写入 `outputs/fig4c_mf_rerun/`，历史输入和结果不覆盖。

历史featureCounts路线筛出35个差异基因。后来kallisto → tximport → DESeq2路线筛出31个，其中30个进入MF分析，主背景为9380个基因。原图10个功能均未达到BH < 0.1，其中7个零命中。仅改背景不能增加名单中的命中基因。放宽筛选只是诊断，不能作为恢复原图的证据。

目前尚不能确定差异唯一来自哪个步骤；继续准确对齐需要作者实际输入基因、GO背景、完整富集表和映射参数。旧 `audit_transform_gostats_20261011.R` 和 `audit_sensitivity_padj_only_20261011.R` 是 **历史BP诊断**，保留用于理解排查过程，不称为原图MF复现。表达表与本次VST的高相关只说明尺度接近，不能确认作者用了VST，更不能反推出原始计数。

## 耗氧图4i

```sh
Rscript run.R fig4i
```

使用 `evidence/fig4i_values.csv` 中从作者Source Data提取并保留单元格位置的16个值，在R中重算双侧非配对Student t检验、均值和SEM。此入口的纵轴从0开始；旧论文样式重绘使用从3开始的截断轴。数据来源及交叉核对见[数据说明](docs/data_sources.md)。这不等于独立重复动物实验。

## 其他文件与提交材料

- [数据来源与获取方式](docs/data_sources.md)
- [完成状态和已知限制](docs/analysis_status.md)
- `code/audit_restyle/` 内的PDF取色和像素脚本为辅助探索，需自行把论文PDF放在肌肉 `data/paper.pdf`；不参与主要数值验证。
- 原始FASTQ、BAM、参考索引、软件包及模型大文件不随仓库提交。小型分组、下载清单和4c核查输入已经保留。
- 本仓库是代码材料。课程还要求单独提交PPT、含关键图表的复现报告、数据来源说明；这些材料不因已有仓库而自动完成。

## 引用与AI辅助

Wang D 等. *GDF15 promotes weight loss by enhancing energy expenditure in muscle*. Nature 619, 143–150 (2023). [DOI](https://doi.org/10.1038/s41586-023-06249-4)。作者公开代码：[Zenodo 10.5281/zenodo.7838970](https://doi.org/10.5281/zenodo.7838970)。

项目使用大语言模型辅助下载排障、代码编写、样式调试和记录整理。统计值由实际脚本计算；报告应披露AI使用范围，保留未完成部分和方法差异，不能把作者实验称为本组独立完成。
