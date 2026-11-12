"""Original river garrison material studies. Output is a padded, mip-safe 4x4 atlas.

Albedo contains colour and construction marks only. Its companion stores roughness,
metal fraction and dyed-cloth coverage in RGB. The shader supplies the two liveries.
"""
from math import cos, pi, sin
from random import Random
from PIL import Image, ImageDraw, ImageFilter

TILE = 128
PAD = 4
NAMES = ["linen", "dyed", "leather", "lamellar", "iron", "edge", "brass", "timber",
         "skin", "hair", "lining", "quilt", "boots", "shield", "binding", "felt"]
SURFACES = [
    ((173,151,118), (230,0,0)), ((180,164,134), (222,0,240)),
    ((92,60,43), (158,0,0)), ((103,104,91),(139,170,0)),
    ((97,105,106),(113,200,0)), ((180,186,175),(81,219,0)),
    ((159,127,77),(114,180,0)), ((132,92,58),(171,0,0)),
    ((186,134,103),(172,0,0)), ((56,46,39),(170,0,0)),
    ((213,194,154),(215,0,0)), ((147,129,102),(230,0,195)),
    ((67,51,42),(168,0,0)), ((124,77,49),(165,17,66)),
    ((128,94,66),(189,0,0)), ((86,89,82),(235,0,30)),
]

def adjusted(rgb, variation):
    return tuple(max(0,min(255,int(c+variation))) for c in rgb)

def uv(name, u, v):
    i = NAMES.index(name)
    return ((i%4*TILE+PAD+u*(TILE-2*PAD))/(4*TILE),
            (i//4*TILE+PAD+v*(TILE-2*PAD))/(4*TILE))

def make_atlas(out):
    albedo = Image.new("RGB",(TILE*4,TILE*4))
    response = Image.new("RGB",albedo.size)
    for index,name in enumerate(NAMES):
        base,pbr = SURFACES[index]
        rng = Random(61112+index)
        tile = Image.new("RGB",(TILE,TILE))
        mask = tile.copy()
        pix, m = tile.load(),mask.load()
        for y in range(TILE):
            for x in range(TILE):
                fleck = rng.uniform(-3,3)
                if name in ("linen","dyed","lining","quilt","felt"):
                    h = (x%3==0)*4 - (y%4==0)*6 + 2*sin(y*.07+x*.04)
                elif name in ("leather","boots","binding","shield"):
                    h = 4*sin(x*.11+sin(y*.09)*1.1)+2*sin(y*.21)+fleck
                elif name=="timber":
                    h = 7*sin(x*.32+1.4*sin(y*.08))+4*sin(x*.15+.16*y)
                elif name=="hair":
                    h = 6*sin(x*.64+sin(y*.057))
                elif name=="skin":
                    h = 2*cos(y*.04)-abs(x-64)*.026
                else:
                    h = 3*sin(x*.2+sin(y*.13))
                pix[x,y]=adjusted(base,h+fleck)
                m[x,y]=(max(0,min(255,int(pbr[0]+fleck*2))),pbr[1],pbr[2])
        pen,rough=ImageDraw.Draw(tile),ImageDraw.Draw(mask)
        if name=="lamellar":
            # Offset rows. Two cord holes, folded iron edge and a paired hide lace per scale.
            for row,y in enumerate(range(-20,TILE+20,24)):
                for x in range(-26+(row%2)*10,TILE+22,21):
                    pen.rounded_rectangle((x+1,y,x+20,y+26),radius=5,fill=adjusted(base,rng.uniform(-10,11)),outline=(63,65,58),width=2)
                    pen.line((x+3,y+20,x+6,y+23,x+16,y+23,x+18,y+20),fill=(147,143,117))
                    for hx in (x+6,x+14):
                        pen.ellipse((hx-2,y+4,hx+2,y+8), fill=(52,45,35))
                        pen.line((hx,y+6,hx+2,y+11),fill=(162,116,70),width=2)
                        rough.line((hx,y+6,hx+2,y+11),fill=(188,5,0),width=3)
        if name=="quilt":
            for x in range(0,TILE,15):
                pen.line((x,0,x,TILE),fill=(110,99,80),width=2)
                for y in range(1,TILE,7):
                    pen.line((x+2,y,x+2,y+3),fill=(179,160,126))
        if name in ("leather","binding","boots"):
            for _ in range(36):
                x,y=rng.randrange(TILE),rng.randrange(TILE)
                pen.line((x,y,x+rng.randrange(2,13),y+rng.randrange(-3,4)),fill=adjusted(base,rng.randrange(-15,15)))
        if name in ("iron","edge","brass"):
            for _ in range(26):
                x,y=rng.randrange(TILE),rng.randrange(TILE)
                pen.line((x,y,x+2,y+rng.randrange(6,32)),fill=adjusted(base,rng.randrange(2,16)))
        if name=="shield":
            for x in range(0,TILE,24):
                pen.line((x,0,x,TILE),fill=(76,53,39),width=2)
                pen.line((x+2,0,x+2,TILE),fill=(148,101,67))
        # Replicate edge texels so the neighbouring material cannot bleed into the seam.
        for src,atlas in ((tile,albedo),(mask,response)):
            ox,oy=index%4*TILE,index//4*TILE
            inner=src.crop((PAD,PAD,TILE-PAD,TILE-PAD))
            padded=inner.resize((TILE,TILE))
            padded.paste(inner,(PAD,PAD))
            for i in range(PAD):
                padded.paste(inner.crop((0,0,1,inner.height)),(i,PAD))
                padded.paste(inner.crop((inner.width-1,0,inner.width,inner.height)),(TILE-1-i,PAD))
                padded.paste(padded.crop((0,PAD,TILE,PAD+1)),(0,i))
                padded.paste(padded.crop((0,TILE-PAD-1,TILE,TILE-PAD)),(0,TILE-1-i))
            atlas.paste(padded,(ox,oy))
    albedo.save(out/"cloth_and_iron.png",optimize=True)
    response.save(out/"surface_response.png",optimize=True)
