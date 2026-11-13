// Original garment geometry for the river company. Run with Node.js; no external packages.
// The swatches and two-joint weights use the same bind and UV grid as river_company.glb.
import { readFileSync, writeFileSync } from "node:fs";

const HIPS=0, CHEST=1, HEAD=2, LEFT_ARM=3, RIGHT_ARM=6;
const SWATCH={ cloth:1, hide:2, lining:10, headcloth:18 };
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
        // Both halves of the wool shoulder piece are cut from one polygonal
        // pattern. The two open corners stop on the ribcage, several centimetres
        // inside the arm socket, with the sewn sleeve visible below the edge.
        const guard=look==="Guard";
        const depth=guard?.106:(look==="Regular"?.153:.166);
        const n=segments<=4?4:segments;
        function textile(a,down) {
            const front=Math.cos(a),side=Math.sin(a),left=Math.max(0,-side);
            const fall=.47+.29*(1-front)+.53*left;
            const y=1.445-depth*fall*down-.020*side*side;
            const rx=.086+(.146+.018*left)*Math.sin(down*1.49);
            const rz=.083+(.084+.020*Math.max(0,-front))*Math.sin(down*1.45);
            const fold=.009*Math.sin(2*a+.47)*Math.sin(Math.PI*down);
            const shoulder=Math.abs(side);
            return [(rx+fold)*side,y,-.008+(rz+fold)*front,
                    side<0?LEFT_ARM:RIGHT_ARM,CHEST,.33*shoulder*down];
        }
        // The spearman's left mantle fastens under a bare right shoulder. A
        // shieldman wears the much shorter padded cover beneath a dark corslet.
        const low=-3.60,high=guard?2.47:.30;
        const mat=guard?11:(look==="Regular"?1:19);
        panel(n,rows,mat,(u,v)=>textile(low+(high-low)*u,1-v));
        if(look==="Regular"||guard){
            panel(n,1,guard?2:26,(u,v)=>textile(low+(high-low)*u,1.055-.055*v));
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
        panel(segments,2,look==="Player"?23:19,(u,v)=>{
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
        // One flat, slung case from the left hip to the right shoulder. The
        // stitched leather edge rises at the back and leaves an open, dark mouth.
        // The same cross-section and attachment points are used at each distance.
        function casePoint(angle,t,rim=0) {
            const cosine=Math.cos(angle), sine=Math.sin(angle);
            const bulge=Math.sin(PI*t);
            const halfWidth=.059+.043*t+.011*bulge+rim;
            const halfDepth=.028+.026*t+.006*bulge+rim;
            const across=halfWidth*Math.sign(cosine)*Math.pow(Math.abs(cosine),.71);
            const back=halfDepth*Math.sign(sine)*Math.pow(Math.abs(sine),.83);
            return [-.164+.340*t+.874*across,.838+.559*t-.48*across+
                    (.029*Math.max(0,-sine)+.011*cosine)*t*t,
                    -.195-.064*t-.012*bulge+back,CHEST,CHEST,1];
        }
        panel(sides,far?3:6,21,(u,v)=>casePoint(TAU*u,v));
        panel(sides,1,2,(u,v)=>casePoint(TAU*u,.915+.052*v,.004));
        panel(sides,1,14,(u,v)=>casePoint(TAU*u,.978+.022*v,.004));
        panel(sides,2,2,(u,v)=>casePoint(TAU*u,1.-.213*v,-.005),true);
        panel(sides,1,15,(u,v)=>{
            const rim=casePoint(TAU*u,.78,-.005);
            const middle=[-.164+.340*.78,.838+.559*.78,-.195-.064*.78];
            return rim.map((value,i)=>i<3?value+(middle[i]-value)*.990*v:value);
        });
        // Hem folded across the flat side, following the silhouette when the
        // bow arm rises. A single seam replaces the coincident older tube.
        panel(1,far?3:5,2,(u,v)=>casePoint(.27+.14*u+.32*v,.08+.85*v,.002));
        const featherCount=far?3:4;
        for(let shaft=0;shaft<featherCount;shaft++) {
            const where=[-.056,-.019,.021,.066][shaft];
            const height=[.140,.232,.171,.207][shaft];
            const back=[.014,-.021,.011,-.012][shaft];
            const step=[-.021,.015,.006,.030][shaft];
            function fletch(t,x=0,z=0) {
                return [.174+where+(.074+step)*t+x,1.359-.39*where+height*t,
                        -.263+back-.048*t+z,CHEST,CHEST,1];
            }
            panel(far?3:5,1,7,(u,v)=>fletch(v,.007*Math.cos(TAU*u),.007*Math.sin(TAU*u)));
            for(const yaw of (far?[.33]:[.33,2.09])) {
                panel(1,3,18,(u,v)=>{
                    const t=.44+.55*v, vane=.026*(.18+Math.sin(PI*(v*.82))*1.05)*(1-.91*v*v);
                    return fletch(t,u*vane*Math.cos(yaw),u*vane*Math.sin(yaw));
                });
            }
        }
        // A single soft, cross-body wrap. Its taper exposes the opposite shoulder
        // and elbow on the draw, instead of another symmetrical shoulder plate.
        panel(segments,3,1,(u,v)=>{
            const a=-2.80+u*2.48, spread=Math.sin(Math.PI*u);
            return [(.169+.099*v)*Math.sin(a),1.432-.168*v*(.55+.51*spread)-.027*Math.sin(a)**2,
                    -.012+(.108+.064*v)*Math.cos(a),LEFT_ARM,CHEST,.44*v*spread];
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
