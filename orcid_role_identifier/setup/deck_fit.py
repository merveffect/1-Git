import math, os, sys
from pptx import Presentation
from pptx.util import Emu

def flags(path, label):
    pr = Presentation(path); out = []
    for i, s in enumerate(pr.slides, 1):
        for sh in s.shapes:
            if not sh.has_text_frame: continue
            tf = sh.text_frame
            pt = None
            for p in tf.paragraphs:
                for r in p.runs:
                    if r.font.size: pt = r.font.size.pt; break
                if pt: break
            pt = pt or 11.0
            w, h = Emu(sh.width).inches, Emu(sh.height).inches
            lines = [p.text for p in tf.paragraphs]
            if not " ".join(lines).strip(): continue
            cpl = max(1, int(w * 72 / (pt * 0.50)))
            n = sum(max(1, math.ceil(len(l) / cpl)) for l in lines)
            want = n * pt * 1.22 / 72
            if want > h + 0.06:
                out.append((i, round(Emu(sh.left).inches,2), round(Emu(sh.top).inches,2),
                            round(want,2), round(h,2), len(" ".join(lines)), " ".join(lines)[:70]))
    print(f"{label}: {len(out)} flags")
    return out

HERE = os.path.dirname(os.path.abspath(__file__))
old = flags(os.path.join(HERE, "deck_october_source.pptx"), "ORIGINAL")
new = flags(sys.argv[1] if len(sys.argv)>1 else
            os.path.join(HERE, "..", "docs", "Role-Pipeline-Walkthrough.pptx"), "EDITED  ")
okpos = {(i,l,t) for i,l,t,*_ in old}
print("\n--- NEW overflow that the original did not have ---")
for row in new:
    if (row[0],row[1],row[2]) not in okpos:
        print(f"  s{row[0]:<3} L={row[1]:<6} T={row[2]:<6} wants {row[3]} vs {row[4]}  {row[5]} chars")
        print(f"       {row[6]!r}")
