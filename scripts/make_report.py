# -*- coding: utf-8 -*-
"""生成 GDF15 核心图复现报告（Word）。"""
import os
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

BASE = r'C:\这只是一个完整的包'
MUSCLE_FIG = os.path.join(BASE, 'GDF15_核心图交接包_20261011', '01_继续分析项目', 'outputs', 'figures')
LIVER_FIG = os.path.join(BASE, 'GDF15_肝脏Fig1i_1j交接包_20261013', '07_figures', 'final')
OUT = r'C:\Users\GT14\Desktop\R-for-bioinformatics\GDF15_核心图复现报告_20261015.docx'

FONT = '微软雅黑'
doc = Document()

# ---------- 页面与默认样式 ----------
sec = doc.sections[0]
sec.page_width = Cm(21.0)
sec.page_height = Cm(29.7)
sec.left_margin = sec.right_margin = Cm(2.2)
sec.top_margin = sec.bottom_margin = Cm(2.2)
CONTENT_W = 21.0 - 4.4  # 16.6 cm

style = doc.styles['Normal']
style.font.name = FONT
style.font.size = Pt(10.5)
style.element.rPr.rFonts.set(qn('w:eastAsia'), FONT)


def set_run(run, size=10.5, bold=False, italic=False, color=None, font=FONT):
    run.font.name = font
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    if color:
        run.font.color.rgb = RGBColor.from_string(color)
    run._element.rPr.rFonts.set(qn('w:eastAsia'), font)
    return run


def para(text, size=10.5, bold=False, italic=False, align=None, color=None,
         space_before=4, space_after=4, style_name=None):
    p = doc.add_paragraph(style=style_name)
    if align is not None:
        p.alignment = align
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.35
    r = p.add_run(text)
    set_run(r, size=size, bold=bold, italic=italic, color=color)
    return p


def heading(text, level=1):
    p = doc.add_paragraph(style=f'Heading {level}')
    p.paragraph_format.space_before = Pt(14 if level == 1 else 10)
    p.paragraph_format.space_after = Pt(6)
    r = p.add_run(text)
    set_run(r, size=16 if level == 1 else 13, bold=True,
            color='1F3864' if level == 1 else '2E5496')
    return p


def bullet(text):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.3
    r = p.add_run(text)
    set_run(r)
    return p


def numbered(text):
    p = doc.add_paragraph(style='List Number')
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.3
    r = p.add_run(text)
    set_run(r)
    return p


def set_cell_bg(cell, color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:fill'), color)
    tcPr.append(shd)


def add_table(rows, widths=None, header=True):
    t = doc.add_table(rows=len(rows), cols=len(rows[0]))
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    if widths:
        total = sum(widths)
        widths = [w / total * CONTENT_W for w in widths]
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = t.cell(ri, ci)
            cell.text = ''
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            r = p.add_run(val)
            set_run(r, size=9, bold=(header and ri == 0))
            if header and ri == 0:
                set_cell_bg(cell, 'DCE6F1')
            if widths:
                cell.width = Cm(widths[ci])
    if widths:
        for ri in range(len(rows)):
            for ci in range(len(rows[0])):
                t.cell(ri, ci).width = Cm(widths[ci])
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


def add_figure(path, width_cm, caption):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.add_run().add_picture(path, width=Cm(width_cm))
    para(caption, size=9, italic=True, align=WD_ALIGN_PARAGRAPH.CENTER,
         color='444444', space_before=0, space_after=10)


def add_toc_field():
    p = doc.add_paragraph()
    r = p.add_run()
    fld_begin = OxmlElement('w:fldChar')
    fld_begin.set(qn('w:fldCharType'), 'begin')
    instr = OxmlElement('w:instrText')
    instr.set(qn('xml:space'), 'preserve')
    instr.text = r'TOC \o "1-2" \h \z \u'
    fld_sep = OxmlElement('w:fldChar')
    fld_sep.set(qn('w:fldCharType'), 'separate')
    t = OxmlElement('w:t')
    t.text = '（在 Word 中右键“更新域”以生成目录）'
    fld_end = OxmlElement('w:fldChar')
    fld_end.set(qn('w:fldCharType'), 'end')
    r._r.append(fld_begin)
    r._r.append(instr)
    r._r.append(fld_sep)
    r._r.append(t)
    r._r.append(fld_end)


# ---------- 封面标题 ----------
para('GDF15 核心图复现报告', size=22, bold=True, align=WD_ALIGN_PARAGRAPH.CENTER,
     space_before=10, space_after=6)
para('论文：GDF15 promotes weight loss by enhancing energy expenditure in muscle',
     size=10.5, italic=True, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
para('Nature 2023 ｜ DOI：10.1038/s41586-023-06249-4 ｜ 作者代码：Zenodo 10.5281/zenodo.7838970',
     size=9.5, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
para('报告日期：2026-10-15 ｜ 环境：Windows 11、R 4.6.1',
     size=9.5, align=WD_ALIGN_PARAGRAPH.CENTER, color='666666', space_after=12)

para('目录', size=14, bold=True, space_before=6, space_after=4)
add_toc_field()
doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ---------- 一、概述 ----------
heading('一、复现概述与范围', 1)
para('本报告汇总两个交接包的全部复现与核查工作：①胫骨前肌（TA 肌肉）RNA-seq 全流程复现与 Fig.4 系列图；'
     '②肝脏转录组 Fig.1i / Fig.1j 的建模后绘图与最终报告图制作。两个项目的数据来源、处理起点与方法边界不同，'
     '报告中分别说明，不做组织间混用。')

heading('1.1 复现目标', 2)
bullet('肌肉项目：从 ENA 原始 FASTQ 出发，用替代工具链完成质控、比对、定量与 DESeq2 差异分析，并复现 Fig.4b、Fig.4c、Fig.4i。')
bullet('肝脏项目：从作者公开计数矩阵出发，完成矩阵质控、DESeq2 建模、PCA 与样本距离计算，并制作 Fig.1i / Fig.1j 的报告用最终图。')
bullet('核查任务（肌肉交接包待办）：作者表达表变换方式鉴定、作者表与本次矩阵的基因/样本对应、Fig.4c 未能复现的原因排查。')

heading('1.2 总体结论一览', 2)
add_table([
    ['图件', '复现状态', '说明'],
    ['Fig.1i（肝脏 PCA）', '已复现', 'rlog 与 VST 两版；解释率使用真实计算值，未改成论文标签'],
    ['Fig.1j（肝脏样本距离）', '已复现', 'raw-count Poisson 距离；叶序与原图 18/18 一致'],
    ['Fig.4b（肌肉样本距离）', '已复现', 'Poisson 距离聚类；聚类存在组间混合'],
    ['Fig.4c（肌肉 GO 富集）', '不可复现', '按论文方法无法复现 cAMP/PKA 信号，机制已定位'],
    ['Fig.4i（钙依赖呼吸）', '已复现', '双侧 Student 检验 P=0.0081，与论文一致'],
    ['Fig.2d（能量消耗）', '既有产出', '使用论文 Source Data 复现，非本次待办任务'],
    ['Fig.2e / Fig.2k', '未复现 / 探索性', '缺配对体重数据；配对关系未证实'],
], widths=[3.2, 2.6, 8.0])

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ---------- 二、数据与方法 ----------
heading('二、数据与方法', 1)
heading('2.1 肌肉（胫骨前肌）RNA-seq：从 FASTQ 开始的全流程', 2)
para('数据集 GSE229794 / PRJNA955831：Vehicle 5 个、GDF15 6 个、Pair-fed 5 个，共 16 样本、32 个双端 FASTQ，'
     '每端 51 bp。用户选定 Windows 原生方案：ShortRead → Cutadapt → Rsubread → featureCounts → DESeq2 → R 作图，'
     '属于方法替代复现。')
add_table([
    ['步骤', '方法与核查', '实际结果'],
    ['下载', 'ENA 大小与 MD5 校验', '32/32 通过；18.281 GB，295,672,731 对读段'],
    ['原始质控', 'ShortRead 全量数量/配对 ID 检查；0.5% 质量抽样（种子 955831）', '数量一致、ID 错配 0；Q30 93.60%–94.86%'],
    ['接头与质量清理', 'Cutadapt 4：双端接头，q20、最短 20 bp', '保留 294,455,592 对（99.588%）'],
    ['清理后质控', '每端抽样 100,000 条核对修剪 JSON', '32 文件通过；Q30 93.98%–95.00%'],
    ['比对', 'mm10/GRCm38 + GENCODE M25；Rsubread 2.26.0，unique=TRUE', '唯一比对 257,859,622 对（87.57%）'],
    ['基因计数', 'featureCounts 反向链 s=2，要求双端比对', '分配 241,070,087 对（81.87%）'],
    ['差异分析', 'DESeq2 ~condition；总计数≥5；|log2FC|>0.6、BH padj<0.1',
     '22,032 基因；DEG：35 / 39 / 78（GDF15 vs Pair-fed、vs Vehicle、Pair-fed vs Vehicle）'],
], widths=[2.6, 6.0, 6.0])

heading('2.2 肝脏转录组：从作者计数矩阵开始', 2)
para('数据集 GSE229708：作者公开的 Counts4allSamples.csv.gz（507,141 字节），16,245 基因 × 18 样本；'
     'Vehicle、GDF15、PairFed 各 6 个，对应 GSM7173713–GSM7173730。本轮未下载肝脏 FASTQ、未做测序质控与比对，'
     '起点即为作者处理后的计数矩阵。')
bullet('过滤：沿用作者代码的总计数≥5；16,245 个基因全部保留，剔除 0 个。')
bullet('模型：DESeq2，design ~ condition，Vehicle 为参照；未获得作者 Salmon/tximport 的长度偏移量，故为直接计数模型。')
bullet('变换：VST 与 rlog 各执行一遍（blind=FALSE），两条路线并列保存。')
bullet('PCA：每种变换独立选取变异最高 500 基因，prcomp 中心化、不缩放，展示 PC1/PC4。')
bullet('样本距离：VST 欧氏、rlog 欧氏、原始计数 Poisson 三种，均用 complete linkage。')

heading('2.3 关键方法差异（必读）', 2)
add_table([
    ['环节', '论文 / 作者', '本次复现'],
    ['接头与质量处理', 'Trim Galore', 'Cutadapt 4（q20，最短 20 bp）'],
    ['转录本定量', 'Salmon + tximport', 'Rsubread / featureCounts（unique=TRUE）'],
    ['基因注释', 'UCSC knownGene', 'GENCODE M25'],
    ['长度偏移量', '有 tximport 偏移', '无（直接计数模型）'],
    ['多重比对策略', '作者策略未完全公开', '统一 unique=TRUE 重做'],
    ['PCA 变换', '图注写 VST，代码用 rlog', '两版都计算并并列提供'],
    ['肝脏数据起点', '作者计数矩阵', '同上，未做 FASTQ 流程'],
    ['富集工具与参数', 'GOstats（参数未完整公开）', 'GOstats 2.78.0，参考作者公开的 clusterProfiler 参数'],
], widths=[3.0, 5.8, 5.8])

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ---------- 三、结果 ----------
heading('三、复现结果', 1)

heading('3.1 Fig.1i：肝脏 PCA（PC1 vs PC4）', 2)
para('模型：DESeq2 变换后取变异最高 500 基因，中心化 PCA。真实解释率为 rlog PC1=56.18% / PC4=5.10%，'
     'VST PC1=56.34% / PC4=4.98%；论文原图标签为 55.38% / 5.08%。本次坐标轴标注使用真实计算值，未改成论文数值。'
     '图中椭圆为 ggplot2 的 95% t 型数据椭圆，仅作组分布示意，不是组间显著性证据。')
add_figure(os.path.join(LIVER_FIG, 'Fig1i_rlog_final.png'), 11.0,
           '图 1　Fig.1i 复现（rlog 变换，作者 PCA 代码所用方法）：PC1 56.18%、PC4 5.10%')
add_figure(os.path.join(LIVER_FIG, 'Fig1i_VST_final.png'), 11.0,
           '图 2　Fig.1i 复现（VST 变换，论文图注声明方法）：PC1 56.34%、PC4 4.98%')

heading('3.2 Fig.1j：肝脏样本距离热图', 2)
para('采用原始计数 Poisson 距离（complete linkage）。该候选的 18 个样本叶序与原图完全一致（18/18），'
     '而 VST 欧氏仅 1/18、rlog 欧氏 13/18（叶序受等价树分支翻转影响，仅作核对信息）。'
     '最大距离：VST 欧氏 56.0068、rlog 欧氏 46.1447、原始计数 Poisson 20,778.2880。'
     '版式按论文 Fig.1j 调整：极浅灰色网格、底部垂直样本名、色标刻度千分位、色标标题 “Sample distance”。')
add_figure(os.path.join(LIVER_FIG, 'Fig1j_raw_Poisson_final.png'), 10.5,
           '图 3　Fig.1j 复现（raw-count Poisson 距离），叶序与原图 18/18 一致')

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

heading('3.3 Fig.4b：肌肉样本 Poisson 距离热图', 2)
para('已按论文第 6 页面板 b 的格式重绘：RdYlBu 100 色渐变、灰色单元格边框、黑色 45° 样本标签、'
     '“Sample distance” 色条、Poisson 距离聚类。聚类结果显示三组未完全干净分开（部分 Pair-fed 与 GDF15 样本混合），'
     '这与本次数据的实际结构一致，未为追求分组而删样本或调参。')
add_figure(os.path.join(MUSCLE_FIG, 'Fig4b_sample_distance.png'), 12.0,
           '图 4　Fig.4b 复现（论文样式重绘）：样本 Poisson 距离热图')

heading('3.4 Fig.4c：肌肉 GO 富集——不可复现，原因已定位', 2)
para('论文 Fig.4c 为 GDF15 vs pair-fed 的 GO 注释（BH 校正），正文称富集出 cAMP/PKA 信号；'
     '方法节 DEG 阈值为 |log2FC|>0.6、padj<0.1（与本次一致），富集工具为 GOstats。'
     '用本次 35 个 DEG 以 GOstats 2.78.0（org.Mm.eg.db 3.23.0）复跑结果如下：')
add_table([
    ['背景设定', 'BP 条目数', 'raw P<0.05', 'BH<0.1', 'cAMP/PKA 条目'],
    ['表达背景（17,722 基因）', '1,489', '375', '0', '无（最好 padj=0.15）'],
    ['全库背景（112,257 基因）', '1,492', '553', '280', 'GO:0140582，padj=0.077，Count=1'],
], widths=[5.0, 2.2, 2.2, 2.0, 5.2])
para('敏感性分析（明确标注为敏感性分析、非主分析）：仅用 padj<0.1（530 基因，含 Ppargc1a、Atp2a1、Ryr1）且不限 log2FC，'
     '配合 GOstats 默认全库背景时，cAMP/PKA 相关条目才转为“显著”（regulation of protein kinase activity padj=0.013、'
     'regulation of cAMP/PKA signal transduction padj=0.055、response to cAMP padj=0.066）；'
     '同设定下使用表达背景则不显著（padj=0.19–0.29）。全库背景下共有 1,354 个 BP 条目 BH<0.1，属明显的背景膨胀。')
para('补充证据：作者公开的 VST 表中，论文点名的 PKA 靶基因在 GDF15−Pair-fed 间差异极小'
     '（Ppargc1a +0.17、Sln +0.05、Pln +0.00、Atp2a1 −0.11、Ucp3 −0.12）；本次 DESeq2 中 Ppargc1a'
     '（LFC=0.34，padj=0.026）、Atp2a1（LFC=−0.11，padj=0.016）虽 padj 显著，但远达不到 |LFC|>0.6。')
para('结论：论文的 cAMP/PKA 富集依赖“小效应基因的 padj 显著性 + 全库背景的超几何膨胀”，'
     '在论文声明的 DEG 阈值与合理表达背景内不可复现。替代流程下真正稳健的富集信号为糖/核苷酸分解代谢、'
     '快肌纤维收缩、肽/细胞因子响应等（表达背景下 BH<0.1 共 324 条 BP），'
     '与 Cish、Pfkfb3、Chac1、Nmrk2、Ppp1r3c 等强 DEG 生物学一致。全程未删样本、未放宽阈值以凑原图。')

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

heading('3.5 Fig.4i：钙依赖呼吸速率', 2)
para('使用论文 Source Data 复现（独立生理数据，非 RNA-seq 矩阵）。Pair-fed vs GDF15，双侧 Student 检验 P=0.0081，'
     '与论文一致。图按论文第 6 页面板 i 格式重绘：截断 y 轴（3–6）、红/蓝柱、SEM 误差线、柱上散点、P 值横线括号。')
add_figure(os.path.join(MUSCLE_FIG, 'Fig4i_calcium_respiration.png'), 7.5,
           '图 5　Fig.4i 复现（论文样式，截断轴）')
para('诚实性提示：论文原图 y 轴为截断轴（基线=3），会把 3.77 vs 4.75 的均值差在视觉上放大近一倍'
     '（完整轴柱高比 1:1.26，截断轴 1:2.3）。课程报告如使用该图，建议注明截断轴，'
     '或改用完整轴版本（Fig4i_calcium_respiration_fullaxis_backup.png）。', size=9.5, color='8B0000')

heading('3.6 其他图件（既有产出与探索性结果）', 2)
add_figure(os.path.join(MUSCLE_FIG, 'GDF15_vs_Pairfed_volcano.png'), 11.0,
           '图 6　GDF15 vs Pair-fed 火山图：红点为 35 个 DEG（|LFC|>0.6、padj<0.1）')
add_figure(os.path.join(MUSCLE_FIG, 'RNAseq_PCA.png'), 11.0,
           '图 7　肌肉 RNA-seq VST PCA：三组部分重叠，与 Fig.4b 的组间混合一致')
add_figure(os.path.join(MUSCLE_FIG, 'Fig2d_energy_expenditure.png'), 11.0,
           '图 8　Fig.2d 能量消耗（既有产出，Source Data 复现，非本次待办任务）')
para('未复现项：Fig.2e 缺少匹配的动物体重数据；Fig.2k 按表顺序配对未经证实，且 KO 共同斜率检验 P≈0.023，'
     '仅保留为探索性附件。')

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ---------- 四、核查 ----------
heading('四、关键核查发现', 1)
heading('4.1 作者表达表的变换方式：确认为 DESeq2 VST', 2)
para('作者公开的 GSE229794_CountsNormalizedByDESeq2.csv.gz（14,538 基因 × 16 样本，数值范围 7.32–19.96）'
     '此前变换方式不明。与本次 DESeq2 模型逐一比对：')
bullet('与本次 VST 值：r=0.976–0.977、斜率≈0.998、r²≈0.954（16 个样本全部一致）；')
bullet('与 rlog：r≈0.88、斜率≈0.36；与 log2(归一化计数)：斜率≈0.38，低表达层斜率→0.10、高表达层→0.92（方差稳定变换的典型压缩特征）。')
para('结论：该表是 DESeq2 VST 变换值，不是原始计数，也不是 log2 计数，不能当整数计数使用。'
     '逐基因残差（resid_sd≈0.59）主要来自定量与注释差异（Salmon/tximport vs featureCounts、'
     'UCSC knownGene vs GENCODE M25）。')

heading('4.2 样本与基因对应：16/16 按序一致', 2)
add_table([
    ['作者表达表列', '本次样本', '组别'],
    ['Vehicle.1–5', 'GSM7177833–37', 'Vehicle'],
    ['GDF15.1–6', 'GSM7177838–43', 'GDF15'],
    ['PairFed.2–6', 'GSM7177844–48', 'Pair-fed'],
], widths=[5.5, 5.5, 5.5])
para('每列与对应样本的 Pearson r 均为最高（0.891–0.893，对 log2 归一化计数）；比较方向均为 GDF15 相对对照，'
     '与论文及作者代码一致。LFC 秩一致性：GDF15 vs Pair-fed Spearman ρ=0.752，GDF15 vs Vehicle ρ=0.740。'
     '作者表中 |ΔVST| 最大的基因（Cish −1.63、Pfkfb3 −1.25、Chac1 −1.10 等）与本次 35 个 DEG 高度重合，强信号两侧一致。')

heading('4.3 肝脏包完整性核验', 2)
para('运行 05_code/03_verify_package.R：文件齐全、MD5 与字节数一致、样本身份与绘图坐标一致，结果为 PASS。'
     '新增的 06_verify_final_figures.R 复核 Fig.1i 解释率标签与 Fig.1j Poisson 叶序（18/18 一致）。')

doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

# ---------- 五、产出 ----------
heading('五、产出文件与代码位置', 1)
add_table([
    ['类别', '位置'],
    ['肌肉最终图（论文样式）',
     'GDF15_核心图交接包_20261011\\01_继续分析项目\\outputs\\figures\\（Fig4b、Fig4i 等；原图备份于 backup_原版_20261011\\）'],
    ['肝脏最终报告图',
     'GDF15_肝脏Fig1i_1j交接包_20261013\\07_figures\\final\\（Fig1i_rlog / VST、Fig1j_raw_Poisson 的 PNG 与 PDF）'],
    ['肌肉核查代码',
     'work\\gdf15\\audit_handoff_20261011.R、audit_transform_gostats_20261011.R、audit_sensitivity_padj_only_20261011.R、check_pka_author_scale.R'],
    ['图件重绘代码', 'work\\gdf15\\restyle_fig4b_fig4i_paper_style.R'],
    ['肝脏绘图与验证代码', '05_code\\05_final_report_figures.R、05_code\\06_verify_final_figures.R'],
    ['核查与处理记录',
     '02_处理记录\\接手核查记录_20261011.md；06_records\\processing_record.md、final_figures_summary.md、report_notes.md'],
], widths=[4.5, 12.1])

# ---------- 六、边界 ----------
heading('六、边界、局限与诚实性声明', 1)
numbered('本次为方法替代复现：修剪、定量、注释、多重比对策略均与作者不同，且缺少 tximport 长度偏移量，不宣称逐数值精确复现。')
numbered('肝脏分析从作者计数矩阵开始，未执行肝脏 FASTQ 下载、质控与比对；此前肌肉 FASTQ 流程不能作为肝脏处理证据。')
numbered('Fig.4c 判定为“不可复现（方法依赖性结果）”，未为凑原图而删样本或放宽阈值。')
numbered('Fig.4i 与论文一致采用截断轴，视觉上放大组间差异；建议报告注明或提供完整轴版本。')
numbered('Fig.1i 图注（VST）与作者代码（rlog）不一致，两版并列提供；Fig.1j 的 Poisson 距离为诊断性替代，未经作者确认。')
numbered('Fig.2e 未复现（缺配对体重数据）；Fig.2k 配对关系未证实，仅作探索性附件。')
numbered('PCA 与热图展示的是样本相似性，不能据此证明具体通路激活或肌肉能耗机制；两组织数据不应混用。')
numbered('本项目的下载排障、代码编写与记录整理有 AI 辅助，课程报告应披露该范围，并由学生复核统计方法与生物学解释。')

# 修复默认 settings.xml 中 zoom 缺少 percent 属性
zoom = doc.settings.element.find(qn('w:zoom'))
if zoom is not None:
    zoom.set(qn('w:percent'), '100')

doc.save(OUT)
print('WROTE', OUT)
