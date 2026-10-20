# GDF15 组学论文核心图复现

课程：《组学数据分析和可视化》学生报告（生命科学与技术学院，2026 秋）

对 *Nature* 2023 论文 **“GDF15 promotes weight loss by enhancing energy expenditure in muscle”** 的核心图进行**方法替代复现**，覆盖两个数据集：

- **胫骨前肌（TA）bulk RNA-seq**：从 ENA 原始 FASTQ 出发，完整走通「下载 → 质控 → 比对 → 计数 → DESeq2 统计建模 → 可视化」，复现 Fig.4b / Fig.4c / Fig.4i。
- **肝脏 bulk RNA-seq**：从作者公开的基因计数矩阵出发，做矩阵质控、DESeq2 建模、PCA 与样本距离，制作 Fig.1i / Fig.1j 报告用图。

---

## 1. 论文基本信息

| 项目 | 内容 |
|---|---|
| 标题 | GDF15 promotes weight loss by enhancing energy expenditure in muscle |
| 期刊 / 年份 | *Nature*，2023 |
| DOI | 10.1038/s41586-023-06249-4 |
| 作者公开代码 | Zenodo 10.5281/zenodo.7838970 |
| 数据集 | GSE229794 / PRJNA955831（肌肉 16 样本）、GSE229708（肝脏 18 样本） |

---

## 2. 复现完成状态

| 图件 | 组织 | 状态 | 关键说明 |
|---|---|---|---|
| **Fig.1i**（PCA，PC1/PC4） | 肝脏 | 已复现 | 同时提供 rlog（作者代码所用）与 VST（图注声明）两版；轴标签用真实解释率，未改成论文数值 |
| **Fig.1j**（样本距离热图） | 肝脏 | 已复现 | raw-count Poisson 距离，18/18 叶序与原图一致 |
| **Fig.4b**（样本距离热图） | 肌肉 | 已复现 | Poisson 距离 + complete linkage；存在组间混合，未删样本 |
| **Fig.4c**（GO 富集） | 肌肉 | **不可复现** | 按论文方法无法复现 cAMP/PKA 信号，机制已定位（见第 5 节） |
| **Fig.4i**（钙依赖呼吸） | 肌肉 | 已复现 | 双侧 Student 检验 P = 0.0081，与论文一致 |
| Fig.2d（能量消耗） | 肌肉 | 既有产出 | 用论文 Source Data 复现的生理指标，非 RNA-seq 流程 |
| Fig.2e / Fig.2k | 肌肉 | 未复现 / 探索性 | 缺配对体重数据；配对关系未证实 |

> 课程要求「不少于 2 张核心图」：已复现 Fig.1i、Fig.1j、Fig.4b、Fig.4i 共 4 张。

---

## 3. 目录结构

```
gdf15-omics-reproduction/
├── README.md                     本文件
├── docs/                         报告与说明文档
│   ├── GDF15_核心图复现报告_20261015.docx   课程复现报告（Word）
│   ├── 数据集来源与可访问性说明.md
│   └── AI辅助与学术诚信说明.md
├── scripts/make_report.py        生成上述 Word 报告的脚本（python-docx）
├── 01_muscle_RNAseq/             肌肉：全流程复现
│   ├── 00_说明/                  交接说明
│   ├── 01_代码/上游流程/         下载、质控、比对、计数、差异分析脚本
│   ├── 01_代码/核查与重绘/       变换鉴定、GOstats 复跑、论文样式重绘
│   ├── 02_处理记录/              处理记录、核查记录、样本汇总
│   ├── 03_流程追溯/              方法差异记录、历史快照
│   ├── 04_结果/统计/             DEG 表、GO 结果、距离矩阵、PCA 坐标等
│   ├── 04_结果/核查/             表达表变换鉴定、样本对应、GO 复跑证据
│   ├── 05_图件/                  final（当前图）、paper_style（论文样式）
│   └── 06_数据说明/              样本表、下载校验、ENA run 列表
└── 02_liver_RNAseq/              肝脏：从作者计数矩阵复现
    ├── 01_data/                  作者计数矩阵与样本表
    ├── 02_qc/                    矩阵与样本质控结果
    ├── 04_plot_data/             可直接绘图的 PCA 坐标、距离矩阵
    ├── 05_code/                  安装、质控建模、绘图、校验脚本
    ├── 06_records/               处理记录、报告注意事项、版本
    ├── 07_figures/final/         Fig.1i / Fig.1j 报告用最终图（PNG+PDF）
    └── 08_sources/               作者公开分析代码与原图参考
```

**未入库（体积或许可原因）**：R 包库 `R-library/`（约 500 MB）、论文 PDF 全文、原始/清理后 FASTQ、BAM、参考基因组索引（18 GB+）、`deseq2_model.rds`、`DESeq2_normalized_counts.csv`。这些均可由仓库内脚本重新生成或从公共数据库下载，获取方式见 `docs/数据集来源与可访问性说明.md`。

---

## 4. 环境与复现步骤

### 4.1 环境

- Windows 11、64 位 **R 4.6.1**
- R 包：DESeq2 1.52.0、Rsubread、GOstats 2.78.0、org.Mm.eg.db 3.23.0、GO.db、PoiClaClu 1.0.2.1、pheatmap、ggplot2、AnnotationDbi
- 外部工具：Cutadapt 4（Windows 原生版）
- Python（仅用于 PDF 取色/像素校验与报告生成）：PyMuPDF、Pillow、python-docx

安装 R 依赖（肌肉核查部分）：

```r
source("01_muscle_RNAseq/01_代码/核查与重绘/install_audit_deps.R")
```

安装肝脏包依赖：

```r
source("02_liver_RNAseq/05_code/00_install_dependencies.R")
```

### 4.2 肌肉（从 FASTQ 开始）

脚本位于 `01_muscle_RNAseq/01_代码/上游流程/`，按顺序执行：

1. `fetch_reference.py` — 下载 mm10/GRCm38 与 GENCODE M25 注释
2. `build_index.R` — 构建 Rsubread 索引
3. `download_raw.ps1` / `download_segmented.py` — 从 ENA 下载 32 个双端 FASTQ（18.28 GB）
4. `verify_downloads.py` — MD5 与大小校验（32/32 通过）
5. `qc_raw.R` → `trim_samples.py`（Cutadapt 4）→ `qc_clean.R` / `merge_clean_qc.R`
6. `align_count.R` / `align_count_unique.R` — Rsubread 比对（unique=TRUE）与 featureCounts 计数
7. `analyze.R` — DESeq2 建模、三组差异分析、GO 富集、绘图
8. `redraw_figures.R`、`physiology.R` — 图件与生理指标（Source Data）复现

关键中间结果（已入库）：`06_数据说明/download_verification.csv`、`04_结果/统计/` 下的 DEG 表与 GO 结果。

### 4.3 肝脏（从作者计数矩阵开始，无需下载 FASTQ）

```r
setwd("02_liver_RNAseq")
source("05_code/01_qc_model.R")          # 矩阵质控 + DESeq2 建模（可跳过，模型已保存）
source("05_code/05_final_report_figures.R")  # 生成 07_figures/final/ 下的报告用图
source("05_code/06_verify_final_figures.R")  # 校验解释率标签与热图叶序
source("05_code/03_verify_package.R")    # 文件与校验和核验（无需额外包）
```

绘图只需 `ggplot2` + `pheatmap`，不重新拟合模型。

---

## 5. 与原论文的差异与失败分析

| 环节 | 论文 / 作者 | 本次复现 | 影响 |
|---|---|---|---|
| 接头与质量处理 | Trim Galore | Cutadapt 4（q20，最短 20 bp） | 保留率 99.588%，差异有限 |
| 转录本定量 | Salmon + tximport | Rsubread / featureCounts（unique=TRUE） | 逐基因残差 sd≈0.59 的主要来源 |
| 基因注释 | UCSC knownGene | GENCODE M25 | 基因集合与长度偏移不同 |
| 长度偏移量 | 有 tximport 偏移 | 无 | 不能声称逐数值精确复现 |
| PCA 变换 | 图注写 VST，代码用 rlog | 两版并列提供 | Fig.1i 存在图注与代码不一致 |
| 富集背景 | 未完整公开 | GOstats 默认全库 / 表达背景两种 | 直接决定 Fig.4c 能否复现 |

**Fig.4c 不可复现的机制**（详见 `01_muscle_RNAseq/02_处理记录/接手核查记录_20261011.md`）：

- 用本次 35 个 DEG 按论文阈值（|log2FC|>0.6、padj<0.1）以 GOstats 复跑：
  - 表达背景（17,722 基因）：BH<0.1 条目 **0** 个；
  - GOstats 默认全库背景（112,257 基因）：cAMP 相关 GO:0140582 仅 padj=0.077 且 Count=1；
- 只有在**放宽为仅 padj<0.1（530 基因）+ 全库背景**时，cAMP/PKA 条目才转为「显著」（此时全库背景共有 1,354 个 BP 条目 BH<0.1，属明显背景膨胀）；
- 作者自己的 VST 表中，论文点名的 PKA 靶基因在 GDF15−Pair-fed 间差异极小（Ppargc1a +0.17、Sln +0.05、Pln +0.00、Atp2a1 −0.11、Ucp3 −0.12）。

> 结论：论文的 cAMP/PKA 富集依赖「小效应基因的 padj 显著性 + 全库背景的超几何膨胀」。本次**未删样本、未放宽阈值**以凑原图。

**Fig.4i 诚实性提示**：论文原图 y 轴为截断轴（基线 3），会把 3.77 vs 4.75 的均值差在视觉上放大近一倍（完整轴柱高比 1:1.26，截断轴 1:2.3）。本仓库按「格式与论文一致」复刻，同时保留完整轴版本 `Fig4i_calcium_respiration_fullaxis_backup.png`。

---

## 6. 数据可获取性

全部数据均为公开数据集，链接与校验信息见 `docs/数据集来源与可访问性说明.md`。

- 肌肉 FASTQ：ENA PRJNA955831（32 个双端文件，18.28 GB，MD5 32/32 校验通过）
- 肌肉表达矩阵（作者提供）：GEO GSE229794 补充文件
- 肝脏计数矩阵：GEO GSE229708 补充文件（507,141 字节，SHA256 见 `02_liver_RNAseq/01_data/data_sources.json`）

---

## 7. 学术诚信与 AI 使用

本项目的下载排障、代码编写、图件重绘与记录整理有**大语言模型辅助**，具体范围与边界见 `docs/AI辅助与学术诚信说明.md`（课程要求第 4 条）。所有图表与数据均注明原始文献出处；未抄袭、未购买代码或报告。

---

## 8. 引用

> Wang, D. et al. GDF15 promotes weight loss by enhancing energy expenditure in muscle. *Nature* **619**, 143–150 (2023). DOI: 10.1038/s41586-023-06249-4

作者公开代码：Zenodo 10.5281/zenodo.7838970
