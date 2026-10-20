# GDF15 组学论文核心图复现 — 代码仓库

课程：《组学数据分析和可视化》学生报告（生命科学与技术学院，2026 秋）

对 *Nature* 2023 论文 **“GDF15 promotes weight loss by enhancing energy expenditure in muscle”** 的核心图进行方法替代复现。

**本仓库仅包含复现过程中编写的代码。** 原始数据、中间结果、图件与处理记录不在库内（体积与许可原因），获取方式见文末「数据来源」。

| 项目 | 内容 |
|---|---|
| 论文 | GDF15 promotes weight loss by enhancing energy expenditure in muscle |
| 期刊 / 年份 | *Nature*，2023 |
| DOI | 10.1038/s41586-023-06249-4 |
| 作者公开代码 | Zenodo 10.5281/zenodo.7838970 |

---

## 目录结构

```
.
├── 01_muscle_RNAseq/code/        胫骨前肌 RNA-seq（从 FASTQ 开始的全流程）
│   ├── pipeline/                 下载 → 质控 → 比对 → 计数 → 统计建模 → 绘图
│   └── audit_restyle/            核查（变换鉴定 / GOstats 复跑）与论文样式重绘
└── 02_liver_RNAseq/code/         肝脏 RNA-seq（从作者计数矩阵开始）
```

---

## 1. 肌肉：胫骨前肌 RNA-seq

数据：GSE229794 / PRJNA955831，16 样本（Vehicle 5、GDF15 6、Pair-fed 5），32 个双端 FASTQ，每端 51 bp。

### `pipeline/` 执行顺序

| 顺序 | 脚本 | 作用 |
|---|---|---|
| 1 | `fetch_reference.py` | 下载 mm10/GRCm38 基因组与 GENCODE M25 注释 |
| 2 | `prepare_annotation.py` | 整理注释为比对/计数可用格式 |
| 3 | `prepare_environment.R` | 准备 R 依赖 |
| 4 | `build_index.R` | 构建 Rsubread 索引 |
| 5 | `download_segmented.py` / `download_raw.ps1` | 从 ENA 分段下载 32 个 FASTQ（18.28 GB，支持续传） |
| 6 | `verify_downloads.py` | 文件大小与 MD5 校验（实际结果 32/32 通过） |
| 7 | `qc_raw.R` | 原始质控：读段数量、配对 ID 一致性、Q30（ShortRead） |
| 8 | `trim_samples.py` | Cutadapt 4 清理：双端接头、q20、最短 20 bp |
| 9 | `qc_clean.R`、`merge_clean_qc.R` | 清理后质控与汇总 |
| 10 | `align_count.R`、`align_count_unique.R`、`align_count_worker.R` | Rsubread 比对（unique=TRUE）+ featureCounts 计数，反向链 s=2 |
| 11 | `summarize_alignment.R`、`inspect_bam.R` | 比对率汇总与 BAM 抽查 |
| 12 | `collect_counts.R` | 合并为基因计数矩阵 |
| 13 | `export_gene_mapping.R` | 导出 ENSEMBL / Entrez / Symbol 映射 |
| 14 | `analyze.R` | DESeq2 建模（~condition）、三组差异分析、GO 富集、PCA、Poisson 距离 |
| 15 | `redraw_figures.R` | 图件绘制（Fig.4b 等） |
| 16 | `physiology.R`、`extract_physiology.py` | 生理指标复现（论文 Source Data）：Fig.2d、Fig.4i |
| — | `run_remaining.ps1` | 批处理串联剩余步骤 |

关键参数：DESeq2 过滤为总计数 ≥ 5；DEG 阈值 |log2FC| > 0.6 且 BH padj < 0.1。

### `audit_restyle/` 核查与重绘

| 脚本 | 作用 |
|---|---|
| `install_audit_deps.R` | 安装审计依赖（DESeq2、GOstats、org.Mm.eg.db、GO.db） |
| `audit_handoff_20261011.R` | 鉴定作者公开表达表的变换方式、样本/基因对应、LFC 秩一致性 |
| `audit_transform_gostats_20261011.R` | rlog/VST 直接比对 + 用 GOstats 复跑 Fig.4c 富集 |
| `audit_sensitivity_padj_only_20261011.R` | 敏感性分析：仅按 padj 阈值（不限 log2FC）的 GO 富集 |
| `check_pka_author_scale.R` | 论文点名 PKA 靶基因在作者表达表中的组间差异 |
| `restyle_fig4b_fig4i_paper_style.R` | Fig.4b / Fig.4i 论文样式重绘（含 base R `barplot()` 在截断轴下不裁剪的修复，改用 `rect()` 手绘柱体） |
| `verify_panel_i_pixels.py`、`verify_restyled_figures.py` | 像素位置与数值反向验证 |
| `extract_page6.py`、`analyze_page6_style*.py` | 论文第 6 页取色与版式分析（探索性迭代版本） |
| `setup_next_stage.R`、`verify_completed_analysis.R` | 阶段初始化与结果完整性检查 |
| `analyze.R`、`redraw_figures.R`、`physiology.R`、`export_gene_mapping.R`、`extract_physiology.py` | 工作目录中的对应副本 |

---

## 2. 肝脏：从作者计数矩阵开始

数据：GSE229708，作者公开计数矩阵 `Counts4allSamples.csv.gz`，16,245 基因 × 18 样本（Vehicle / GDF15 / PairFed 各 6）。**本部分不下载 FASTQ、不做比对。**

```r
setwd("02_liver_RNAseq")
source("code/00_install_dependencies.R")      # DESeq2、pheatmap、PoiClaClu 等
source("code/01_qc_model.R")                  # 矩阵质控 + DESeq2 建模 + PCA + 距离矩阵
source("code/02_plot.R")                      # 候选图（Fig.1i rlog/VST、Fig.1j 三种距离）
source("code/03_verify_package.R")            # 文件与校验和核验（无需额外包）
source("code/04_validate_models.R")           # 模型校验
source("code/05_final_report_figures.R")      # 生成报告用最终图
source("code/06_verify_final_figures.R")      # 校验解释率标签与热图叶序
```

> 脚本按肝脏交接包结构编写：`01_qc_model.R` 需在包根目录运行（读 `01_data/`、写 `03_models/` 与 `04_plot_data/`）；`05_final_report_figures.R` 只依赖 `04_plot_data/`，无需重新拟合模型。

模型设定：DESeq2 `design = ~ condition`，Vehicle 为参照；未获得作者 Salmon/tximport 的长度偏移量，故为直接计数模型。PCA 为每种变换独立取变异最高 500 基因、`prcomp` 中心化不缩放、展示 PC1/PC4。

---

## 3. 环境

- Windows 11、R 4.6.1
- R 包：DESeq2 1.52.0、Rsubread 2.26.0、GOstats 2.78.0、org.Mm.eg.db 3.23.0、GO.db、PoiClaClu 1.0.2.1、pheatmap、ggplot2、ShortRead、AnnotationDbi
- 外部工具：Cutadapt 4（Windows 原生版）
- Python 3（辅助）：PyMuPDF、Pillow（PDF 取色与像素校验）

---

## 4. 关键结论（使用代码时需注意）

1. **Fig.4c 不可复现**：按论文阈值（|log2FC|>0.6、padj<0.1）用 GOstats 复跑，表达背景下 BH<0.1 条目为 0；只有放宽为「仅 padj<0.1 + GOstats 默认全库背景」时 cAMP/PKA 条目才显著，而该设定下全库背景共有 1,354 个 BP 条目 BH<0.1，属明显背景膨胀。代码中保留了这一敏感性分析（`audit_sensitivity_padj_only_20261011.R`），**未通过删样本或放宽主分析阈值来凑出原图结果**。
2. **作者公开表达表是 DESeq2 VST 值**，不是计数也不是 log2 计数（与本次 VST 比对 r=0.976、斜率≈0.998）。
3. **Fig.4i 采用论文同款截断轴**（基线 3），会放大组间差异的视觉效果；`restyle_fig4b_fig4i_paper_style.R` 中保留完整轴绘制选项。
4. **Fig.1i 图注写 VST、作者 PCA 代码用 rlog**，两版都提供；Fig.1j 的 raw-count Poisson 距离为诊断性替代，未经作者确认。
5. 本次为**方法替代复现**（Cutadapt vs Trim Galore、featureCounts vs Salmon+tximport、GENCODE M25 vs UCSC knownGene），不能声称逐数值精确复现。

---

## 5. 数据来源（不在库内，需自行获取）

| 数据 | 来源 | 获取方式 |
|---|---|---|
| 肌肉原始 FASTQ | ENA PRJNA955831 | `pipeline/download_segmented.py`（18.28 GB，自动下载并校验） |
| 肌肉作者表达矩阵 | GEO GSE229794 补充文件 | 下载 `GSE229794_CountsNormalizedByDESeq2.csv.gz` 放入工作目录 |
| 肝脏计数矩阵 | GEO GSE229708 补充文件 | 下载 `Counts4allSamples.csv.gz` 放入 `01_data/` |
| 生理指标 | 论文 Source Data（MOESM4/6/11/15） | 由 `extract_physiology.py` 读取 |
| 参考基因组与注释 | mm10 / GENCODE M25 | `pipeline/fetch_reference.py` |

---

## 6. 学术诚信

- 复现内容（代码与图）与原创观点（差异分析、改进建议）严格区分；
- 所有图表与数据均注明原始文献 DOI 与数据来源；
- 复现过程中使用大语言模型辅助（下载排障、脚本编写、图件样式调试、记录整理），**统计结果均由脚本实际计算得出，未擅改**；报告与汇报中需披露该使用范围；
- 未抄袭、未买卖代码或报告；组间可讨论思路，但不直接共用代码或最终结果。

## 7. 引用

> Wang, D. et al. GDF15 promotes weight loss by enhancing energy expenditure in muscle. *Nature* **619**, 143–150 (2023). DOI: 10.1038/s41586-023-06249-4

作者公开代码：Zenodo 10.5281/zenodo.7838970
