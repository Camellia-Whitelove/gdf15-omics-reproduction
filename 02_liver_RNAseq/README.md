# Fig.1i / Fig.1j 肝脏转录组交接包

**建模已完成。协作者可直接从绘图数据继续，不必重跑分析。**

先读 `06_records/processing_record.md` 与 `06_records/report_notes.md`。这是肝脏数据，与此前肌肉 Fig.4b/4c 项目分开。

| 目录 | 用途 |
|---|---|
| 01_data | 作者原始发布的计数矩阵、18样本分组与GEO来源 |
| 02_qc | 矩阵和样本质控、过滤名单、诊断结果 |
| 03_models | 已拟合DESeq2模型、PCA模型、变换矩阵、聚类对象及探索性差异结果 |
| 04_plot_data | 可直接绘图的PCA坐标/解释率/500基因名单、距离矩阵与排列 |
| 05_code | 安装、质控建模、绘图、文件校验和模型验证的R代码 |
| 06_records | 完整简明处理记录、方法差异、报告注意事项、版本和运行日志 |
| 07_figures | 供核对的PNG候选图，协作者仍需制作报告用最终图 |
| 08_sources | 论文PDF、作者公开代码与原图参考 |

## 最快使用方式

1. 解压整个包，在RStudio打开一个脚本。
2. 把R的工作目录设置为解压后包含本README的文件夹。RStudio菜单：Session → Set Working Directory → Choose Directory。
3. 无额外包即可校验：`source("05_code/03_verify_package.R")`。显示PASS即可。
4. 绘图只需ggplot2和pheatmap：`source("05_code/02_plot.R")`。已提供示例PNG，可以编辑此脚本的字号、配色和导出参数。
5. 缺少包时执行 `source("05_code/00_install_dependencies.R")`，需要联网。实际运行版本见 `06_records/package_versions.csv`；其他版本可能产生小幅数值差异。
6. 如需重跑全部矩阵质控与建模：`source("05_code/01_qc_model.R")`，随后运行02_plot。此步骤会更新模型和图表数据；原随包校验清单将不再适用于更新后的文件。

## 明确限制

- 肝脏FASTQ未下载、未质控、未比对；本轮从作者计数矩阵开始。
- 图注写VST，作者PCA代码用rlog；Fig.1j的Poisson替代与原图排列一致，但不能说这是已确认的作者方法。
- 请并列说明两条变换路线，保留真实解释率，不能改成原图55.38%/5.08%。
- 不含测序原始文件、BAM、参考序列、索引、R软件或整套R库。绘图和报告所需输入、模型、代码、记录已保留。
