# -*- coding: utf-8 -*-
import os, matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
SP=os.path.dirname(os.path.abspath(__file__))
INK="#1c1f23"; MUT="#6f757e"; RULE="#d9dad8"
TEAL="#1f6f6a"; PLUM="#8a3d5e"; AMBER="#8a6410"; RED="#9b3b2f"; GREY="#c3c7c3"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":9,"axes.edgecolor":RULE,
 "text.color":INK,"xtick.color":MUT,"ytick.color":MUT,
 "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":200})

# --- A. machine vs human, per group --------------------------------------
g=["teaching_academic","researcher_early","student","researcher_established",
   "practitioner","support_technical","leadership","trainee_clinical","pharmacist"]
hs=[0.295,3.17,3.89,7.71,1.03,4.63,3.26,0.27,0.0]
y=np.arange(len(g))
fig,ax=plt.subplots(figsize=(6.4,2.8))
ax.barh(y,hs,color=[PLUM if v>=3 else AMBER if v>=1 else GREY for v in hs],height=.62)
ax.set_yticks(y); ax.set_yticklabels(g,fontsize=8.4); ax.invert_yaxis()
for i,v in enumerate(hs):
    ax.text(v+0.12,i,f"{v}%" if v else "none",va="center",fontsize=8,color=INK)
ax.set_xlim(0,9.2); ax.set_xlabel("share of records a person decided, not the machine")
ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
fig.savefig(f"{SP}/fig/human_share.png",bbox_inches="tight",facecolor="white"); plt.close(fig)

# --- B. lecturer: the two directions + the title-reading check ------------
fig,ax=plt.subplots(figsize=(6.4,2.0))
lab=["Did we FIND the people\nwho say they teach?",
     "Do the people we PUT here\nsay they teach?",
     "Did we READ their\njob title correctly?"]
val=[91.1,78.2,99.2]
col=[TEAL,AMBER,TEAL]
y=np.arange(len(lab))
ax.barh(y,val,color=col,height=.55)
ax.axvline(88.9,color=RED,lw=1.0,ls="--")
ax.text(87.8,-0.62,"ceiling 88.9%",fontsize=7.4,color=RED,ha="right",va="top")
ax.set_yticks(y); ax.set_yticklabels(lab,fontsize=8.2); ax.invert_yaxis()
for i,v in enumerate(val): ax.text(v+1.2,i,f"{v}%",va="center",fontsize=8.6,color=INK)
ax.set_xlim(0,112); ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
ax.set_xlabel("Lecturer, measured against people who answered two surveys the same way")
fig.savefig(f"{SP}/fig/lecturer_three.png",bbox_inches="tight",facecolor="white"); plt.close(fig)

# --- C. the one-word failure family --------------------------------------
fig,ax=plt.subplots(figsize=(6.4,1.9))
t=["member  ·  9 Oct\nvia 'faculty member'","fellow  ·  29 Oct\nvia 'clinical fellow'",
   "associate  ·  30 Oct\nvia 'associate professor'"]
v=[23157,48777,6631]
x=np.arange(len(t))
ax.bar(x,v,color=[GREY,GREY,PLUM],width=.5)
ax.set_xticks(x); ax.set_xticklabels(t,fontsize=8.2)
for i,vv in enumerate(v):
    ax.text(i,vv+1600,f"{vv:,}",ha="center",fontsize=8.6,color=INK)
ax.set_ylim(0,58000); ax.set_ylabel("records")
ax.yaxis.set_major_formatter(lambda v,p: f"{int(v/1000)}k" if v else "0")
ax.grid(axis="y",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
ax.set_title("One word out of two: the same mistake, three times, 78,565 records",
             fontsize=8.6,color=INK,pad=8)
fig.savefig(f"{SP}/fig/one_word.png",bbox_inches="tight",facecolor="white"); plt.close(fig)
print("3 grafik uretildi")
