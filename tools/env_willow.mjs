// Original river willows. Knot and bough coordinates below are local metres,
// with +X towards the water. The mesh library uses standard glTF, indexed
// positions, two UV sets, vertex colours and no third-party assets.
const TAU=Math.PI*2;
const add=(a,b)=>a.map((v,i)=>v+b[i]);
const sub=(a,b)=>a.map((v,i)=>v-b[i]);
const times=(a,s)=>a.map(v=>v*s);
const blend=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const dot=(a,b)=>a.reduce((sum,v,i)=>sum+v*b[i],0);
const norm=a=>times(a,1/Math.max(1e-8,Math.hypot(...a)));
const clamp=(a,m=0,n=1)=>Math.max(m,Math.min(n,a));
const random=seed=>()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);
function bezier(a,b,c,d,t){return blend(blend(blend(a,b,t),blend(b,c,t),t),blend(blend(b,c,t),blend(c,d,t),t),t);}
function mesh(name){return {name,p:[],n:[],uv:[],tag:[],col:[],idx:[]};}
function vert(m,p,n,uv,tag,c){
    m.p.push(...p);m.n.push(...n);m.uv.push(...uv);m.tag.push(...tag);m.col.push(...c);
    return m.p.length/3-1;
}
function tri(m,i,j,k,out){
    const point=n=>m.p.slice(n*3,n*3+3);
    if(dot(cross(sub(point(j),point(i)),sub(point(k),point(i))),out)<0)m.idx.push(i,k,j);
    else m.idx.push(i,j,k);
}
function bole(m,points,radii,sides,seed){
    const grain=random(seed),profile=Array.from({length:sides},()=>.85+grain()*.28);
    const palette=Array.from({length:sides},()=>.82+grain()*.39);
    const rings=[], tangents=[];
    for(let row=0;row<points.length;row++){
        const axis=norm(sub(points[Math.min(row+1,points.length-1)],points[Math.max(0,row-1)]));
        const side=norm(cross(axis,Math.abs(axis[2])<.87?[0,0,1]:[1,0,0]));
        const back=cross(axis,side),ring=[],normals=[];
        for(let i=0;i<sides;i++){
            const a=i*TAU/sides+.065*Math.sin(row*.97+i*2.54);
            const radial=norm(add(times(side,Math.cos(a)),times(back,Math.sin(a))));
            const r=radii[row]*profile[i]*(1+.049*Math.cos(i*3.7+row));
            const dark=(row===0?.87:1)*palette[i],stain=.035*Math.sin(i*2+row*.4);
            ring.push(vert(m,add(points[row],times(radial,r)),radial,[i/sides,row*.56],[0,4.33+palette[i]*.22],
                [(0.34+stain)*dark,(.303+stain*.56)*dark,(.248+stain*.34)*dark]));
            normals.push(radial);
        }
        rings.push(ring);tangents.push(normals);
    }
    for(let row=0;row+1<rings.length;row++)for(let i=0;i<sides;i++){
        const j=(i+1)%sides,o=add(tangents[row][i],tangents[row][j]);
        tri(m,rings[row][i],rings[row][j],rings[row+1][j],o);
        tri(m,rings[row][i],rings[row+1][j],rings[row+1][i],o);
    }
}
// Each twig has a raised green shoulder, two staggered folds, and a free,
// much narrower tip. From above, its horizontal shoulder and drooping face
// are visible together. From below, gaps reveal the actual timber branches.
function spray(m,start,out,spread,fall,width,turn,tile,value){
    const axis=norm([out[0],0,out[2]]),side=[-axis[2],0,axis[0]];
    const centers=[
        start,add(add(start,times(axis,spread*.37)),[0,.27+spread*.14,0]),
        add(add(add(start,times(axis,spread*.76)),times(side,turn*.25)),[0,.19-fall*.09,0]),
        add(add(add(start,times(axis,spread*.96)),times(side,turn*.67)),[0,-fall*.49,0]),
        add(add(add(start,times(axis,spread*.88)),times(side,turn)),[0,-fall,0])
    ];
    const widths=[.24,.81,1.0,.77,.29],tValues=[0,.19,.39,.68,1],rows=tile===2?[0,1,2,4]:[0,1,2,3,4];
    const ids=[];
    for(const row of rows){
        const t=tValues[row],ring=[],facing=norm(add(times(axis,.18+t*.64),[0,1.12-t*.44,0]));
        const sections=row===4?[-1,1]:[-1,0,1];
        for(const k of sections){
            let p=add(centers[row],times(side,k*width*widths[row]));
            p=add(p,times(axis,Math.abs(k)*width*(.12+.16*t)+k*width*.12*Math.sin(row+.5+turn)));
            p[1]-=Math.abs(k)*width*(.22+.13*Math.sin(row*1.43+turn))+k*width*.14*Math.sin(row+.7+turn);
            const n=norm(add(facing,times(side,k*.29)));
            const light=value*(.85+.13*(1-t))+.047*Math.cos(k*1.67+row*.4+turn);
            ring.push(vert(m,p,n,[(tile+.023+(.954*(k+1)*.5))*.25,.015+t*.97],
                [t,2.5+light*.4],[.8,.8,.8]));
        }
        ids.push(ring);
    }
    for(let i=0;i+1<ids.length;i++){
        const n=norm(add(times(axis,.36+i*.12),[0,.88-i*.08,0])),a=ids[i],b=ids[i+1];
        if(b.length===2){
            tri(m,a[0],a[1],b[0],n);tri(m,a[1],b[1],b[0],n);tri(m,a[1],a[2],b[1],n);
        }else for(let j=0;j<2;j++){
            tri(m,a[j],a[j+1],b[j+1],n);
            tri(m,a[j],b[j+1],b[j],n);
        }
    }
}
const OLD_BOUGHS=[
    [[.57,1.92,-.14],[1.51,2.88,-.62],[2.50,3.88,-1.19],[3.76,4.12,-1.82]],
    [[.85,2.27,.03],[1.02,3.23,1.00],[.32,4.30,2.03],[-.51,4.45,2.68]],
    [[.65,2.16,-.23],[-.29,3.06,-.62],[-1.02,4.09,-1.66],[-2.10,4.11,-2.46]],
    [[1.13,2.56,-.09],[2.02,3.53,.65],[3.49,4.50,1.17],[4.42,4.22,1.86]],
    [[1.00,2.45,-.19],[1.33,3.91,-.86],[2.36,5.11,-.92],[2.92,5.22,-.53]],
    [[.84,2.25,-.06],[.37,3.48,.09],[-.24,4.67,.91],[-.85,5.01,1.48]],
    [[1.17,2.68,-.23],[1.30,3.70,-1.05],[.86,4.68,-2.00],[1.06,4.71,-2.78]]
];
const YOUNG_BOUGHS=[
    [[.12,1.25,.04],[.25,2.15,-.04],[.64,3.60,-.68],[1.37,3.93,-1.08]],
    [[.20,1.67,.09],[.40,2.58,.80],[-.37,3.32,1.51],[-.79,3.74,1.53]],
    [[.18,1.22,-.04],[-.14,2.19,-.62],[-.50,3.25,-1.20],[-1.19,3.48,-1.58]],
    [[.29,1.95,.01],[.73,2.83,.39],[1.75,3.71,.78],[2.19,3.79,1.14]],
    [[.33,1.79,.03],[.40,3.15,-.04],[.25,4.03,.16],[.70,4.54,.23]]
];
function makeTree(old){
    const wood=mesh(old?"VeteranBark":"CoppiceBark"),leaves=mesh(old?"VeteranFoliage":"CoppiceFoliage");
    const rng=random(old?40127:99821),bones=old?OLD_BOUGHS:YOUNG_BOUGHS;
    const trunk=old?[[0,-.17,0],[-.08,.25,.07],[.13,.73,.13],[.24,1.24,.01],
        [.57,1.94,-.13],[.86,2.34,-.04],[1.17,2.7,-.2]]:
        [[0,-.16,0],[.04,.28,.02],[.04,.66,-.07],[.13,1.18,0],[.23,1.67,.07],[.39,2.08,.03]];
    bole(wood,trunk,old?[.60,.56,.48,.395,.35,.29,.24]:[.36,.33,.245,.20,.155,.128],old?13:9,356);
    const roots=old?5:4;
    for(let j=0;j<roots;j++){
        const a=j*TAU/roots+.4*rng(),dir=[Math.cos(a),0,Math.sin(a)],side=[-dir[2],0,dir[0]];
        const reach=(old?1.6:1.01)*(.72+.68*rng())*(dir[0]>.68?1.32:1.0);
        const end=add(add(times(dir,reach),times(side,reach*(rng()-.50)*.33)),[0,dir[0]>.55?-.42:-.16,0]);
        bole(wood,[add(times(dir,.12),[0,old?.61:.39,0]),add(times(dir,reach*.36),[0,.18,0]),
            add(add(times(dir,reach*.74),times(side,reach*.18)),[0,-.012,0]),end],old?[.27,.184,.084,.015]:[.155,.100,.054,.013],5,90+j);
    }
    bones.forEach((b,index)=>{
        const size=(old?1:.71)*(.93+rng()*.14);
        const sections=old?6:5;
        const path=Array.from({length:sections},(_,j)=>bezier(...b,j/(sections-1)));
        const radii=path.map((_,j)=>size*(.035+.215*(1-j/(sections-1))**1.22));
        bole(wood,path,radii,old?6:5,216+index);
        const forward=norm([b[3][0]-b[1][0],0,b[3][2]-b[1][2]]),across=[-forward[2],0,forward[0]];
        // A warm top plate and two darker banks on each bough. Twigs leave
        // unequal gaps and ends hang at different heights over the river.
        const tiers=old?4:3;
        for(let j=0;j<tiers;j++){
            const at=.39+j*.17+rng()*.06;
            const start=bezier(...b,at),sign=j%2?1:-1;
            const branchDir=norm(add(times(forward,.65+.18*rng()),times(across,sign*(.66+.25*rng()))));
            const reach=(old?.97:.69)*(.80+.46*rng());
            const tip=add(add(start,times(branchDir,reach)),[0,.14+reach*.23,0]);
            bole(wood,[start,add(add(start,times(branchDir,reach*.45)),[0,.24,0]),tip],
                [.082,.053,.020].map(r=>r*size),4,321+j+index*7);
            const tail=(old?2.17:1.39)*(.76+.55*rng())*(1.16-.21*at);
            spray(leaves,tip,branchDir,reach*.91,tail,size*(.41+.20*rng()),(rng()-.5)*reach*.81,j%2,.32+.40*rng());
            const crownDir=norm(add(times(forward,.95),times(across,sign*.36)));
            const crown=add(add(start,times(branchDir,.27*reach)),[0,.39+size*.10,0]);
            spray(leaves,crown,crownDir,reach*1.51,tail*.51,size*(.68+.22*rng()),(rng()-.5)*.48,2,.56+.25*rng());
            if(j===1 || (old&&j===3)){
                const fringeDir=norm(add(branchDir,times(across,sign*.51)));
                spray(leaves,add(tip,times(branchDir,.24)),fringeDir,reach*.89,tail*1.19,size*.36,(rng()-.5)*.84,1,.33+.38*rng());
            }
        }
        // New growth from the bough itself draws an upper canopy over the
        // bare forks. Leave asymmetric windows between neighbouring boughs.
        const inner=bezier(...b,.53+.095*rng());
        const inward=norm(add(times(forward,.30),times(across,index%2?1:-1)));
        spray(leaves,add(inner,[0,.39,0]),inward,size*(1.15+.32*rng()),size*(1.05+.61*rng()),
            size*(.75+.19*rng()),(rng()-.5)*.37,2,.49+.17*rng());
        spray(leaves,b[3],forward,size*(1.14+.28*rng()),size*(2.35+rng()*.62),
            size*(.56+.11*rng()),(rng()-.5)*.66,index%2,.50+.21*rng());
    });
    if(old){
        // The central leader bends inland before curling over the exposed
        // bank. Its hanging tips partly shade the fork, with light between.
        const spine=[[.91,2.30,-.09],[.54,3.37,-.41],[.42,4.42,-.05],[.95,5.11,.02]];
        bole(wood,spine,[.19,.123,.078,.035],6,812);
        for(let j=0;j<4;j++){
            const h=bezier(...spine,.56+j*.14);
            const a=1.28+j*1.58;
            const dir=[Math.cos(a),0,Math.sin(a)];
            spray(leaves,h,dir,1.24+j*.09,1.21+.29*Math.cos(j),.70+.12*Math.sin(.9*j),.17*Math.cos(j),j%2===0?2:0,.53+j*.049);
        }
    }
    return [wood,leaves];
}
function base64(bytes){
    const abc="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let s="";
    for(let i=0;i<bytes.length;i+=3){
        const n=(bytes[i]<<16)|((bytes[i+1]||0)<<8)|(bytes[i+2]||0);
        s+=abc[n>>>18]+abc[(n>>>12)&63]+(i+1<bytes.length?abc[(n>>>6)&63]:"=")+(i+2<bytes.length?abc[n&63]:"=");
    }return s;
}
export function willowLibrary(){
    const meshes=[...makeTree(true),...makeTree(false)],chunks=[],views=[],accessors=[];let length=0;
    function buffer(values,dimensions,integer,extents=false){
        const size=integer?2:4,aligned=(length+3)&~3;
        if(aligned>length)chunks.push(new Uint8Array(aligned-length));
        const bytes=new Uint8Array(values.length*size),data=new DataView(bytes.buffer);
        values.forEach((v,i)=>integer?data.setUint16(i*2,v,true):data.setFloat32(i*4,Math.round(v*1e6)/1e6||0,true));
        const view=views.push({buffer:0,byteOffset:aligned,byteLength:bytes.length,target:integer?34963:34962})-1;
        length=aligned+bytes.length;chunks.push(bytes);
        const acc={bufferView:view,componentType:integer?5123:5126,count:values.length/dimensions,type:["","SCALAR","VEC2","VEC3","VEC4"][dimensions]};
        if(extents){acc.min=[];acc.max=[];for(let c=0;c<dimensions;c++){const col=values.filter((_,i)=>i%dimensions===c);
            acc.min.push(Math.floor(Math.min(...col)*1e4)/1e4);acc.max.push(Math.ceil(Math.max(...col)*1e4)/1e4);}}
        return accessors.push(acc)-1;
    }
    const glMeshes=meshes.map(m=>({name:m.name,primitives:[{attributes:{POSITION:buffer(m.p,3,false,true),
        NORMAL:buffer(m.n,3,false),TEXCOORD_0:buffer(m.uv,2,false),TEXCOORD_1:buffer(m.tag,2,false),COLOR_0:buffer(m.col,3,false)},
        indices:buffer(m.idx,1,true),mode:4}]}));
    const data=new Uint8Array(length);let off=0;for(const c of chunks){data.set(c,off);off+=c.length;}
    return JSON.stringify({asset:{version:"2.0",generator:"River Gate original willow authoring"},
        scene:0,scenes:[{nodes:[0]}],nodes:[{name:"RiverWillows",children:[1,2,3,4]},...meshes.map((m,i)=>({name:m.name,mesh:i}))],
        meshes:glMeshes,buffers:[{byteLength:length,uri:"data:application/octet-stream;base64,"+base64(data)}],bufferViews:views,accessors})+"\n";
}

export function willowInk(){
    const W=512,H=256,raw=new Uint8Array(W*H*4),rng=random(72253);
    let tile=0;
    function put(x,y,c,a=1){
        x=Math.floor(x);y=Math.floor(y);
        if(x<3||x>=125||y<3||y>=253||a<=0)return;
        const i=(y*W+x+tile*128)*4,old=raw[i+3]/255,result=a+old*(1-a);
        c.forEach((v,k)=>raw[i+k]=Math.round((v*a+raw[i+k]*old*(1-a))/result));
        raw[i+3]=Math.round(result*255);
    }
    function line(x,y,u,v,w,c){
        const steps=Math.ceil(Math.hypot(u-x,v-y)*1.45);
        for(let i=0;i<=steps;i++){
            const t=i/Math.max(steps,1),cx=x+(u-x)*t,cy=y+(v-y)*t,r=w*(1-.20*t);
            for(let py=Math.floor(cy-r-1);py<=cy+r+1;py++)for(let px=Math.floor(cx-r-1);px<=cx+r+1;px++)
                put(px,py,c,clamp(r+.56-Math.hypot(px+.5-cx,py+.5-cy)));
        }
    }
    // A willow blade has a narrow stem, a slightly rolled middle and an
    // off-axis point. The upper face is paler than the folded underside.
    function leaf(x,y,dx,dy,width,c,lift){
        const len=Math.hypot(dx,dy),sx=-dy/len,sy=dx/len;
        const extent=width*1.8+1;
        for(let py=Math.floor(Math.min(y,y+dy)-extent);py<Math.max(y,y+dy)+extent;py++)
        for(let px=Math.floor(Math.min(x,x+dx)-extent);px<Math.max(x,x+dx)+extent;px++){
            const ax=px+.5-x,ay=py+.5-y,t=(ax*dx+ay*dy)/(len*len);
            if(t<=0||t>=1)continue;
            const w=width*Math.pow(Math.sin(Math.PI*t),.93)*(1.10-.28*t);
            const d=ax*sx+ay*sy-Math.sin(Math.PI*t)*lift;
            const a=clamp(w+.58-Math.abs(d));if(a<=0)continue;
            const tone=.88+.115*(1-d/(w+.2))+.12*(1-Math.abs(d)/(w+.3))+.05*t;
            put(px,py,c.map(v=>clamp(v*tone,0,255)),a);
        }
    }
    for(tile=0;tile<3;tile++){
        const short=tile===2,loose=tile===1;
        const num=short?16:loose?10:15;
        // Angular leaf clusters overlap at the crest before breaking into
        // long free tips. Keep whole hanging stems visible even after mipmapping.
        for(let pass=0;pass<2;pass++)for(let s=0;s<num;s++){
            const v=(s+.3+rng()*.40)/num;
            const topX=64+(v-.5)*(short?28:45)+(rng()-.5)*16,topY=6+rng()*15;
            const reach=(v-.5)*(short?110:98)+(rng()-.5)*15;
            const bottom=short?124+99*rng():loose?148+95*rng():180+66*rng();
            const curl=(rng()-.5)*22,phase=rng()*6;
            const twig=t=>[topX+reach*(1-Math.exp(-4*t))+curl*t*t+3*Math.sin(t*5+phase)*t,topY+(bottom-topY)*t];
            let prev=twig(0);
            for(let q=1;q<=15;q++){
                const p=twig(q/15);
                line(prev[0],prev[1],p[0],p[1],pass===0?1.30:1.05,pass===0?[45,72,54]:[73,88,53]);prev=p;
            }
            const steps=Math.round((short?11:15)+rng()*4);
            const local=rng(),light=pass===0?.65+.17*local:.82+.32*local;
            for(let j=1;j<=steps;j++)for(let k=0;k<(loose?1:2);k++){
                const t=(j-.45+k*.29)/steps,p=twig(t),side=(j+k)%2?-1:1;
                const width=(short?3.3:2.7)*(1-.48*t)*(.92+.50*rng());
                const len=(short?13:16)*(1-.23*t)*(.91+.45*rng());
                const dy=len*(.51+ .56*t),dx=side*len*(1.03-.49*t);
                const c=(pass===0?[49,81,60]:short?[102,125,76]:[87,115,76]).map((v,n)=>v*light+(n===0?10:-1)*rng());
                leaf(p[0],p[1],dx,dy,width,c,side*(1.9+2*rng()));
            }
        }
    }
    tile=3;
    for(let layer=0;layer<2;layer++)for(let i=0;i<30;i++){
        const sx=64+(rng()-.5)*62,sy=248-rng()*12,dx=(rng()-.5)*87,dy=-(79+154*rng());
        const c=(layer===0?[47,80,65]:[102,123,75]).map(v=>v*(.8+.32*rng()));
        for(let j=0;j<2;j++){
            const t=j*.49,x=sx+dx*t*t,y=sy+dy*t;
            leaf(x,y,dx*((t+.51)**2-t*t),dy*.54,(2.7-j*.84)*(.87+.27*rng()),c,dx*.041);
        }
        if(i%4===0){
            const x=sx+dx,y=sy+dy;
            line(x-dx*.10,y-dy*.12,x,y,1.12,[105,107,65]);
            leaf(x-dx*.032,y-dy*.035,dx*.11,dy*.075,2.1,[137,127,78],.1);
        }
    }
    // Retain the natural hanging points inside each sprite. This ragged
    // perimeter prevents a dense, overlapping spray from exposing a cut rectangle.
    for(let s=0;s<3;s++)for(let y=2;y<254;y++){
        const t=y/255,center=63+6*Math.sin(t*4.9+s*1.71)+2.6*Math.sin(t*14.8+s);
        const half=15+44*Math.pow(Math.sin(t*Math.PI),.58)-6*t;
        const left=center-half+4.2*Math.sin(y*.097+s)+1.8*Math.sin(y*.316+s);
        const right=center+half+5.1*Math.sin(y*.079+s+1.8)+2.8*Math.cos(y*.244+s);
        for(let x=2;x<126;x++){
            const i=(y*W+s*128+x)*4+3;
            const edge=Math.min(x-left,right-x);
            raw[i]=Math.round(raw[i]*clamp((edge+1.5)/3.5));
        }
    }
    return raw;
}
