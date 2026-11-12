// Original river-gate region painting and four leaf sprays. No third-party assets or packages.
import {readFileSync,writeFileSync} from "node:fs";
import {willowLibrary,willowInk} from "./env_willow.mjs";
const cap=(n,a=0,b=1)=>Math.max(a,Math.min(b,n));
const lerp=(a,b,t)=>a+(b-a)*t;
const mix=(a,b,t)=>a.map((v,i)=>lerp(v,b[i],cap(t)));
const mul=(a,t)=>a.map(v=>v*t);
const smooth=(a,b,x)=>{let t=cap((x-a)/(b-a));return t*t*(3-2*t);};
function dice(seed){return ()=>((seed=(Math.imul(1664525,seed)+1013904223)>>>0)/4294967296);}
function grid(x,y,k){
    let h=Math.imul(x^k,374761393)+Math.imul(y,668265263);
    h=Math.imul(h^(h>>>13),1274126177);
    return ((h^(h>>>16))>>>0)/4294967295;
}
function value(x,y,scale,seed) {
    const u=x*scale,v=y*scale,i=Math.floor(u),j=Math.floor(v);
    return lerp(lerp(grid(i,j,seed),grid(i+1,j,seed),smooth(0,1,u-i)),
        lerp(grid(i,j+1,seed),grid(i+1,j+1,seed),smooth(0,1,u-i)),smooth(0,1,v-j));
}
function png(raw,width,height,channels) {
    const u32=n=>new Uint8Array([n>>>24,n>>>16,n>>>8,n]);
    function join(parts){const dst=new Uint8Array(parts.reduce((n,p)=>n+p.length,0));let o=0;for(const p of parts){dst.set(p,o);o+=p.length;}return dst;}
    function chunk(name,bytes){
        const d=join([Uint8Array.from(name,c=>c.charCodeAt(0)),bytes]);
        let n=0xffffffff;for(const v of d){n^=v;for(let j=0;j<8;j++)n=(n>>>1)^((n&1)?0xedb88320:0);}
        return join([u32(bytes.length),d,u32((n^0xffffffff)>>>0)]);
    }
    const lines=new Uint8Array(height*(width*channels+1));
    for(let y=0;y<height;y++)lines.set(raw.subarray(y*width*channels,(y+1)*width*channels),y*(width*channels+1)+1);
    const parts=[new Uint8Array([120,1])];let a=1,b=0;
    for(let o=0;o<lines.length;o+=65535){const len=Math.min(65535,lines.length-o);
        parts.push(new Uint8Array([o+len==lines.length?1:0,len&255,len>>>8,(~len)&255,((~len)>>>8)&255]),lines.subarray(o,o+len));
    }
    for(const v of lines){a=(a+v)%65521;b=(b+a)%65521;}
    parts.push(u32((b<<16)|a));
    return join([new Uint8Array([137,80,78,71,13,10,26,10]),chunk("IHDR",join([u32(width),u32(height),new Uint8Array([8,channels==4?6:2,0,0,0])])),
        chunk("IDAT",join(parts)),chunk("IEND",[])]);
}

// Trace the main road and its two crossing approaches as continuous brush ribbons.
function path_segments(roads){
    const patches=new Map();
    const key=(x,y)=>Math.floor(x/10)+"/"+Math.floor(y/10);
    for(const road of roads){const points=road.points,steps=7;
        for(let i=0;i<points.length-1;i++){
            const p=[points[Math.max(0,i-1)],points[i],points[i+1],points[Math.min(points.length-1,i+2)]];
            const at=(t,k)=>0.5*((2*p[1][k])+(-p[0][k]+p[2][k])*t+(2*p[0][k]-5*p[1][k]+4*p[2][k]-p[3][k])*t*t+(-p[0][k]+3*p[1][k]-3*p[2][k]+p[3][k])*t*t*t);
            for(let j=0;j<steps;j++){const x=at(j/steps,0),y=at(j/steps,1),dx=at((j+1)/steps,0)-x,dy=at((j+1)/steps,1)-y;
                const s={x,y,dx,dy,n:dx*dx+dy*dy,w:road.width};
                for(let gx=Math.floor((x-10)/10);gx<=Math.floor((x+dx+10)/10);gx++) for(let gy=Math.floor((y-10)/10);gy<=Math.floor((y+dy+10)/10);gy++){
                    const cell=gx+"/"+gy;if(!patches.has(cell))patches.set(cell,[]);patches.get(cell).push(s);
                }
            }
        }
    }
    return (x,y)=>{let best=99,width=0;for(const s of patches.get(key(x,y))||[]){
        const t=cap(((x-s.x)*s.dx+(y-s.y)*s.dy)/s.n),d=Math.hypot(x-s.x-t*s.dx,y-s.y-t*s.dy);
        if(d-s.w<best-width){best=d;width=s.w;}
    }return [best,width];};
}
function paintGround(plan){
    const w=512,h=336,raw=new Uint8Array(w*h*3), road=path_segments(plan.roads);
    const [left,near,right,far]=plan.bounds;
    const stems=plan.trees;
    for(let py=0;py<h;py++) for(let px=0;px<w;px++){
        const x=lerp(left,right,(px+0.5)/w),z=lerp(near,far,(py+0.5)/h);
        const broad=value(x,z,0.068,426), small=value(x+0.36*z,z,0.31,172), stroke=value(x-z*.35,z+x*.12,0.56,42);
        const bed=Math.hypot((x-8)/32,(z+35)/16),river=Math.abs(x+32);
        let c=mix([60,84,73],[108,125,88],0.24+broad*.64);
        c=mix(c,[134,139,95],smooth(0.57,0.89,small*.42+broad*.58)*0.72);
        c=mix(c,[95,120,112],(1-smooth(0.55,1.3,bed))*(0.20+0.45*broad));
        const wet=(1-smooth(5.1,14.3,river+1.8*(small-0.5)));
        c=mix(c,[47,85,72],wet*.83);
        // Fold a narrow peat margin and a broken band of sedge into the bank.
        const edgeRiver=river+.55*Math.sin(z*.48)+.67*Math.sin(z*.15)+(small-.5)*1.86;
        const moss=(1-smooth(.42,1.74,Math.abs(edgeRiver-6.6)))*(.26+.50*broad);
        const undercut=(1-smooth(.23,1.13,Math.abs(edgeRiver-5.01)))*(.36+.42*small);
        c=mix(c,[97,110,73],moss);
        c=mix(c,[58,72,58],undercut);
        c=mix(c,[86,106,90],(1-smooth(3.5,5.0,edgeRiver))*.53);
        for(const [cx,cz,rx,rz,a] of plan.fields){
            const co=Math.cos(a),si=Math.sin(a),dx=x-cx,dz=z-cz,u=(dx*co+dz*si)/rx,v=(-dx*si+dz*co)/rz;
            const e=Math.pow(Math.abs(u),4)+Math.pow(Math.abs(v),4);
            const inPlot=(1-smooth(0.69,1.19,e+0.18*(small-.5)));
            if(inPlot>0){
                const furrow=(Math.sin(v*rz*3.14+0.32*small)+1)/2;
                c=mix(c,mix([122,120,79],[153,149,101],0.20+0.45*furrow+0.23*broad),inPlot*.78);
            }
        }
        for(const [cx,cz,r] of plan.groves){
            const dx=(x-cx)/r,dz=(z-cz)/(r*.76);
            const d=dx*dx+dz*dz;
            if(d<4.4)c=mix(c,[68,88,71],(1-smooth(0.18,3.8,d+.4*(small-.5)))*0.55);
        }
        for(const [cx,cz,height,species] of stems){
            const dx=x-cx,dz=z-cz, radius=height*.46;
            if(Math.abs(dx)>radius*1.7 || Math.abs(dz)>radius*1.7)continue;
            const d=(dx*dx+dz*dz)/(radius*radius);
            const shelter=1-smooth(.15,1.92,d+.14*(small-.5));
            c=mix(c,[60,75,58],shelter*.50);
            c=mix(c,[100,91,66],(1-smooth(.015,.22,d))*.69);
            if(species===0){
                const lean=(cx<-32?1:-1)*height*.25;
                const up=((dx-lean)/(radius*1.17))**2+(dz/(radius*.90))**2;
                c=mix(c,[43,63,53],(1-smooth(.12,1.68,up))*.47);
            }
        }
        for(const [cx,cz,len,height,a] of plan.outcrops){
            const dx=x-cx,dz=z-cz,co=Math.cos(a),si=Math.sin(a);
            const u=(dx*co+dz*si)/(len*.65),v=(-dx*si+dz*co)/(height+0.81),d=u*u+v*v;
            if(d<4.6){
                c=mix(c,[91,109,91],(1-smooth(.64,4.4,d+.36*(small-.5)))*.69);
                c=mix(c,[133,139,116],(1-smooth(.40,1.34,d))*.53);
            }
        }
        const [d,wide]=road(x,z),jag=(small-.52)*1.25+(stroke-.5)*.57,edge=d-wide+jag;
        const shoulder=1-smooth(-0.65,2.45,edge), packed=1-smooth(-0.60,0.65,edge);
        const ruts=(1-smooth(.07,.40,Math.abs(d-(wide>2?1.25:.64)+0.11*(small-.5))));
        const tread=mix([128,119,98],[157,147,119],.17+.49*broad+.35*small);
        c=mix(c,[132,137,95],shoulder*.46);
        c=mix(c,mul(tread,1-.093*ruts*(.46+.54*small)),packed);
        const yard=(1-smooth(18.6,22.4,Math.abs(z)))*smooth(45,52,x)*(1-smooth(86,91,x));
        c=mix(c,mix([129,122,99],[158,146,117],broad),yard*(.83-.16*packed));
        if(x>-96&&x<-58&&Math.abs(z)<23){
            const tent=cap(Math.round((-64-x)/6.1),0,4),e=Math.hypot((x+64+tent*6.1)/2.8,(Math.abs(z)-8.2-(tent%2)*6)/3.0);
            c=mix(c,[139,129,101],(1-smooth(.5,1.29,e))*.69);
            const aisle=Math.hypot((x+69.6)/10.4,(z+18.8+.13*(x+69.6))/2.41);
            const canopy=Math.hypot((x+65.25)/2.81,(z+18.65)/1.88);
            c=mix(c,mix([122,113,90],[144,128,99],small), (1-smooth(.48,1.18,aisle+.26*(small-.5)))*.87);
            c=mix(c,[88,86,69],(1-smooth(.54,1.17,canopy))*.72);
            for(const [fx,fz] of [[-70.18,-20.62],[-82.43,19.18]]){
                const hearth=Math.hypot((x-fx)/1.22,(z-fz)/1.03);
                c=mix(c,[78,79,64],(1-smooth(.44,1.30,hearth))*.84);
            }
        }
        const tone=.97+.044*stroke+.027*(small-.44);
        const n=(py*w+px)*3;
        c.forEach((val,k)=>{raw[n+k]=Math.round(cap(val*tone,0,255));});
    }
    return png(raw,w,h,3);
}
function standLayout(plan) {
    const random=dice(7624), trees=[];
    for(const [x,z,r,h,type] of plan.groves) {
        const n=Math.max(2,Math.min(8,Math.round(r*.68)));
        for(let i=0;i<n;i++){
            const a=i*2.4+(random()-.5)*.62;
            const d=r*Math.sqrt((i+.12)/n)*.91;
            const px=x+Math.cos(a)*d,pz=z+Math.sin(a)*d;
            if(Math.abs(px+32)<4.9)continue;
            trees.push([px,pz,h*(.76+.42*random()),type,Math.floor(random()*2),random()*Math.PI*2].map(v=>Math.round(v*10000)/10000));
        }
    }
    // The mature trees are placed beside the traversable approaches. Existing
    // young floodplain willows lean towards the water; they retain their sizes.
    const clear=trees.filter(([x,z,h,k])=>k!==0 || !plan.willows.some(w=>Math.hypot(w[0]-x,w[1]-z)<5.25));
    for(const tree of clear){
        if(tree[3]===0 && Math.abs(tree[0]+32)<15){
            tree[5]=Math.round(((tree[0]<-32?0:Math.PI)+Math.sin(tree[5])*.69)*1e4)/1e4;
        }
    }
    for(const [x,z,h,variant,heading] of plan.willows)clear.push([x,z,h,0,variant,heading]);
    return clear;
}
function paintLeafSprays(){
    const size=256,raw=new Uint8Array(size*size*4),rng=dice(36022);
    function set(x,y,c,a=1){if(x<0||x>=size||y<0||y>=size||a<=0)return;
        const i=(Math.floor(y)*size+Math.floor(x))*4;
        const old=raw[i+3]/255,alpha=cap(a)+old*(1-cap(a));
        for(let k=0;k<3;k++) raw[i+k]=Math.round((c[k]*cap(a)+raw[i+k]*old*(1-cap(a)))/alpha);
        raw[i+3]=Math.round(alpha*255);
    }
    function stem(x0,y0,x1,y1,r,c){const n=Math.ceil(Math.hypot(x1-x0,y1-y0)*1.3);
        for(let j=0;j<=n;j++){const t=j/n,x=lerp(x0,x1,t),y=lerp(y0,y1,t),radius=r*(1-.42*t);
            for(let py=Math.floor(y-radius-1);py<=y+radius+1;py++)for(let px=Math.floor(x-radius-1);px<=x+radius+1;px++)
                set(px,py,c,cap(radius+.52-Math.hypot(px+.5-x,py+.5-y)));
        }
    }
    function leaf(x,y,dx,dy,width,col,lean=0){
        const len=Math.hypot(dx,dy),ux=dx/len,uy=dy/len,nx=-uy,ny=ux;
        for(let py=Math.floor(Math.max(0,Math.min(y,y+dy)-width-2));py<=Math.min(size-1,Math.max(y,y+dy)+width+2);py++){
            for(let px=Math.floor(Math.max(0,Math.min(x,x+dx)-width-2));px<=Math.min(size-1,Math.max(x,x+dx)+width+2);px++){
                const a=px+.5-x,b=py+.5-y,t=(a*ux+b*uy)/len;
                if(t<=0||t>=1)continue;
                const curve=lean*t*(1-t)*4;
                const v=a*nx+b*ny-curve;
                const w=width*Math.pow(Math.sin(Math.PI*t),.81)*(1-.28*t);
                const coverage=cap(w-Math.abs(v)+.54);
                if(coverage<=0)continue;
                const flank=v<0?.88:1.045;
                const ridge=(1-smooth(.12,.67,Math.abs(v)))*(.08+.06*(1-t));
                set(px,py,mul(col,flank+ridge+.11*t),coverage);
            }
        }
    }
    const shadow=[[45,79,62],[49,84,68],[59,84,57]],sun=[[127,149,86],[119,153,106],[160,149,86]];
    function crown(tile,willow,autumn){
        const ox=(tile%2)*128,oy=Math.floor(tile/2)*128;
        const base=[ox+63,oy+(willow?12:115)];
        const tips=willow?[[16,93],[33,114],[53,103],[72,119],[91,110],[112,89],[79,87],[45,92]]:
            [[14,64],[22,41],[40,23],[60,13],[80,20],[106,35],[114,61],[100,81],[34,81],[53,55],[73,61],[88,39]];
        const type=willow?1:autumn?2:0;
        for(let j=0;j<tips.length;j++){
            const end=[ox+tips[j][0],oy+tips[j][1]],first=[lerp(base[0],end[0],.46)+(rng()-.5)*13,lerp(base[1],end[1],.33)];
            stem(base[0],base[1],first[0],first[1],1.8,[66,77,53]);
            stem(first[0],first[1],end[0],end[1],1.15,[82,96,62]);
            for(let k=0;k<8;k++){
                const t=.19+k*.097;
                const cx=lerp(first[0],end[0],t),cy=lerp(first[1],end[1],t);
                for(let s of [-1,1]){
                    const sign=((j%2)===0?1:-1)*s;
                    const dx=sign*(willow?5.7+rng()*6:7+rng()*7)+.09*(end[0]-base[0]);
                    const dy=(willow?1:-1)*(willow?10+rng()*7:4.8+rng()*6);
                    const lit=cap(.19+.49*rng()+.24*(1-(cy-oy)/128));
                    leaf(cx,cy,dx,dy,willow?1.55+rng()*.8:2.9+rng()*1.6,mix(shadow[type],sun[type],lit),sign*0.8);
                }
            }
        }
    }
    crown(0,false,false);crown(1,true,false);crown(3,false,true);
    // Reed blade silhouettes bend in different directions around a common root.
    for(let j=0;j<43;j++){
        const x=63+(rng()-.5)*22,y=243-rng()*13;
        const heading=(rng()-.5)*1.6, length=37+rng()*59;
        const px=x+Math.sin(heading)*length,py=y-Math.cos(heading)*length;
        leaf(x,y,px-x,py-y,1.4+rng()*3.3,mix([55,83,58],[141,151,84],rng()),Math.sin(heading)*6);
        if(j%10===0){
            stem(x,y,px,py,1.0,[116,125,73]);
            leaf(px,py,Math.sin(heading)*8,-12,1.8,[157,140,81]);
        }
    }
    return png(raw,size,size,4);
}

// Broken shale, dry stems and compressed seams, painted at ankle scale. A
// transparent repeat keeps the large, nonrepeating land painting visible.
function paintTrailMarks(){
    const size=256, raw=new Uint8Array(size*size*4),random=dice(818627);
    function put(x,y,c,a){
        let i=(((y%size+size)%size)*size+(x%size+size)%size)*4;
        const old=raw[i+3]/255, next=a+old*(1-a);
        if(next<=0)return;
        for(let k=0;k<3;k++)raw[i+k]=Math.round((c[k]*a+raw[i+k]*old*(1-a))/next);
        raw[i+3]=Math.round(next*255);
    }
    function line(x0,y0,x1,y1,r,c,a){
        const dx=x1-x0,dy=y1-y0,n=dx*dx+dy*dy;
        for(let y=Math.floor(Math.min(y0,y1)-r-1);y<=Math.max(y0,y1)+r+1;y++) for(let x=Math.floor(Math.min(x0,x1)-r-1);x<=Math.max(x0,x1)+r+1;x++){
            const u=cap(((x+.5-x0)*dx+(y+.5-y0)*dy)/Math.max(n,.0001));
            const d=Math.hypot(x+.5-x0-u*dx,y+.5-y0-u*dy);
            put(x,y,c,a*cap(r+.55-d));
        }
    }
    function flake(x,y,rx,ry,angle,shade){
        const co=Math.cos(angle),si=Math.sin(angle);
        for(let j=-Math.ceil(rx+2);j<=Math.ceil(rx+2);j++)for(let k=-Math.ceil(rx+2);k<=Math.ceil(rx+2);k++){
            const u=(k*co+j*si)/rx,v=(-k*si+j*co)/ry;
            const face=Math.max(Math.abs(u)+.29*Math.abs(v),Math.abs(v)+.28*Math.abs(u),.62*(u+v));
            if(face>=1.07)continue;
            const edge=cap((1.07-face)*Math.min(rx,ry));
            const light=face>.76?(0.73+.20*(1-(u+v)*.5)):(1.01+.06*(1-v)+.036*Math.cos(u*4+v*6));
            put(Math.round(x)+k,Math.round(y)+j,mul(shade,light),edge*.78);
        }
    }
    for(let cluster=0;cluster<36;cluster++){
        const x=random()*size,y=random()*size;
        let qx=x,qy=y,a=(random()-.5)*1.6;
        for(let k=0;k<3+Math.floor(random()*5);k++){
            const ex=qx+Math.cos(a)*(3+random()*5),ey=qy+Math.sin(a)*(3+random()*5);
            line(qx,qy,ex,ey,.52+random()*.43,[83,78,62],.34);
            if(k%3==1)line(qx,qy,qx+1.1,qy-2.9,.57,[100,92,73],.26);
            qx=ex;qy=ey;a+=(random()-.5)*1.1;
        }
    }
    for(let cluster=0;cluster<30;cluster++){
        const x=random()*size,y=random()*size;
        for(let s=0;s<3+random()*5;s++){
            const rad=1.1+random()**2*5.8;
            flake(x+(random()-.5)*29,y+(random()-.5)*22,rad,rad*(.43+random()*.50),random()*Math.PI,
                mix([122,119,101],[170,162,134],random()));
        }
    }
    for(let i=0;i<108;i++){
        const x=random()*size,y=random()*size,w=2.0+random()*7.9,a=random()*Math.PI*2;
        const dx=Math.cos(a)*w,dy=Math.sin(a)*w;
        line(x+.4,y+.6,x+dx+.5,y+dy+.6,.48,[86,88,65],.30);
        line(x,y,x+dx*.52,y+dy*.50,.60,[164,151,112],.52);
        line(x+dx*.52,y+dy*.50,x+dx,y+dy-.29,.41,[182,172,133],.48);
    }
    return png(raw,size,size,4);
}

const dir=new URL("../assets/environment/",import.meta.url);
const plan=JSON.parse(readFileSync(new URL("foothills.json",dir),"utf8"));
plan.trees=standLayout(plan);
writeFileSync(new URL("stand-placements.json",dir),"[\n"+plan.trees.map(t=>"  "+JSON.stringify(t)).join(",\n")+"\n]\n");
writeFileSync(new URL("floodplain-paint.png",dir),paintGround(plan));
writeFileSync(new URL("leaf-sprays.png",dir),paintLeafSprays());
writeFileSync(new URL("trail-marks.png",dir),paintTrailMarks());

writeFileSync(new URL("bank-willows.gltf",dir),willowLibrary());
writeFileSync(new URL("willow-sprays.png",dir),png(willowInk(),512,256,4));
