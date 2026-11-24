#!/usr/bin/env python3
"""Bosspunkte von Naowh Forever auf unsere Dungeonkarten legen (1.0.8.21).

Naowh Forever (NaowhForever_DungeonJournal/Data/Maps.lua, "all rights
reserved") zeichnet je Boss einen Punkt auf eigene Kartenbilder. Wir
uebernehmen - wie bei Dropchancen und Haendlern - NUR DIE TATSACHE, wo ein
Boss steht, nie Code oder Bilder. Damit ein Punkt auf UNSEREM Bild an der
richtigen Stelle sitzt, wird jedes Naowh-Bild per Bildabgleich (OpenCV
findTransformECC, affin) auf jede Ebene derselben Instanz gelegt: die beste
Uebereinstimmung bestimmt die Ebene, ihre Abbildung rechnet den Punkt um.
Unsere Ebenen: klassische Instanzen aus den Kacheln des Clients (ueber
wago.tools /api/casc/<Datei>), gezeichnete aus media/dungeonmaps.

Aufruf (S = Arbeitsordner mit tiles/<Datei>.blp, fmaps/<Karte>.png,
nfmaps.tsv aus dump_naowh_maps.lua und infoupd/x/NaowhForever_DungeonJournal):
    python3 -I .github/scripts/register_naowh_maps.py S <Repo>
schreibt S/nfpins.json (je Punkt: Instanz, Ebene, x, y, Uebereinstimmung cc).
Braucht numpy, pillow, opencv-python-headless.
"""
import sys, re, os, json, collections
import numpy as np, cv2
from PIL import Image
S = sys.argv[1]                     # scratchpad
REPO = sys.argv[2]
NF = os.path.join(S, "infoupd/x/NaowhForever_DungeonJournal/Media/Maps")
INST = {"AlcazPrison":2994,"BlackfathomDeeps":48,"BlackmawHold":2974,"BlackrockDepths":230,"Dalaran":2959,"Deadmines":36,
 "DireMaul":429,"DrownedCity":2970,"ExcavationSite":2998,"Gnomeregan":90,"HallOfThanes":3065,"Kroldok":3039,
 "LowerBlackrockSpire":229,"Maraudon":349,"RagefireChasm":389,"RazorfenDowns":129,"RazorfenKraul":47,"RuinsOfLordaeron":2999,
 "ScarletMonasteryArmory":189,"ScarletMonasteryCathedral":189,"ScarletMonasteryGraveyard":189,"ScarletMonasteryLibrary":189,
 "Scholomance":289,"ShadowfangKeep":33,"ShapersTerrace":3001,"Stockade":34,"Stratholme":329,"SunkenTemple":109,"Uldaman":70,
 "UpperBlackrockSpire":229,"WailingCaverns":43,"ZulFarrak":209}
DRAWN = {2959:["2959","2959_2"],2998:["2998"],2999:["2999"],3065:["3065"],2970:["2970","2970_2"],3039:["3039"],
 2994:["2994","2994_2"],2974:["2974"]+["2974_%d"%i for i in range(2,7)],3001:["3001","3001_2"]}
# our classic floors
src = open(os.path.join(REPO,"data/dungeonmaps.lua"),encoding="utf-8").read()
ours = collections.defaultdict(list); inst=None
for line in src.splitlines():
    m = re.match(r'\s*\[(\d+)\]\s*=\s*\{\s*name\s*=', line)
    if m: inst=int(m.group(1)); continue
    m = re.search(r'tiles\s*=\s*\{([\d,\s]+)\}', line)
    if m and inst: ours[inst].append([int(x) for x in m.group(1).replace(" ","").split(",") if x])
def classic(tiles):
    im = Image.new("RGB",(1024,768))
    for i,t in enumerate(tiles):
        p = os.path.join(S,"tiles/%d.blp"%t)
        im.paste(Image.open(p).convert("RGB"), ((i%4)*256,(i//4)*256))
    return im.crop((0,0,1002,668))
def our_floors(i):
    if i in DRAWN: return [Image.open(os.path.join(S,"fmaps/%s.png"%k)).convert("RGB") for k in DRAWN[i]]
    return [classic(t) for t in ours[i]]
# naowh map data
maps = {}; pins = collections.defaultdict(list); imgs = collections.defaultdict(dict)
for line in open(os.path.join(S,"nfmaps.tsv"),encoding="utf-8"):
    p=line.rstrip("\n").split("\t")
    if p[0]=="M": maps[p[1]]=(p[2],int(p[3]),float(p[4]) if p[4] else 683/1024)
    elif p[0]=="I": imgs[p[1]][int(p[2])]=p[3]
    elif p[0]=="P": pins[p[1]].append((int(p[2]),int(p[3]),float(p[4]),float(p[5])))
def nf_img(key,f):
    base,n,bottom = maps[key]
    path = imgs[key].get(f) or (base+str(f) if f>1 else base)
    fn = os.path.join(NF, path.split("\\")[-1]+".blp")
    if not os.path.exists(fn): return None
    im = Image.open(fn).convert("RGB")
    return im.crop((0,0,im.width,int(round(im.height*bottom))))
W=320
def gray(im, w, h):
    a = np.asarray(im.resize((w,h), Image.LANCZOS).convert("L"), dtype=np.float32)/255.0
    return cv2.GaussianBlur(a,(5,5),0)
cache={}
out=[]
for key,(base,n,bottom) in sorted(maps.items()):
    if key not in INST: continue
    i=INST[key]
    if i not in cache: cache[i]=our_floors(i)
    for f in range(1,n+1):
        nim = nf_img(key,f)
        if nim is None: print("kein Bild",key,f); continue
        best=None
        for oi,oim in enumerate(cache[i]):
            h = int(W*oim.height/oim.width)
            T = gray(oim,W,h); I = gray(nim,W,h)
            warp = np.eye(2,3,dtype=np.float32)
            try:
                cc, warp = cv2.findTransformECC(T, I, warp, cv2.MOTION_AFFINE,
                    (cv2.TERM_CRITERIA_EPS|cv2.TERM_CRITERIA_COUNT, 300, 1e-6), None, 5)
            except cv2.error:
                cc = -1
            if best is None or cc>best[0]: best=(cc,oi+1,warp.copy(),W,h)
        cc,of,warp,w,h = best
        inv = cv2.invertAffineTransform(warp)
        for npc,pf,x,y in pins[key]:
            if pf!=f: continue
            px,py = x*w, y*h
            ox = inv[0,0]*px+inv[0,1]*py+inv[0,2]; oy = inv[1,0]*px+inv[1,1]*py+inv[1,2]
            out.append(dict(key=key,inst=i,nf_floor=f,floor=of,cc=round(float(cc),3),npc=npc,x=round(float(ox/w),4),y=round(float(oy/h),4),nx=x,ny=y))
        print(key,"Ebene",f,"-> unsere",of,"cc",round(float(cc),3),"Skalierung",np.round(warp[:, :2].diagonal(),3),"Versatz",np.round(warp[:,2]/[w,h],3))
json.dump(out,open(os.path.join(S,"nfpins.json"),"w"),indent=0)
