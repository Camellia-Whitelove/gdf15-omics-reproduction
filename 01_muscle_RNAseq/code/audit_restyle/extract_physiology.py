import pathlib, csv, openpyxl, json, hashlib
root=pathlib.Path(__file__).resolve().parents[2]/'data'
out=pathlib.Path(__file__).resolve().parents[2]/'outputs/physiology';out.mkdir(parents=True,exist_ok=True)
w=openpyxl.load_workbook(root/'source_MOESM4.xlsx',read_only=True,data_only=True)
ws=w['Fig.2d,e']; rows=list(ws.values); ee=[]
for c in range(1,13):
    for r in range(3,len(rows)):
        if isinstance(rows[r][c],(int,float)):
            ee.append(dict(temperature=rows[1][c],phase=rows[0][c],group=rows[2][c],mouse_index=r-2,EE_kcal_h=rows[r][c],source_cell=ws.cell(r+1,c+1).coordinate))
assert len(ee)==96
with (out/'fig2d_energy_expenditure.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=ee[0]);writer.writeheader();writer.writerows(ee)
ws=openpyxl.load_workbook(root/'source_MOESM6.xlsx',read_only=True,data_only=True)['Fig.4i']
values=list(ws.values);rows=[]
for c,group in enumerate(values[0]):
    for r in range(1,9):rows.append(dict(group=group,mouse_index=r,CAF_minus_DAN=values[r][c],source_cell=ws.cell(r+1,c+1).coordinate))
ext=list(openpyxl.load_workbook(root/'source_MOESM15.xlsx',read_only=True,data_only=True)['ED.Fig10o'].values)
for z in rows:
    col=z['mouse_index']+(0 if z['group']=='WT-Pair-fed' else 8)
    diff=ext[2][col]-ext[3][col]
    z['recalculated_CAF_minus_DAN']=diff
    z['difference_from_fig4i']=z['CAF_minus_DAN']-diff
    if abs(z['difference_from_fig4i'])>0.001:raise RuntimeError('CAF-DAN reconciliation failed')
with (out/'fig4i_calcium_respiration.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=rows[0]);writer.writeheader();writer.writerows(rows)
manifest=[]
for n in [4,6,11,15]:
    p=root/f'source_MOESM{n}.xlsx'
    manifest.append(dict(file=p.name,source=f'https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-023-06249-4/MediaObjects/41586_2023_6249_MOESM{n}_ESM.xlsx',bytes=p.stat().st_size,md5=hashlib.md5(p.read_bytes()).hexdigest()))
(out/'source_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('EXTRACTED 96 EE observations and 16 calcium respiration observations; CAF-DAN reconciled within 0.001. Body masses for Fig2e are absent from Fig2d,e sheet.',flush=True)
# Fig2k has its matching body masses in Extended Data Fig6a.
wb=openpyxl.load_workbook(root/'source_MOESM11.xlsx',read_only=True,data_only=True)
bw_rows=list(wb['ED.Fig6a'].values)
ee_rows=list(w['Fig.2j,k'].values)
def grouped(header,values):
    result={};current=None
    for name,value in zip(header,values):
        if isinstance(name,str):current=name
        if isinstance(value,(int,float)) and current is not None:result.setdefault(current,[]).append(value)
    return result
bw=grouped(bw_rows[0][1:],bw_rows[1][1:])
energy=grouped(ee_rows[1][1:],ee_rows[7][1:])
observations=[]
for group,values in energy.items():
    assert len(values)==len(bw[group]),(group,len(values),len(bw[group]))
    for i,(mass,value) in enumerate(zip(bw[group],values),1):observations.append(dict(group=group,mouse_index=i,body_mass_g=mass,dark_EE_kcal_h=value,BW_source='ED.Fig6a',EE_source='Fig.2j,k row 8'))
assert len(observations)==43
with (out/'fig2k_body_mass_and_EE.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=observations[0]);writer.writeheader();writer.writerows(observations)
print('Fig2k EXTRACTED 43 animals; BW and EE joined by named group and within-group source order. No individual mouse identifiers supplied in these tables.',flush=True)

