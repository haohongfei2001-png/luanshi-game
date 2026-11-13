// Build the original river-gate prop meshes and material masks. No packages required.
import {mkdirSync,readFileSync,writeFileSync} from "node:fs";
import {fileURLToPath} from "node:url";

// Original river-gate material masks. All sampling and paint strokes wrap at the edge.
const W = 128;
const TAU = Math.PI * 2;
const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));
const byte = n => Math.round(clamp(n, 0, 255));
const mix = (a, b, t) => a + (b - a) * t;
const wrap = (a, n) => ((a % n) + n) % n;

function random(seed) {
    return () => {
        seed = (Math.imul(1664525, seed) + 1013904223) >>> 0;
        return seed / 4294967296;
    };
}

function pool(side, rng) {
    const a = Array.from({length: side * side}, rng);
    return (x, y) => {
        const u = x * side / W, v = y * side / W;
        const smooth = t => t * t * (3 - 2 * t);
        const sx = smooth(u - Math.floor(u)), sy = smooth(v - Math.floor(v));
        const get = (i, j) => a[wrap(Math.floor(v) + j, side) * side + wrap(Math.floor(u) + i, side)];
        return mix(mix(get(0, 0), get(1, 0), sx), mix(get(0, 1), get(1, 1), sx), sy);
    };
}

function materials() {
    const rng = random(724811);
    const broad = pool(5, rng), broken = pool(13, rng), fine = pool(34, rng);
    const land = new Uint8Array(W * W * 3), works = new Uint8Array(land.length);
    const index = (x, y, c) => (wrap(y, W) * W + wrap(x, W)) * 3 + c;
    for (let y = 0; y < W; y++) {
        for (let x = 0; x < W; x++) {
            const grit = rng() - 0.5, fleck = fine(x, y) - 0.5, patch = broad(x, y);
            const n = index(x, y, 0);
            land[n] = byte(136 + 65 * grit + 53 * fleck + 42 * (broken(x, y) - 0.5));
            land[n+1] = byte(45 + 74 * patch + 38 * fleck);
            land[n+2] = byte(82 + 40 * grit + 44 * patch + 29 * fleck);
            // Shakes and growth lines flow around the knots, along the long grain.
            let knot = 0;
            for (const [kx, ky] of [[32, 43], [89, 96], [108, 15]]) {
                const dx = Math.abs(wrap(x-kx+64, W)-64) * 0.58;
                const dy = Math.abs(wrap(y-ky+64, W)-64) * 1.8;
                const r = Math.hypot(dx, dy);
                if (r < 19) knot += (1-r/19) * Math.sin(r*1.02) * 28;
            }
            const growth = Math.sin(TAU*(y / W * 14 + 0.75*broad(x, y) + 0.22*broken(x, y)));
            works[n] = byte(140 + growth*22 + knot + 25*fleck + 22*grit);
            // Hand-set staggered courses, chipped edges and shallow mortar recesses.
            const cy = wrap(y + (broken(x, y)-0.5)*3.8, W) / 16;
            const row = Math.floor(cy);
            const u = (x + (row % 2) * 17 + (fine(x, y)-0.5)*3.1) / 32;
            const edge = Math.min(Math.min(cy-row, 1-cy+row)*16,
                                  Math.min(u-Math.floor(u), 1-u+Math.floor(u))*32);
            const stone = (Math.sin(wrap(Math.floor(u), 4)*45.6 + row*22.1)*0.5+0.5);
            works[n+1] = byte(mix(54, 127+stone*41, clamp((edge-0.04)/1.30, 0, 1))
                                 + 24*fleck + 18*grit + 13*(broken(x,y)-0.5));
            // Linen and cord threads share this relief channel at different scales.
            const pick = (Math.floor(x/3)+Math.floor(y/3))%2;
            const thread = pick ? Math.cos(TAU*x/4) : Math.cos(TAU*y/4);
            works[n+2] = byte(136 + thread*25 + 26*fleck + 20*(patch-0.5) + 18*grit);
        }
    }
    function mark(x, y, c, value, opacity) {
        const n = index(Math.round(x), Math.round(y), c);
        land[n] = byte(mix(land[n], value, opacity));
    }
    // Pebbles sit in the silt: shade at one edge, a pale face, broken outlines.
    for (let i=0; i<390; i++) {
        const x=rng()*W, y=rng()*W, a=0.55+rng()**3*3.6, b=a*(0.42+rng()*0.47);
        const roll=rng()*TAU, co=Math.cos(roll), si=Math.sin(roll);
        for (let j=-Math.ceil(a); j<=Math.ceil(a); j++) {
            for (let k=-Math.ceil(a); k<=Math.ceil(a); k++) {
                const u=(co*k+si*j)/a, v=(co*j-si*k)/b, h=u*u+v*v;
                if (h<1) {
                    mark(x+k, y+j, 2, 156+58*Math.sqrt(1-h)-22*(u+v), 0.86);
                    mark(x+k+1, y+j+1, 0, h>0.62?91:165, 0.57);
                }
            }
        }
    }
    // Dry sedge and broken turf, laid in sparse clumps instead of isotropic noise.
    for (let i=0; i<390; i++) {
        const x=rng()*W, y=rng()*W, hue=127+105*rng();
        for (let blade=0; blade<3+Math.floor(rng()*4); blade++) {
            const direction=-2.40+rng()*2.4, length=1.5+rng()**2*7;
            const dx=Math.cos(direction)*length, dy=Math.sin(direction)*length;
            for (let s=0; s<=length; s++) {
                const t=s/length;
                mark(x+t*dx+t*t*1.2, y+t*dy, 1, hue, (1-t*0.58)*0.83);
            }
        }
    }
    return {"fieldbed.png":land, "joinery.png":works};
}
const plus = (a,b) => a.map((v,i)=>v+b[i]);
const minus = (a,b) => a.map((v,i)=>v-b[i]);
const mul = (a,t) => a.map(v=>v*t);
const cross = (a,b) => [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const dot = (a,b) => a.reduce((s,x,i)=>s+x*b[i],0);
const unit = a => mul(a,1/Math.max(1e-6,Math.hypot(...a)));
const srgb = n => n<=0.04045 ? n/12.92 : ((n+0.055)/1.055)**2.4;
const paint = hex => [0,2,4].map(s=>srgb(parseInt(hex.slice(s,s+2),16)/255));
const wood=paint("876a4e"), worn=paint("ab906b"), bark=paint("685444"), iron=paint("5a6261"),
      cord=paint("a08a66"), hide=paint("806955"), darkHide=paint("635246"), sack=paint("aca183");

class Joinery {
    constructor(name) {
        this.name=name;
        this.verts=[];
        this.lookup=new Map();
        this.indices=[[],[]];
    }
    vertex(p,n,c) {
        // Quantize before packing. Small libm differences between JS engines must not
        // create different glTF bytes for the same authored joint.
        const rounded=k=>Math.round(k*1000000)/1000000 || 0;
        const value=[...p.map(rounded),...n.map(rounded),...c];
        const key=value.map(k=>Math.round(k*100000)).join("/");
        if (!this.lookup.has(key)) {
            this.lookup.set(key,this.verts.length);
            this.verts.push(value);
        }
        return this.lookup.get(key);
    }
    face(points,col,material=0,expected=null) {
        let n=unit(cross(minus(points[1],points[0]),minus(points[2],points[0])));
        if (expected && dot(n,expected)<0) {
            points=points.slice().reverse();
            n=mul(n,-1);
        }
        const ids=points.map(p=>this.vertex(p,n,col));
        for (let i=1;i+1<ids.length;i++) this.indices[material].push(ids[0],ids[i],ids[i+1]);
    }
    block(p,size,col,mat=0) {
        const corners=[];
        for(let z of [-1,1]) for(let y of [-1,1]) for(let x of [-1,1])
            corners.push(plus(p,[size[0]*x/2,size[1]*y/2,size[2]*z/2]));
        for(let f of [[0,1,3,2],[4,5,7,6],[0,1,5,4],[2,3,7,6],[0,2,6,4],[1,3,7,5]]) {
            const face=f.map(i=>corners[i]);
            this.face(face,col,mat,minus(face[0],p));
        }
    }
    rod(a,b,r1,r2,col,sides=7,mat=0) {
        const axis=unit(minus(b,a)), side=unit(cross(axis,Math.abs(axis[1])<0.85?[0,1,0]:[0,0,1]));
        const up=cross(axis,side);
        const rim=[...Array(sides)].map((_,i)=>plus(mul(side,Math.cos(i*TAU/sides)),mul(up,Math.sin(i*TAU/sides))));
        const lower=rim.map(d=>plus(a,mul(d,r1))), upper=rim.map(d=>plus(b,mul(d,r2)));
        for(let i=0;i<sides;i++){
            const j=(i+1)%sides;
            this.face([lower[i],lower[j],upper[j],upper[i]],col,mat,plus(rim[i],rim[j]));
        }
        this.face(lower,col,mat,mul(axis,-1));
        this.face(upper,col,mat,axis);
    }
    hoop(p,r,rim,width,col,mat) {
        const n=20;
        const at=(i,rad,z)=>plus(p,[Math.cos(i*TAU/n)*rad,Math.sin(i*TAU/n)*rad,z]);
        for(let i=0;i<n;i++){
            const f=i+1, normal=[Math.cos((i+0.5)*TAU/n),Math.sin((i+0.5)*TAU/n),0];
            for(let [rad,sign] of [[r,1],[r-rim,-1]])
                this.face([at(i,rad,-width),at(f,rad,-width),at(f,rad,width),at(i,rad,width)],col,mat,mul(normal,sign));
            for(let z of [-width,width])
                this.face([at(i,r-rim,z),at(f,r-rim,z),at(f,r,z),at(i,r,z)],col,mat,[0,0,z]);
        }
    }
    wheel(x,y,z,r,spokes=10) {
        const p=[x,y,z];
        this.hoop(p,r-0.014,r*0.17,0.058,wood,0);
        this.hoop(p,r,0.021,0.061,iron,1);
        for(let i=0;i<spokes;i++) {
            const d=[Math.cos(i*TAU/spokes),Math.sin(i*TAU/spokes),0];
            this.rod(plus(p,mul(d,r*0.21)),plus(p,mul(d,r*0.88)),r*0.058,r*0.038,worn,4);
        }
        this.rod(plus(p,[0,0,-0.102]),plus(p,[0,0,0.102]),r*0.22,r*0.22,bark,10);
        this.rod(plus(p,[0,0,-0.119]),plus(p,[0,0,0.119]),r*0.088,r*0.088,iron,8,1);
    }
    bundle(p,s,col) {
        const levels=[[-1,0.50],[-0.72,0.87],[-0.18,1],[0.52,0.91],[1,0.44]], sides=8;
        const rings=levels.map(([y,r])=>Array.from({length:sides},(_,i)=>
            plus(p,[Math.cos(i*TAU/sides)*r*s[0],y*s[1],Math.sin(i*TAU/sides)*r*s[2]])));
        for(let n=1;n<rings.length;n++) for(let i=0;i<sides;i++){
            const j=(i+1)%sides;
            this.face([rings[n-1][i],rings[n-1][j],rings[n][j],rings[n][i]],col,0,minus(rings[n][i],p));
        }
        this.face(rings[0],col,0,[0,-1,0]);
        this.face(rings.at(-1),col,0,[0,1,0]);
        this.rod(plus(p,[-s[0]*0.36,s[1],0]),plus(p,[s[0]*0.36,s[1],0]),0.024,0.024,cord,4);
    }
}

function carriage() {
    const frame=new Joinery("Carriage"), beam=new Joinery("SuspendedBeam");
    for(const x of [-1.25,1.22]){
        frame.rod([x,0.48,-0.86],[x,0.48,0.86],0.084,0.084,bark,8);
        for(const z of [-0.82,0.82]) frame.wheel(x,0.49,z,0.48);
    }
    for (let side of [-1,1]) {
        const z=0.58*side;
        frame.block([0,0.70,z],[3.58,0.20,0.18],wood);
        for(const x of [-1.13,1.12]){
            frame.rod([x,0.74,z],[x,2.02,0.25*side],0.101,0.084,wood,6);
            frame.rod([x-0.41,0.79,z],[x,1.35,z*0.76],0.062,0.065,worn,5);
            frame.rod([x+0.41,0.79,z],[x,1.35,z*0.76],0.062,0.065,worn,5);
            for(const y of [0.84,0.90]) frame.block([x,y,z],[0.22,0.032,0.21],cord);
            frame.block([x,0.68,z],[0.11,0.24,0.20],iron,1);
        }
        frame.block([0,2.01,0.22*side],[3.28,0.13,0.15],bark);
        // Slings leave the centre open and keep the operator's view through the trestles.
        for (let x of [-0.89,0.90]) {
            frame.rod([x,1.99,0.22*side],[x,1.09,0.15*side],0.036,0.034,cord);
            frame.block([x,2.005,0.22*side],[0.082,0.166,0.17],cord);
        }
    }
    for(let x of [-1.44,-0.78,-0.15,0.45,1.35]) frame.block([x,0.69,0],[0.15,0.15,1.41],bark);
    for(let x of [-1.13,1.12]) frame.block([x,2.09,0],[0.16,0.12,0.64],worn);
    // The small hide shelter is drawn back over one rear bay. Its tied, rolled
    // fore edge leaves both slings, the upper rails and the moving nose in sight.
    const oxhide=paint("836950"), weathered=paint("977b60"), roll=paint("705444");
    function awning(u,t,side) {
        const cut=.104*Math.sin(Math.PI*t);
        const x=-1.64+.98*u-cut*u;
        const arch=1.0-t*t;
        const y=1.893+.255*arch-.024*Math.sin(u*Math.PI)*t-.031*Math.sin(2*t+u)*t;
        return [x,y,side*(.012+.634*t)];
    }
    for(const side of [-1,1]){
        for(let j=0;j<4;j++){
            for(let i=0;i<3;i++){
                const u=i/3, end=(i+1)/3, a=j/4, b=(j+1)/4;
                frame.face([awning(u,a,side),awning(end,a,side),awning(end,b,side),awning(u,b,side)],
                           i===0?weathered:oxhide,0,[0,1,side]);
            }
        }
        for(let j=0;j<5;j++){
            const a=awning(1,j/5,side),b=awning(1,(j+1)/5,side);
            frame.rod(a,b,.046,.044,roll,7);
        }
        for(const t of [.18,.72]){
            const pin=awning(1,t,side);
            frame.rod(plus(pin,[.031,.038,0]),plus(pin,[-.034,-.040,0]),.013,.013,cord,5);
        }
        for(const u of [.10,.70]){
            const p=awning(u,1,side);
            frame.rod(p,[-1.14,1.31,side*.47],.014,.013,cord,6);
        }
        for(const x of [-1.13,1.12]){
            for(const shift of [-.032,.025]){
                const top=[x+shift,2.11,side*.205], low=[x+shift+.042,1.96,side*.29];
                frame.rod(top,low,.022,.021,cord,6);
            }
        }
    }
    beam.rod([-2.13,1.18,0],[1.96,1.18,0],0.167,0.20,worn,10);
    for(let x of [-1.78,-0.93,0.86,1.66]) beam.rod([x,1.18,0],[x+0.085,1.18,0],0.204,0.204,bark,10);
    beam.rod([1.88,1.18,0],[2.16,1.18,0],0.211,0.226,iron,10,1);
    beam.rod([2.16,1.18,0],[2.54,1.18,0],0.226,0.143,iron,10,1);
    return [frame,beam];
}

function baggage() {
    const cart=new Joinery("GrainCart");
    cart.rod([0,0.62,-0.83],[0,0.62,0.83],0.075,0.075,bark,8);
    for(let side of [-1,1]) {
        cart.wheel(0,0.62,side*0.87,0.61,10);
        const z=0.61*side;
        cart.block([0,0.80,z],[2.33,0.19,0.14],wood);
        cart.rod([-0.93,0.83,z],[-2.88,0.32,side*0.44],0.086,0.066,worn,6);
        for(let x of [-1.04,-0.36,0.4,1.04]) cart.rod([x,0.86,z],[x*1.05,1.48,z*1.12],0.050,0.043,worn,5);
        cart.block([0,1.08,z*1.04],[2.22,0.10,0.072],bark);
        cart.block([0,1.33,z*1.09],[2.22,0.094,0.069],wood);
    }
    for(let i=0;i<6;i++) cart.block([0,0.89,(i-2.5)*0.23],[2.30,0.085,0.221],worn);
    for(let i=0;i<3;i++) for(let j of [-1,1])
        cart.bundle([(i-1)*0.64,1.12,j*0.30],[0.37,0.21,0.31],i%2?sack:cord);
    cart.bundle([0.12,1.45,0],[0.58,0.18,0.33],sack);
    for(let x of [-0.4,0.49]) {
        cart.rod([x,1.05,-0.65],[x,1.58,-0.23],0.018,0.018,cord,5);
        cart.rod([x,1.58,-0.23],[x,1.58,0.23],0.018,0.018,cord,5);
        cart.rod([x,1.58,0.23],[x,1.03,0.65],0.018,0.018,cord,5);
    }
    return [cart];
}
function base64(bytes) {
    const chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let out="";
    for(let i=0;i<bytes.length;i+=3) {
        const n=(bytes[i]<<16)|((bytes[i+1]||0)<<8)|(bytes[i+2]||0);
        out+=chars[(n>>>18)&63]+chars[(n>>>12)&63]+(i+1<bytes.length?chars[(n>>>6)&63]:"=")+(i+2<bytes.length?chars[n&63]:"=");
    }
    return out;
}
function join(parts) {
    const a=new Uint8Array(parts.reduce((n,p)=>n+p.length,0));
    let pos=0;
    for (let part of parts) { a.set(part,pos); pos+=part.length; }
    return a;
}
function u32(n) {return new Uint8Array([n>>>24,n>>>16,n>>>8,n]);}
function png(pixels) {
    const crc=data=>{
        let crc=0xffffffff;
        for(let b of data) {
            crc^=b;
            for(let i=0;i<8;i++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);
        }
        return (crc^0xffffffff)>>>0;
    };
    const chunk=(id,body)=>{
        const content=join([Uint8Array.from(id,c=>c.charCodeAt(0)),body]);
        return join([u32(body.length),content,u32(crc(content))]);
    };
    const raw=new Uint8Array((W*3+1)*W);
    for(let y=0;y<W;y++) raw.set(pixels.slice(y*W*3,(y+1)*W*3),y*(W*3+1)+1);
    // The single uncompressed deflate block is reproducible across zlib versions.
    const n=raw.length;
    if(n>65535) throw Error("PNG needs more than one deflate block");
    let a=1,b=0;
    for (let value of raw) {a=(a+value)%65521;b=(b+a)%65521;}
    const z=join([new Uint8Array([120,1,1,n&255,n>>>8,(~n)&255,((~n)>>>8)&255]),raw,u32((b<<16)|a)]);
    return join([new Uint8Array([137,80,78,71,13,10,26,10]),chunk("IHDR",join([u32(W),u32(W),new Uint8Array([8,2,0,0,0])])),chunk("IDAT",z),chunk("IEND",[])]);
}
function gltf(shapes) {
    const doc={asset:{version:"2.0",generator:"Luanshi original river-gate workshop"},
        scene:0,scenes:[{name:"RiverGateProp",nodes:[]}],nodes:[],meshes:[],accessors:[],bufferViews:[],
        materials:[{name:"Adzed timber, hide and cord",pbrMetallicRoughness:{metallicFactor:0,roughnessFactor:0.90},doubleSided:true},
                   {name:"Oxidized iron",pbrMetallicRoughness:{metallicFactor:0.56,roughnessFactor:0.63}}]};
    const parts=[];
    let offset=0;
    function buffer(bytes,target,stride=0) {
        if(offset%4) { const pad=new Uint8Array(4-offset%4); parts.push(pad); offset+=pad.length;}
        const view={buffer:0,byteOffset:offset,byteLength:bytes.length,target};
        if(stride) view.byteStride=stride;
        doc.bufferViews.push(view); parts.push(bytes); offset+=bytes.length;
        return doc.bufferViews.length-1;
    }
    function accessor(obj) {doc.accessors.push(obj); return doc.accessors.length-1;}
    for (const shape of shapes) {
        const raw=new Uint8Array(shape.verts.length*28), v=new DataView(raw.buffer);
        const min=[Infinity,Infinity,Infinity],max=[-Infinity,-Infinity,-Infinity];
        shape.verts.forEach((vertex,i)=>{
            for(let j=0;j<6;j++) v.setFloat32(i*28+j*4,vertex[j],true);
            for(let j=0;j<3;j++) {
                raw[i*28+24+j]=byte(vertex[j+6]*255);
                min[j]=Math.min(min[j],vertex[j]); max[j]=Math.max(max[j],vertex[j]);
            }
            raw[i*28+27]=255;
        });
        const count=shape.verts.length, bufferView=buffer(raw,34962,28);
        const POSITION=accessor({bufferView,byteOffset:0,componentType:5126,count,type:"VEC3",min,max});
        const NORMAL=accessor({bufferView,byteOffset:12,componentType:5126,count,type:"VEC3"});
        const COLOR_0=accessor({bufferView,byteOffset:24,componentType:5121,normalized:true,count,type:"VEC4"});
        const primitives=[];
        shape.indices.forEach((ids,material)=>{
            if(!ids.length) return;
            const data=new Uint8Array(ids.length*2), view=new DataView(data.buffer);
            ids.forEach((index,i)=>view.setUint16(i*2,index,true));
            const indices=accessor({bufferView:buffer(data,34963),componentType:5123,count:ids.length,type:"SCALAR"});
            primitives.push({attributes:{POSITION,NORMAL,COLOR_0},indices,material});
        });
        const idx=doc.meshes.length; doc.meshes.push({name:shape.name,primitives});
        doc.nodes.push({name:shape.name,mesh:idx}); doc.scenes[0].nodes.push(idx);
    }
    const packed=join(parts);
    doc.buffers=[{byteLength:packed.length,uri:"data:application/octet-stream;base64,"+base64(packed)}];
    return JSON.stringify(doc)+"\n";
}

const out = new URL("../assets/environment/",import.meta.url);
mkdirSync(fileURLToPath(out),{recursive:true});
const ramTarget=new URL("river_ram.gltf",out);
const ramModel=gltf(carriage());
if (process.argv.includes("--check-ram")) {
    if(readFileSync(ramTarget,"utf8")!==ramModel) throw Error("Unbaked river ram");
} else if(process.argv.includes("--ram-only")) {
    writeFileSync(ramTarget,ramModel);
} else {
    for(const [name,bytes] of Object.entries(materials())) writeFileSync(new URL(name,out),png(bytes));
    writeFileSync(ramTarget,ramModel);
    writeFileSync(new URL("grain_cart.gltf",out),gltf(baggage()));
}
