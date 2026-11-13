"""Indexed surface and glTF writer for the authored river company. Coordinates are metres, +Z forward."""
import json
import math
import struct
from figure_atlas import uv

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,k): return tuple(x*k for x in a)
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a): return mul(a,1/max(1.e-12,math.sqrt(dot(a,a))))
def lerp(a,b,t): return add(a,mul(sub(b,a),t))
def smooth(t): return t*t*(3-2*t)
TAU=math.tau

class Surface:
    def __init__(self,detail=True):
        self.detail=detail
        self.positions=[]
        self.tex=[]
        self.joints=[]
        self.faces=[]
    def vertex(self,p,st,skin):
        if isinstance(skin,int): skin=(skin,skin,1.)
        a,b,w=skin
        self.tex.append(st)
        self.joints.append(((a*32+b+.5)/1024.,w))
        self.positions.append(p)
        return len(self.positions)-1
    def quad(self,a,b,c,d):
        self.faces.extend([(a,b,c),(a,c,d)])
    def grid(self,cols,rows,sample,material):
        start=len(self.positions)
        for j in range(rows+1):
            for i in range(cols+1):
                u,v=i/cols,j/rows
                p,skin=sample(u,v)
                self.vertex(p,uv(material,u,1-v),skin)
        for j in range(rows):
            for i in range(cols):
                a=start+j*(cols+1)+i
                self.quad(a,a+1,a+cols+2,a+cols+1)
    def rings(self,sections,material,bone,count=12,sculpt=None):
        def point(u,v):
            j=round(v*(len(sections)-1))
            y,rx,rz,cx,cz=sections[j]
            a=TAU*u
            p=(cx+rx*math.sin(a),y,cz+rz*math.cos(a))
            if sculpt: p=sculpt(p,a,j)
            skin=bone(p) if callable(bone) else bone
            return p,skin
        self.grid(count,len(sections)-1,point,material)
    def tube(self,points,radii,material,bone,sides=7,flatten=1):
        """Sweep a shaped cross section along a curved seam, limb, collar, or grip."""
        def point(u,v):
            j=round(v*(len(points)-1))
            axis=unit(sub(points[min(j+1,len(points)-1)],points[max(0,j-1)]))
            tangent=unit(cross((0,0,1) if abs(axis[2])<.92 else (0,1,0),axis))
            bitangent=cross(axis,tangent)
            r=radii[j]
            rx,ry=(r,r*flatten) if isinstance(r,(int,float)) else r
            a=TAU*u
            p=add(points[j],add(mul(tangent,rx*math.cos(a)),mul(bitangent,ry*math.sin(a))))
            return p,bone(p) if callable(bone) else bone
        self.grid(sides,len(points)-1,point,material)
    def oval(self,c,rad,material,bone,sides=10,bands=6):
        rows=[]
        for j in range(bands+1):
            a=-math.pi/2+math.pi*j/bands
            rows.append((c[1]+rad[1]*math.sin(a),max(.0001,rad[0]*math.cos(a)),max(.0001,rad[2]*math.cos(a)),c[0],c[2]))
        self.rings(rows,material,bone,sides)
    def panel(self,points,material,bone):
        ids=[self.vertex(p,uv(material,*st),bone) for p,st in zip(points,[(0,1),(1,1),(1,0),(0,0)])]
        self.quad(*ids)
    def ribbon(self,points,width,material,bone):
        def edge(u,v):
            j=round(v*(len(points)-1))
            p=points[j]
            return (p[0]+(u-.5)*width,p[1],p[2]),bone
        self.grid(1,len(points)-1,edge,material)
    def normals(self):
        # Smooth the UV seam, while preserving deliberately modelled edges on separate panels.
        sums={}
        for a,b,c in self.faces:
            n=cross(sub(self.positions[b],self.positions[a]),sub(self.positions[c],self.positions[a]))
            for i in (a,b,c):
                key=tuple(round(x,5) for x in self.positions[i])
                sums[key]=add(sums.get(key,(0.,0.,0.)),n)
        return [unit(sums.get(tuple(round(x,5) for x in p),(0,1,0))) for p in self.positions]

class Library:
    def __init__(self):
        self.data=bytearray()
        self.doc={"asset":{"version":"2.0","generator":"Luanshi river company / tools/art"},
                  "scene":0,"scenes":[{"nodes":[]}],"nodes":[],"meshes":[],"bufferViews":[],"accessors":[]}
    def accessor(self,values,fmt,width,limits=False):
        gl=self.doc
        while len(self.data)%4: self.data.append(0)
        pos=len(self.data)
        pack=struct.Struct("<"+fmt*width).pack
        for value in values: self.data.extend(pack(*value))
        view=len(gl["bufferViews"])
        gl["bufferViews"].append({"buffer":0,"byteOffset":pos,"byteLength":len(self.data)-pos})
        idx=len(gl["accessors"])
        desc={"bufferView":view,"componentType":5126 if fmt=="f" else 5123,"count":len(values),
              "type":{1:"SCALAR",2:"VEC2",3:"VEC3"}[width]}
        if limits:
            desc.update(min=list(map(min,zip(*values))),max=list(map(max,zip(*values))))
        gl["accessors"].append(desc)
        return idx
    def insert(self,name,s,check_tiles=True):
        assert 0<len(s.positions)<65536, name
        # Every face samples a single padded atlas tile, even across a sewn seam.
        if check_tiles:
            tiles=[(int(u*8),int(v*4)) for u,v in s.tex]
            for a,b,c in s.faces:
                if tiles[a]!=tiles[b] or tiles[a]!=tiles[c]:
                    raise ValueError(f"{name}: face {a,b,c} bridges atlas tiles {tiles[a],tiles[b],tiles[c]}")
        acc=self.accessor
        attr={"POSITION":acc(s.positions,"f",3,True),"NORMAL":acc(s.normals(),"f",3),
              "TEXCOORD_0":acc(s.tex,"f",2),"TEXCOORD_1":acc(s.joints,"f",2)}
        index=acc([(v,) for f in s.faces for v in f],"H",1)
        i=len(self.doc["meshes"])
        self.doc["meshes"].append({"name":name,"primitives":[{"attributes":attr,"indices":index}]})
        self.doc["nodes"].append({"mesh":i,"name":name})
        self.doc["scenes"][0]["nodes"].append(i)
    def save(self,path):
        self.doc["buffers"]=[{"byteLength":len(self.data)}]
        desc=bytearray(json.dumps(self.doc,separators=(",",":")).encode())
        while len(desc)%4: desc.append(32)
        while len(self.data)%4: self.data.append(0)
        path.write_bytes(struct.pack("<4sII",b"glTF",2,28+len(desc)+len(self.data))
                         +struct.pack("<I4s",len(desc),b"JSON")+desc
                         +struct.pack("<I4s",len(self.data),b"BIN\0")+self.data)
