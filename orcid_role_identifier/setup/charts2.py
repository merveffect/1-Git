# -*- coding: utf-8 -*-
import os, matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
SP=os.path.dirname(os.path.abspath(__file__))
INK="#1c1f23"; MUT="#6f757e"; RULE="#d9dad8"
TEAL="#1f6f6a"; PLUM="#8a3d5e"; AMBER="#8a6410"; RED="#9b3b2f"; GREY="#c3c7c3"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":9,
 "axes.edgecolor":RULE,"text.color":INK,"xtick.color":MUT,"ytick.color":MUT,
 "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":200})
def save(f,n): f.savefig(f"{SP}/fig/{n}.png",bbox_inches="tight",facecolor="white"); plt.close(f)

# --- probable tier impact -------------------------------------------------
aud=["Healthcare (broad)","Pharmacist","Head of faculty","Clinical administrator",
     "Practitioner","Clinical researcher","Researcher","Lecturer"]
conf=[126270,2335,20222,6855,60083,50590,322266,400445]
prob=[236418,4889,30678,8781,63113,52767,323062,400763]
add=[p-c for p,c in zip(prob,conf)]
pct=[round((p-c)/c*100) for p,c in zip(prob,conf)]
y=np.arange(len(aud))
fig,ax=plt.subplots(figsize=(6.5,3.0))
ax.barh(y,conf,color=TEAL,height=.6,label="delivered today (Confirmed)")
ax.barh(y,add,left=conf,color=AMBER,height=.6,alpha=.75,label="would be added (Probable)")
ax.set_yticks(y); ax.set_yticklabels(aud,fontsize=8.5); ax.invert_yaxis()
for i,(c,a,p) in enumerate(zip(conf,add,pct)):
    if p>=5: ax.text(c+a+6000,i,f"+{p}%",va="center",fontsize=8,color=AMBER)
ax.set_xlabel("people"); ax.legend(frameon=False,fontsize=8,loc="lower center",bbox_to_anchor=(.5,1.01),ncol=2)
ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
ax.set_xlim(0,470000)
ax.xaxis.set_major_formatter(lambda v,p: f"{int(v/1000)}k" if v else "0")
save(fig,"probable")

print("1 grafik uretildi")
