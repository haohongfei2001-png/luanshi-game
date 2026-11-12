"""Register the original river-company paint sheets to outfit and face UVs."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps

SOURCE=Path(__file__).with_name("source")

def _between(t,stops):
    for (a,v),(b,w) in zip(stops,stops[1:]):
        if t<=b:
            return v+(w-v)*(t-a)/(b-a)
    return stops[-1][1]

def _face(sheet,index,size):
    # Target rows are the sculpt's hairline, brow, upper lid, nostrils, lips and chin.
    width,height=sheet.size
    lane=width/3
    stops=[(0,0),(.32,.206),(.423,.328),(.603,.603),(.703,.747),(.880,.956),(1,.988)]
    patch=Image.new("RGB",(size,size))
    paint=patch.load()
    for y in range(size):
        v=(y+.5)/size
        fy=_between(v,stops)*(height-1)
        for x in range(size):
            u=(x+.5)/size
            fx=(index+min(.966,max(.034,.5+(u-.5)*1.14)))*lane
            colour=sheet.getpixel((min(width-1,round(fx)),round(fy)))
            # Turn the projection into the unpainted neck/scalp at the extreme edges.
            weight=min(1,max(0,(.47-abs(u-.5))/.105))
            paint[x,y]=tuple(round(a*(1-weight)+b*weight) for a,b in zip((168,120,92),colour))
    return patch

def _crossed_front(cloth):
    # Torso U wraps at the middle of the chest. Paint both ends of each crossing
    # seam into the same cylinder, leaving sleeves and armour free of a second lapel.
    size=cloth.width*3
    image=cloth.resize((size,size),Image.Resampling.BICUBIC)
    pen=ImageDraw.Draw(image)
    outer=[(-.215,.025),(-.152,.105),(-.087,.190),(-.024,.261),(.054,.346),(.116,.448),(.162,.567)]
    inner=[(.217,.022),(.142,.099),(.083,.172),(.023,.240),(-.007,.268)]
    for shift in (0.,1.):
        for points in (inner,outer):
            line=[((x+shift)*size,y*size) for x,y in points]
            pen.line(line,fill=(87,88,86),width=round(size*.027),joint="curve")
            pen.line([((x+shift)*size,(y+.012)*size) for x,y in points],fill=(147,142,127),width=max(1,round(size*.005)),joint="curve")
    return image.resize(cloth.size,Image.Resampling.LANCZOS)

def materials(size):
    with Image.open(SOURCE/"river_cloth_study.png") as image:
        sheet=image.convert("RGB")
    w,h=sheet.size
    def quarter(x,y):
        x0,x1=round(x*w/2)+3,round((x+1)*w/2)-3
        y0,y1=round(y*h/2)+3,round((y+1)*h/2)-3
        return sheet.crop((x0,y0,x1,y1)).resize((size,size),Image.Resampling.LANCZOS)
    cotton=ImageOps.autocontrast(ImageOps.grayscale(quarter(0,0)),cutoff=1)
    quilt=ImageOps.autocontrast(ImageOps.grayscale(quarter(1,0)),cutoff=1)
    red=quarter(1,1)
    red=red.point([min(255,round(i*1.22+5)) for i in range(256)]*3)
    # Keep the broad fold in the dye. Subpixel weave from the paint study
    # must not turn a receding sleeve into a glittering bank of threads.
    cotton=Image.blend(cotton.filter(ImageFilter.GaussianBlur(2.2)),cotton,.28)
    cloth=ImageOps.colorize(cotton,(99,98,96),(184,178,161))
    padded=ImageOps.colorize(quilt,(53,57,64),(144,137,118))
    armor=quarter(0,1)
    armor=armor.point([min(255,round(i*1.19+7)) for i in range(256)]*3)
    with Image.open(SOURCE/"river_face_study.png") as image:
        faces=image.convert("RGB")
    return {"dyed":cloth,"coat":_crossed_front(cloth),"quilt":padded,"lamellar":armor,"hero_mantle":red,
            "visage":_face(faces,0,size),"visage_second":_face(faces,1,size),"visage_third":_face(faces,2,size)}
