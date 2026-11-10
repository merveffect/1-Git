# -*- coding: utf-8 -*-
import os, matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
SP=os.path.dirname(os.path.abspath(__file__))
INK="#1c1f23"; MUT="#6f757e"; RULE="#d9dad8"
TEAL="#1f6f6a"; AMBER="#8a6410"; RED="#9b3b2f"; GREY="#c3c7c3"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":9,"axes.edgecolor":RULE,
 "text.color":INK,"xtick.color":MUT,"ytick.color":MUT,
 "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":200})

# --- agreement against the ceiling ---------------------------------------
aud=["Lecturer","Healthcare (broad)","Researcher","** ALL **","Head of faculty"]
val=[90.3,79.0,69.9,81.8,20.0]
n  =[28545,2757,14290,46656,1057]
col=[TEAL,TEAL,AMBER,"#2c6e8f",RED]
y=np.arange(len(aud))
fig,ax=plt.subplots(figsize=(6.5,2.5))
ax.barh(y,val,color=col,height=.6)
ax.axvline(88.9,color=RED,lw=1.1,ls="--")
ax.text(87.5,-0.75,"ceiling 88.9%\nwhat people agree with THEMSELVES",
        fontsize=7.4,color=RED,va="top",ha="right")
ax.set_yticks(y); ax.set_yticklabels(aud,fontsize=8.6); ax.invert_yaxis()
for i,(v,k) in enumerate(zip(val,n)):
    ax.text(v+1.2,i,f"{v}%   ({k:,} people)",va="center",fontsize=8,color=INK)
ax.set_xlim(0,118); ax.set_xlabel("of the people we classified, how many did we put in the right audience")
ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
fig.savefig(f"{SP}/fig/validation.png",bbox_inches="tight",facecolor="white"); plt.close(fig)

# --- the funnel ----------------------------------------------------------
steps=["People in the surveys","Matched to someone in the CDP",
       "We know their job at all","In the right audience"]
vals=[290045,238440,46656,38158]
fig,ax=plt.subplots(figsize=(6.5,2.0))
y=np.arange(len(steps))
ax.barh(y,vals,color=[GREY,GREY,TEAL,TEAL],height=.62)
ax.set_yticks(y); ax.set_yticklabels(steps,fontsize=8.6); ax.invert_yaxis()
for i,v in enumerate(vals):
    ax.text(v+5000,i,f"{v:,}",va="center",fontsize=8.2,color=INK)
ax.set_xlim(0,340000); ax.set_xticks([0,100000,200000,300000])
ax.xaxis.set_major_formatter(lambda v,p: f"{int(v/1000)}k" if v else "0")
ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
ax.text(0,3.75,"the drop from 238k to 47k is COVERAGE, not accuracy — "
        "we have no ORCID record for most of them",fontsize=7.6,color=MUT)
fig.savefig(f"{SP}/fig/validation_funnel.png",bbox_inches="tight",facecolor="white"); plt.close(fig)
print("2 grafik uretildi")
