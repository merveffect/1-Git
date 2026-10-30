# -*- coding: utf-8 -*-
import os, matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
SP=os.path.dirname(os.path.abspath(__file__))
INK="#1c1f23"; MUT="#6f757e"; RULE="#d9dad8"
TEAL="#1f6f6a"; AMBER="#8a6410"; RED="#9b3b2f"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":9,"axes.edgecolor":RULE,
 "text.color":INK,"xtick.color":MUT,"ytick.color":MUT,
 "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":200})

aud = ["Lecturer","Researcher","Healthcare (broad)","Head of faculty"]
rec = [91.1, 74.3, 90.9, 23.8]
pre = [78.2, 43.9, 22.7, 26.3]
y = np.arange(len(aud)); h = 0.36
fig, ax = plt.subplots(figsize=(6.5,2.7))
ax.barh(y-h/2, rec, height=h, color=TEAL,  label="did we FIND the people who say they are this?")
ax.barh(y+h/2, pre, height=h, color=AMBER, label="do the people we PUT here say they are this?")
ax.set_yticks(y); ax.set_yticklabels(aud, fontsize=9); ax.invert_yaxis()
for i,(r,p) in enumerate(zip(rec,pre)):
    ax.text(r+1.5, i-h/2, f"{r}%", va="center", fontsize=8.2, color=TEAL)
    ax.text(p+1.5, i+h/2, f"{p}%", va="center", fontsize=8.2, color=AMBER)
ax.set_xlim(0,108); ax.set_xlabel("measured against people who gave the same answer in two surveys")
ax.legend(frameon=False, fontsize=7.8, loc="lower center", bbox_to_anchor=(.5,1.01), ncol=1)
ax.grid(axis="x", color=RULE, lw=.6, alpha=.7); ax.set_axisbelow(True)
fig.savefig(f"{SP}/fig/two_directions.png", bbox_inches="tight", facecolor="white"); plt.close(fig)
print("grafik uretildi")
