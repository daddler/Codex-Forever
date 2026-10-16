"""Logo der Oberflaeche aus Zahlen zeichnen (6.47.0.0).

    python3 .github/scripts/make_logo_mark.py .github/scripts/logo/wcui.png
    python3 .github/scripts/make_logo.py

Wunsch des Projektinhabers: "Mach das Logo professioneller". Ein ruhiges
Zeichen statt des Wappens: dunkle Muenze mit Goldrand, ein "W" in
Inschriftform, darueber eine Raute im WeintCodex-Lila. Liest auch bei
16-20 px. Das alte Bild liegt als logo/wcui_2026_09.png daneben.
"""
import math, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
S=2048; C=S/2
def lin(c1,c2,t): return tuple(int(c1[i]+(c2[i]-c1[i])*t) for i in range(len(c1)))
def vgrad(w,h,top,bot):
    g=Image.new('RGBA',(w,h))
    px=g.load()
    for y in range(h):
        c=lin(top,bot,y/(h-1))
        for x in range(w): px[x,y]=c
    return g
GOLD_T=(242,214,150,255); GOLD_B=(176,128,62,255)
BG_T=(34,35,44,255); BG_B=(14,15,20,255)
VIO=(124,108,255,255)
img=Image.new('RGBA',(S,S),(0,0,0,0))
# outer disc mask
R=960
def disc(r):
    m=Image.new('L',(S,S),0); ImageDraw.Draw(m).ellipse((C-r,C-r,C+r,C+r),fill=255); return m
gold=vgrad(S,S,GOLD_T,GOLD_B)
bg=vgrad(S,S,BG_T,BG_B)
img.paste(gold,(0,0),disc(R))
img.paste(lin((60,46,24,255),(60,46,24,255),0),(0,0),ImageChops.subtract(disc(R-40),disc(R-56)))
img.paste(bg,(0,0),disc(R-56))
# inner hairline ring
ring=ImageChops.subtract(disc(R-104),disc(R-112))
img.paste((176,140,80,90),(0,0),ring)
# W monogram: four slanted strokes with flat cuts (crisp, inscription-like)
m=Image.new('L',(S,S),0); d=ImageDraw.Draw(m)
w=1180; h=700; top=C-h/2+70; bot=C+h/2+70; x0=C-w/2; tw=190; mid=top+h*0.22
xs=[x0, x0+w*0.27, C, x0+w*0.73, x0+w]
def stroke(xa,ya,xb,yb,t):
    d.polygon([(xa-t/2,ya),(xa+t/2,ya),(xb+t/2,yb),(xb-t/2,yb)],fill=255)
stroke(xs[0]+tw/2,top,xs[1],bot,tw)
stroke(xs[2],mid,xs[1],bot,tw*0.82)
stroke(xs[2],mid,xs[3],bot,tw*0.82)
stroke(xs[4]-tw/2,top,xs[3],bot,tw)
# serifs at the top ends
for x in (xs[0]+tw/2, xs[4]-tw/2):
    d.rectangle((x-tw*0.95,top,x+tw*0.95,top+38),fill=255)
img.paste(gold,(0,0),m)
# diamond above (accent)
dm=Image.new('L',(S,S),0); dd=ImageDraw.Draw(dm)
cy=top-175; r=90
dd.polygon([(C,cy-r*1.35),(C+r,cy),(C,cy+r*1.35),(C-r,cy)],fill=255)
vg=vgrad(S,S,(170,158,255,255),(92,76,230,255))
img.paste(vg,(0,0),dm)
img=img.resize((512,512),Image.LANCZOS)
img.save(sys.argv[1])
