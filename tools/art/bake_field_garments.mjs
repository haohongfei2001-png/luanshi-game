// Original garment geometry for the river company. Run with Node.js; no external packages.
// The swatches and two-joint weights use the same bind and UV grid as river_company.glb.
import { readFileSync, writeFileSync } from "node:fs";

const HIPS=0, CHEST=1, HEAD=2, LEFT_ARM=3, RIGHT_ARM=6;
const SWATCH={ cloth:1, hide:2, lining:10, headcloth:18, edge:29, iron:30, waist:31 };
const pack=[];
const views=[], accessors=[], nodes=[], meshes=[];
const lods=[["Close",10,5],["Line",6,3],["Rank",4,2]];
const looks=["Levy","Archer","Regular","Guard","Officer","Player"];
let byteLength=0;

function accessor(values,components,index=false) {
    const size=index?2:4;
    const aligned=(byteLength+3) & ~3;
    if(aligned>byteLength) pack.push(new Uint8Array(aligned-byteLength));
    const bytes=new Uint8Array(values.length*size), view=new DataView(bytes.buffer);
    values.forEach((n,i)=>index?view.setUint16(i*2,n,true):view.setFloat32(i*4,n,true));
    views.push({buffer:0,byteOffset:aligned,byteLength:bytes.length,target:index?34963:34962});
    pack.push(bytes);
    byteLength=aligned+bytes.length;
    const entry={bufferView:views.length-1,componentType:index?5123:5126,count:values.length/components,type:["","SCALAR","VEC2","VEC3"][components]};
    if(components===3) {
        entry.min=[Infinity,Infinity,Infinity];entry.max=[-Infinity,-Infinity,-Infinity];
        values.forEach((v,i)=>{const a=i%3,x=Math.fround(v);entry.min[a]=Math.min(entry.min[a],x);entry.max[a]=Math.max(entry.max[a],x);});
    }
    accessors.push(entry);return accessors.length-1;
}

function surface(look,segments,rows) {
    const position=[], normal=[], uv=[], skin=[], indices=[];
    function panel(nx,ny,swatch,point,reverse=false) {
        const start=position.length/3;
        for(let j=0;j<=ny;j++) for(let i=0;i<=nx;i++) {
            const u=i/nx,v=j/ny;
            const [x,y,z,b1,b2,weight]=point(u,v);
            position.push(x,y,z);normal.push(0,0,0);
            uv.push((swatch%8+(4+120*u)/128)/8,(Math.floor(swatch/8)+(4+120*(1-v))/128)/4);
            skin.push((b1*32+b2+.5)/1024,weight);
        }
        for(let j=0;j<ny;j++) for(let i=0;i<nx;i++) {
            const a=start+j*(nx+1)+i,b=a+1,c=b+nx+1,d=a+nx+1;
            if(reverse) indices.push(a,d,c,a,c,b);else indices.push(a,b,c,a,c,d);
        }
    }
    const armoured=["Regular","Guard","Officer","Player"].includes(look);
    if(armoured) {
        for(const side of [-1,1]) {
            const arm=side===-1?LEFT_ARM:RIGHT_ARM;
            const span=look==="Regular"?.130:(look==="Player"&&side===1?.108:.194);
            // A curved shoulder defence laps over the fitted sleeve. The bound rim and
            // textile lining share the same edge vertices and joint weights as the iron.
            function at(u,t) {
                const a=(u-.5)*2.95,round=Math.cos(a),rise=Math.sin(t*Math.PI);
                // The pauldron is cupped high on the deltoid with a cut-away front.
                // Its lowest point faces back toward the elbow, clearing the wrist.
                const x=.218+.020*t+(.056+.044*t+.030*rise)*round;
                const y=1.423-.010*round-t*(span-.051*(1-round)-.022*Math.sin(a));
                const z=-.010+(.092+.017*rise+.015*t)*Math.sin(a);
                return [side*x,y,z,arm,CHEST,.46+.54*t];
            }
            const parts=look==="Regular"
                ? [[0,.72,SWATCH.iron],[.72,.83,SWATCH.hide],[.83,1,SWATCH.cloth]]
                : [[0,.64,SWATCH.iron],[.64,.73,SWATCH.edge],[.73,.88,SWATCH.iron],[.88,1,SWATCH.hide]];
            for(const [top,bottom,colour] of parts) panel(segments,top===0?rows:1,colour,(u,v)=>at(u,top+(bottom-top)*v),side===-1);
        }
    }
    if(look==="Levy" || look==="Archer") {
        // Two ends of the tied wrap have different lengths. Only the knot rotates
        // completely with the skull; the ends hang against the back of the coat.
        for(const side of [-1,1]) {
            const reach=side===-1?.201:.140;
            panel(2,rows+1,side===-1?SWATCH.headcloth:SWATCH.cloth,(u,t)=>{
                const spread=(.025+.018*Math.sin(t*Math.PI))*(1-.72*t*t);
                const x=-.014+side*(.019+.052*t)+(u-.5)*spread;
                const y=1.638-reach*t+.008*Math.sin(t*Math.PI);
                const z=-.094-.075*t-.017*Math.sin(t*Math.PI)+.006*Math.sin(u*Math.PI);
                return [x,y,z,HEAD,CHEST,1-.73*t*t];
            });
        }
    }
    if(look==="Officer" || look==="Player") {
        // A diagonal folded collar rests on the upper back above the mantle. It gives
        // the normal follow camera a direction cue when the weapon arm is hidden.
        panel(segments,2,look==="Player"?20:SWATCH.edge,(u,v)=>{
            const angle=1.55+3.18*u;
            const x=(.119+.109*v)*Math.sin(angle);
            const y=1.457-.066*v-.032*v*Math.sin(Math.PI*u)-.030*u;
            const z=-.045+(.094+.072*v)*Math.cos(angle);
            return [x,y,z,CHEST,HIPS,.98];
        },true);
    }
    // Costume masses for a 22 m orthographic camera. They are fitted to the
    // existing bind, not camera-facing badges. Hardware still uses the same surface.
    const PI=Math.PI,TAU=2*PI;
    const far=segments<=4, sides=far?5:segments+2;
    if(look==="Archer") {
        // A suspended leather quiver follows the diagonal from left hip to right
        // shoulder. The mouth, lip and two long feather vanes read together.
        function tube(u,t,pad=0) {
            const a=TAU*u,bulge=Math.sin(PI*t),r=.053+.024*t+.012*bulge+pad;
            const x=-.185+.350*t,z=-.228-.058*t;
            return [x+r*.86*Math.cos(a),.804+.605*t-.50*r*Math.cos(a),
                    z+r*.88*Math.sin(a),CHEST,HIPS,.83+.16*t];
        }
        panel(sides,far?2:3,21,(u,v)=>tube(u,v));
        panel(sides,1,2,(u,v)=>tube(u,.87+.09*v,.004));
        panel(sides,1,10,(u,v)=>tube(u,.966+.034*v,.003));
        panel(sides,1,2,(u,v)=>{
            const p=tube(u,1),q=tube(0,1);
            return [.165+(p[0]-.165)*(1-.96*v),1.409+(p[1]-1.409)*(1-.96*v),
                    -.286+(p[2]+.286)*(1-.96*v),q[3],q[4],q[5]];
        });
        for(const wing of [-1,1]) {
            panel(far?1:2,far?2:3,18,(u,v)=>{
                const s=wing*(.032+.037*v),span=Math.sin(PI*(.12+.86*v))*.027;
                return [.168+s+.059*v+(u-.5)*span,1.41+.181*v+(wing<0?0:.041),
                        -.290-.044*v+(u-.5)*span*.72,CHEST,HIPS,.99];
            },wing<0);
        }
        // A single soft, cross-body wrap. Its taper exposes the opposite shoulder
        // and elbow on the draw, instead of another symmetrical shoulder plate.
        panel(segments,3,26,(u,v)=>{
            const a=-2.80+u*2.48, spread=Math.sin(Math.PI*u);
            return [(.169+.099*v)*Math.sin(a),1.432-.168*v*(.55+.51*spread)-.027*Math.sin(a)**2,
                    -.012+(.108+.064*v)*Math.cos(a),LEFT_ARM,CHEST,.32*v*spread];
        });
    } else if(look==="Levy") {
        // A small, soft ration satchel sits against the right hip, below the existing sling.
        panel(sides,far?2:4,0,(u,v)=>{
            const a=TAU*u, fullness=.56+.43*Math.sin(PI*(.02+.90*v)), y=.789+.212*v;
            return [.185+.075*fullness*Math.cos(a),y-.016*Math.cos(a),
                    -.092+.101*fullness*Math.sin(a),HIPS,12,.98-.15*(1-v)];
        });
        panel(segments,2,2,(u,v)=>{
            const a=1.96+3.17*u;
            return [.187+(.064+.009*v)*Math.cos(a),.966+.032*v-.017*Math.cos(a),
                    -.094+(.093+.010*v)*Math.sin(a),HIPS,12,.98];
        });
    } else if(look==="Regular" || look==="Guard") {
        // The two leather straps pass over the shoulders and disappear into the
        // iron corslet. Keep the cloth at the nape and the upper arms visible.
        for(const side of [-1,1]) {
            const width=look==="Guard"?.047:.035;
            panel(far?1:2,far?3:5,SWATCH.hide,(u,v)=>{
                const angle=PI*(.09+.85*v);
                const x=side*(.111+.037*v)+width*(u-.5);
                const z=-.018+.155*Math.cos(angle);
                const y=1.266+.173*Math.sin(angle)-.014*v;
                return [x,y,z,CHEST,HIPS,.98];
            });
        }
        if(look==="Guard") {
            for(const side of [-1,1]) {
                const joint=side<0?9:12, span=side<0?.407:.297;
                function flank(u,t) {
                    const ang=side*(.54+(2.05-.23*t)*u+.13*t);
                    const bulge=.206+.080*t+.014*Math.sin(PI*t), y=.962-t*span+
                        t*(.081*(2*u-1)**2+.026*u);
                    return [bulge*Math.sin(ang),y,(-.016+(.162+.085*t)*Math.cos(ang)),
                            joint,HIPS,.60*t];
                }
                panel(segments,far?1:rows,30,(u,v)=>flank(u,v),side<0);
                panel(segments,1,2,(u,v)=>flank(u,.96+.065*v),side<0);
            }
        }
    }
    for(let i=0;i<indices.length;i+=3) {
        const a=indices[i]*3,b=indices[i+1]*3,c=indices[i+2]*3;
        const ax=position[b]-position[a],ay=position[b+1]-position[a+1],az=position[b+2]-position[a+2];
        const bx=position[c]-position[a],by=position[c+1]-position[a+1],bz=position[c+2]-position[a+2];
        const n=[ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx];
        for(const k of [a,b,c]) for(let j=0;j<3;j++)normal[k+j]+=n[j];
    }
    for(let i=0;i<normal.length;i+=3) {
        const length=Math.hypot(normal[i],normal[i+1],normal[i+2]);
        if(length<1e-10)throw Error("Degenerate trim surface for "+look);
        for(let j=0;j<3;j++)normal[i+j]/=length;
    }
    const attrs={POSITION:accessor(position,3),NORMAL:accessor(normal,3),TEXCOORD_0:accessor(uv,2),TEXCOORD_1:accessor(skin,2)};
    return {attributes:attrs,indices:accessor(indices,1,true)};
}

for(const [suffix,segments,rows] of lods) for(const look of looks) {
    const name=look+suffix+"Trim", at=meshes.length;
    meshes.push({name,primitives:[surface(look,segments,rows)]});nodes.push({name,mesh:at});
}
const binary=new Uint8Array(byteLength);
let offset=0;for(const part of pack){binary.set(part,offset);offset+=part.length;}
const doc={asset:{version:"2.0",generator:"Luanshi river company"},scene:0,scenes:[{nodes:nodes.map((_,i)=>i)}],nodes,meshes,
    buffers:[{uri:"data:application/octet-stream;base64,"+Buffer.from(binary).toString("base64"),byteLength}],bufferViews:views,accessors};
const target=new URL("../../assets/river_gate/figures/field_garments.gltf",import.meta.url);
const output=JSON.stringify(doc)+"\n";
if(process.argv.includes("--check")) {
    if(readFileSync(target,"utf8")!==output) throw Error("Unbaked field garment changes");
} else writeFileSync(target,output);
