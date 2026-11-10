# -*- coding: utf-8 -*-
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

INK="#1c1f23"; MUT="#6f757e"; RULE="#d9dad8"
TEAL="#1f6f6a"; PLUM="#8a3d5e"; AMBER="#8a6410"; RED="#9b3b2f"; GREY="#b9bdb9"
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":9,
    "axes.edgecolor":RULE,"axes.labelcolor":INK,"text.color":INK,
    "xtick.color":MUT,"ytick.color":MUT,"axes.spines.top":False,
    "axes.spines.right":False,"figure.dpi":200})

def save(fig,name):
    fig.savefig(f"{SP}/fig/{name}.png",bbox_inches="tight",facecolor="white"); plt.close(fig)
import os; SP=os.path.dirname(os.path.abspath(__file__))

# --- 1. what the taxonomy knows about our anchors -------------------------
groups=["practitioner","support_technical","pharmacist","leadership","student",
        "researcher_early","teaching_academic","trainee_clinical","researcher_established"]
unknown=[52,9,9,7,7,6,6,5,2]
fig,ax=plt.subplots(figsize=(6.6,3.1))
y=range(len(groups))
ax.barh(list(y),unknown,color=[RED if v>=20 else AMBER if v>=6 else GREY for v in unknown],height=.62)
ax.set_yticks(list(y)); ax.set_yticklabels(groups,fontsize=8.5)
ax.invert_yaxis(); ax.set_xlabel("our anchors the taxonomy does NOT list")
for i,v in enumerate(unknown): ax.text(v+.8,i,str(v),va="center",fontsize=8.5,color=INK)
ax.set_xlim(0,60); ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
save(fig,"taxonomy_blindspot")

# --- 2. coverage read per profession --------------------------------------
prof=["Researcher, early","Teaching academic","Clinical trainee","Researcher, established",
      "Leadership","Pharmacist","Practitioner"]
cov=[75,69,68,62,62,51,38]
fig,ax=plt.subplots(figsize=(6.6,2.7))
y=range(len(prof))
ax.barh(list(y),cov,color=[TEAL if v>=65 else AMBER if v>=50 else RED for v in cov],height=.6)
ax.set_yticks(list(y)); ax.set_yticklabels(prof,fontsize=8.5); ax.invert_yaxis()
ax.set_xlabel("share of records sitting in titles a person has read  (%)")
for i,v in enumerate(cov): ax.text(v+1,i,f"{v}%",va="center",fontsize=8.5,color=INK)
ax.set_xlim(0,100); ax.grid(axis="x",color=RULE,lw=.6,alpha=.7); ax.set_axisbelow(True)
save(fig,"coverage")

# --- 3. the pipeline, as a simple flow ------------------------------------
fig,ax=plt.subplots(figsize=(6.8,1.75)); ax.axis("off")
steps=[("What the\nperson typed","#eceded",INK),("Cleaned up","#eceded",INK),
       ("Turned into\nmeaning","#dfece9",TEAL),("Matched to\nexamples","#dfece9",TEAL),
       ("Given a\nprofession","#f3e3ea",PLUM),("Scored per\naudience","#f5ecd9",AMBER)]
x=0.0; w=1.62; gap=0.24
for i,(lab,fc,tc) in enumerate(steps):
    ax.add_patch(Rectangle((x,0),w,1,facecolor=fc,edgecolor=RULE,lw=.8))
    ax.text(x+w/2,.5,lab,ha="center",va="center",fontsize=7.6,color=tc)
    if i<len(steps)-1:
        ax.add_patch(FancyArrowPatch((x+w+.04,.5),(x+w+gap-.04,.5),
            arrowstyle="-|>",mutation_scale=9,color=MUT,lw=.9))
    x+=w+gap
ax.set_xlim(-.1,x); ax.set_ylim(-.15,1.15)
ax.text(0,-.1,"runs ONCE for each different job title  —  not once per person",
        fontsize=7.5,color=MUT)
save(fig,"pipeline")

# --- 4. what each outside source can check --------------------------------
fig,ax=plt.subplots(figsize=(6.6,2.5)); ax.axis("off")
rows=["Academic career titles","Clinical specialties","Non-English titles","Who the person really is"]
cols=["Role library\n(taxonomy)","Survey answers\n(incoming)","Clinical expert\n(Bernadeta)"]
M=[[2,1,0],[0,1,2],[0,1,1],[0,2,0]]
cmap={2:(TEAL,"strong"),1:(AMBER,"partly"),0:(GREY,"no")}
cw,ch=1.55,.62
for j,c in enumerate(cols):
    ax.text(2.25+j*cw+cw/2,len(rows)*ch+.16,c,ha="center",va="bottom",fontsize=8,color=INK)
for i,r in enumerate(rows):
    yy=(len(rows)-1-i)*ch
    ax.text(2.18,yy+ch/2,r,ha="right",va="center",fontsize=8.5,color=INK)
    for j in range(len(cols)):
        col,lab=cmap[M[i][j]]
        ax.add_patch(Rectangle((2.25+j*cw,yy+.05),cw-.08,ch-.1,facecolor=col,alpha=.22,
                     edgecolor=col,lw=.9))
        ax.text(2.25+j*cw+(cw-.08)/2,yy+ch/2,lab,ha="center",va="center",fontsize=8,color=col)
ax.set_xlim(0,2.25+len(cols)*cw+.1); ax.set_ylim(-.1,len(rows)*ch+.55)
save(fig,"sources")
print("4 grafik uretildi")
