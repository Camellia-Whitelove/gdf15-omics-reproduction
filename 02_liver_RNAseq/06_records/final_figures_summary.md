# 最终报告图制作记录

日期：2026-10-14

## 已完成工作

1. **完整性核验**：运行 `05_code/03_verify_package.R`，文件、MD5、字节数、样本身份和绘图坐标全部 PASS。
2. **依赖补齐**：本机缺少 `pheatmap`，执行 `05_code/00_install_dependencies.R` 完成安装（同时补全 DESeq2 / PoiClaClu）。
3. **最终图脚本**：新增 `05_code/05_final_report_figures.R`。
   - 从 `04_plot_data/` 读取已保存的 PCA 坐标、解释率和距离矩阵；不重新拟合模型。
   - 生成 `07_figures/final/` 目录下的报告用 PNG + PDF。
4. **验证脚本**：新增 `05_code/06_verify_final_figures.R`。
   - 核对 Fig.1i 的 PC1/PC4 解释率标签与实际数值一致。
   - 核对 Fig.1j raw Poisson 热图的叶序与 `04_plot_data/order_raw_Poisson.csv` 完全一致（18/18）。

## 输出文件

| 文件 | 说明 |
|---|---|
| `07_figures/final/Fig1i_rlog_final.png/.pdf` | 作者代码使用的 rlog 变换；PC1=56.18%，PC4=5.10% |
| `07_figures/final/Fig1i_VST_final.png/.pdf` | 论文图注声明的 VST 变换；PC1=56.34%，PC4=4.98% |
| `07_figures/final/Fig1j_raw_Poisson_final.png/.pdf` | 与原图叶序完全一致的 raw-count Poisson 距离热图 |

## 格式一致性说明

- **Fig.1i**：采用 `theme_classic`，移除候选图中的标题和副标题；坐标轴标注使用真实解释率（未改成论文标签 55.38%/5.08%）；保留 95% t 型数据椭圆和分组颜色（GDF15 红、PairFed 绿、Vehicle 蓝）。
- **Fig.1j**：使用 pheatmap 默认 `RdYlBu` 反转配色（蓝低-红高），与候选图一致；移除标题；将色标标题设为 "Sample distance"；样本标签格式化为 "GDF15 1" 等；**2026-10-14 再调整：按论文 Fig.1j 版面，改用极浅 `grey90` 边框、隐藏右侧行名、仅保留底部垂直列名、色标刻度加千分位逗号、标题位于色标右侧，使版式与原文一致**。

## 仍须注意的方法差异

- Fig.1i 的图注写 VST，作者 PCA 代码使用 rlog；因此同时提供两版，报告应并列说明。
- Fig.1j 使用 raw-count Poisson 距离是本次诊断性替代方法，与原图 caption 的 VST 不一致，且未经作者确认。
- 肝脏分析从作者已上传的计数矩阵开始，未下载/比对 FASTQ；不宜声称逐数值精确复现。
