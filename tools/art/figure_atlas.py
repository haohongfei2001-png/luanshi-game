"""Original river garrison material studies. Output is a padded, mip-safe material atlas.

Albedo contains colour and construction marks only. Its companion stores roughness,
metal fraction and dyed-cloth coverage in RGB. The shader supplies the two liveries.
"""
from math import cos, exp, pi, sin
from random import Random
from PIL import Image, ImageDraw, ImageFilter
from painted_company import materials

TILE = 128
PAD = 4
NAMES = ["linen", "dyed", "leather", "lamellar", "iron", "edge", "brass", "timber",
         "skin", "hair", "lining", "quilt", "boots", "shield", "binding", "felt",
         "visage", "eye", "headcloth", "mantle", "sash", "quiver", "overskirt",
         "hero_mantle", "visage_second", "visage_third", "facing", "coat", "black_iron", "iron_binding", "lames"]
SURFACES = [
    ((174,153,124), (230,0,0)), ((178,173,151), (230,0,244)),
    ((87,63,46), (219,0,0)), ((95,110,114),(143,155,0)),
    ((110,111,106),(190,130,0)), ((169,165,150),(154,169,0)),
    ((137,113,76),(181,117,0)), ((132,92,58),(171,0,0)),
    ((175,124,96),(209,0,0)), ((46,37,36),(209,0,0)),
    ((213,194,154),(215,0,0)), ((111,103,89),(230,0,72)),
    ((67,51,42),(168,0,0)), ((124,77,49),(165,17,66)),
    ((111,81,66),(206,0,0)), ((72,78,84),(235,0,22)),
    ((183,133,104),(210,0,0)), ((169,151,133),(191,0,0)),
    ((188,167,129),(242,0,0)), ((61,87,103),(237,0,159)),
    ((139,56,42),(218,0,0)), ((94,60,39),(186,0,0)), ((87,94,101),(239,0,139)),
    ((110,42,39),(235,0,0)), ((172,125,96),(210,0,0)), ((172,125,96),(210,0,0)), ((61,65,67),(236,0,70)), ((150,150,146),(238,0,248)),
    ((91,91,87),(205,96,0)), ((110,103,87),(201,73,0)), ((99,100,95),(210,83,0)),
]

def adjusted(rgb, variation):
    return tuple(max(0,min(255,int(c+variation))) for c in rgb)

def uv(name, u, v):
    i = NAMES.index(name)
    return ((i%8*TILE+PAD+u*(TILE-2*PAD))/(8*TILE),
            (i//8*TILE+PAD+v*(TILE-2*PAD))/(4*TILE))

def painted(name, base, x, y):
    u,v=(x+.5)/TILE,(y+.5)/TILE
    def blend(col, paint, amount):
        return tuple(a+(b-a)*min(1,max(0,amount)) for a,b in zip(col,paint))
    if name=="visage":
        px,py=(u-.5)*1.9,8.13-v*2.63
        a=abs(px)
        def wash(cx,cy,wx,wy):
            return exp(-((a-cx)/wx)**2-((py-cy)/wy)**2)
        col=blend(base,(128,84,73),.44*wash(.64,6.74,.23,.62)+.48*wash(.24,5.94,.45,.19))
        col=blend(col,(209,161,123),.52*wash(.45,6.81,.21,.17)+.50*wash(.04,7.36,.31,.31))
        col=blend(col,(152,97,83),.48*wash(.49,6.62,.25,.22))
        col=blend(col,(108,76,69),.62*wash(.315,7.04,.19,.092))
        col=blend(col,(62,49,43),.90*wash(.303,7.179+.081*(a-.21)-.55*(a-.27)**2,.151,.031))
        col=blend(col,(118,72,64),.64*wash(.061,6.55,.063,.047)+.72*wash(.073,6.288,.136,.045))
        col=blend(col,(219,159,117),.54*wash(0,6.73,.07,.14)+.27*wash(.074,6.19,.11,.06))
        return col
    if name=="eye":
        pupil=((u-.5)/.092)**2+((v-.5)/.215)**2
        return blend((161,145,129),(52,40,34),max(0,min(1,(1.27-pupil)*3)))
    if name in ("dyed","mantle","headcloth","sash","felt","quiver","binding","overskirt"):
        # Broad shadows can still be read when the whole sleeve measures six pixels.
        folds=cos(2*pi*(3*u+.26*v+.19*sin(2*pi*(u+v))))*.5+.5
        cavity=(folds**3)*(.68 if name in ("mantle","dyed","felt") else .30)
        value=10*(1-v)-14*v-25*cavity+8*(1-folds)**2
        col=adjusted(base,value)
        if name in ("mantle","sash","headcloth"):
            border=min(abs(v-.090),abs(v-.91))
            col=blend(col,(172,138,92),.56*exp(-(border/.012)**2))
        if name=="binding":
            seam=(v*3.5+u*.9)%1
            col=blend(col,(58,53,54),.63*exp(-((seam-.45)/.075)**2))
        return col
    return None

def make_atlas(out):
    albedo = Image.new("RGB",(TILE*8,TILE*4))
    response = Image.new("RGB",albedo.size)
    paintings=materials(TILE)
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
                paint=painted(name,base,x,y)
                pix[x,y]=adjusted(paint if paint is not None else base,h*.37+fleck*.5 if paint is not None else h+fleck)
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
        if name=="lames":
            # Overlapping rows read at battle distance. Restrict light edges to
            # the underside of each row; scattered white rivets sparkle in motion.
            for row in range(-1,5):
                y=row*31
                for col in range(-1,8):
                    x=col*24+(row%2)*12
                    value=rng.uniform(-5,6)
                    body=adjusted(base,value)
                    pen.rounded_rectangle((x,y,x+23,y+36),radius=4,fill=body)
                    pen.line((x+2,y+3,x+2,y+24),fill=adjusted(body,-12),width=2)
                    pen.line((x+1,y+26,x+4,y+29,x+21,y+29),fill=adjusted(body,-21),width=2)
                    pen.line((x+5,y+27,x+19,y+27),fill=adjusted(body,12),width=2)
                    for lx in (x+7,x+15):
                        pen.line((lx,y+5,lx+2,y+13),fill=(109,88,65),width=2)
                        rough.line((lx,y+5,lx+2,y+13),fill=(224,4,0),width=3)
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
        if name in paintings:
            tile=paintings[name]
        # Replicate edge texels so the neighbouring material cannot bleed into the seam.
        for src,atlas in ((tile,albedo),(mask,response)):
            ox,oy=index%8*TILE,index//8*TILE
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
