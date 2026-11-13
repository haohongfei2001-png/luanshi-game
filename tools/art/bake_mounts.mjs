// Original river-gate horse and light cart. Node + no packages. Units: metres, +Z points to muzzle.
// The contours below are authored stations, not an assembly of engine sphere/capsule primitives.
const PI=Math.PI,TAU=2*PI;
const BASE='river_gate_mounts', N=256, T=64;
const COAT=0,LIGHT=1,POINT=2,HOOF=3,HAIR=4,MUZZLE=5,HIDE=6,STRAP=7,WOOL=8,BLUE=9,PIPING=10,BRASS=11,WOOD=12,IRON=13,EYE=14,FLAX=15;
const clamp=(v,a=0,b=1)=>Math.min(b,Math.max(a,v));
const add=(a,b)=>a.map((x,i)=>x+b[i]),sub=(a,b)=>a.map((x,i)=>x-b[i]),mul=(a,k)=>a.map(x=>x*k);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]],dot=(a,b)=>a.reduce((s,x,i)=>s+x*b[i],0),unit=a=>mul(a,1/(Math.hypot(...a)||1));
const normUV=(a)=>Math.round(clamp(a)*65535);
function cat(a,b,t){return a.map((v,i)=>v+(b[i]-v)*t)}
function b64(data){const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';let s=''; for(let i=0;i<data.length;i+=3){let n=(data[i]<<16)|((data[i+1]||0)<<8)|(data[i+2]||0);s+=alphabet[n>>18]+alphabet[n>>12&63]+(i+1<data.length?alphabet[n>>6&63]:'=')+(i+2<data.length?alphabet[n&63]:'=')}return s}
function concat(items){let n=items.reduce((t,a)=>t+a.length,0),a=new Uint8Array(n),p=0;for(let item of items){a.set(item,p);p+=item.length}return a}
function atlasUV(tile,u,v){return [((tile%4)*T+2+clamp(u)*(T-4))/N,((tile>>2)*T+2+clamp(v)*(T-4))/N]}
class Sculpt{
 constructor(){this.p=[];this.n=[];this.t=[];this.j=[];this.i=[];}
 pt(p,mat,u,v,j=0,w=1){
  // Both LODs place the painted flank, shoulder and muzzle in the same bind-space UV.
  if(mat===COAT||mat===LIGHT){u=(p[2]+.95)/2.25;v=(1.95-p[1])/1.92;}
  const k=this.p.length;this.p.push(p);this.n.push([0,0,0]);this.t.push(atlasUV(mat,u,v));this.j.push([(j+.5)/32,w]);return k}
 tri(a,b,c){const nn=cross(sub(this.p[b],this.p[a]),sub(this.p[c],this.p[a]));if(dot(nn,nn)<1e-14)return;this.i.push(a,b,c);for(const k of [a,b,c])this.n[k]=add(this.n[k],nn)}
 quad(a,b,c,d){this.tri(a,b,c);this.tri(a,c,d)}
 // Path section: [x,height,forward, half-width, perpendicular-depth, joint, weight]. Transverse sections share vertices.
 skin(rows,n,mat,ref=[1,0,0],bias=0){
  const rs=[];
  for(let k=0;k<rows.length;k++){const r=rows[k],p=r.slice(0,3),d=unit(sub(rows[Math.min(k+1,rows.length-1)].slice(0,3),rows[Math.max(0,k-1)].slice(0,3))),v=unit(cross(d,ref)),u=unit(cross(v,d));let rr=[];
   for(let s=0;s<n;s++){const a=TAU*s/n+bias;let pt=add(p,add(mul(u,Math.cos(a)*r[3]),mul(v,Math.sin(a)*r[4])));rr.push(this.pt(pt,mat,s/n,k/(rows.length-1),r[5]||0,r[6]??1))}
   rs.push(rr)
  }
  for(let k=0;k<rs.length-1;k++)for(let s=0;s<n;s++){let l=(s+1)%n;this.quad(rs[k][s],rs[k][l],rs[k+1][l],rs[k+1][s])}
  for(let k of [0,rs.length-1]){const r=rows[k],c=this.pt(r.slice(0,3),mat,.5,k?1:0,r[5]||0,r[6]??1);for(let s=0;s<n;s++){let l=(s+1)%n;if(k)this.tri(c,rs[k][s],rs[k][l]);else this.tri(c,rs[k][l],rs[k][s])}}
 }
 line(points,radii,mat,n=5,j=0,ref=null){let d=unit(sub(points.at(-1),points[0]));if(!ref)ref=Math.abs(d[0])>.82?[0,1,0]:[1,0,0];this.skin(points.map((p,i)=>[...p,Array.isArray(radii)?radii[i]:radii,Array.isArray(radii)?radii[i]:radii,j]),n,mat,ref)}
 // Four-corner or multi-point textile strip, with independent UV edges.
 strip(left,right,mat,j=0){const a=[],b=[];for(let i=0;i<left.length;i++){a.push(this.pt(left[i],mat,0,i/(left.length-1),j));b.push(this.pt(right[i],mat,1,i/(left.length-1),j))}
 for(let i=0;i<a.length-1;i++)this.quad(a[i],b[i],b[i+1],a[i+1]);}
 panel(rows,mat,j=0){const ids=rows.map((row,k)=>row.map((p,i)=>this.pt(p,mat,i/(row.length-1),k/(rows.length-1),j)));for(let k=0;k+1<ids.length;k++)for(let i=0;i+1<ids[k].length;i++)this.quad(ids[k][i],ids[k][i+1],ids[k+1][i+1],ids[k+1][i]);}
 // Ellipse used for crafted domed eyes, compact rivets and exposed metal axle.
 oval(c,scale,mat,n=8,j=0){const rr=[[-.94,.33],[-.56,.83],[.10,1],[.7,.71],[.96,.28]].map(([t,r])=>[c[0],c[1],c[2]+t*scale[2],scale[0]*r,scale[1]*r,j]);this.skin(rr,n,mat)}
 tyre(x,y,z,r,w,h,mat,j,n){const rings=[];for(let k=0;k<n;k++){let a=TAU*k/n,s=Math.sin(a),c=Math.cos(a);rings.push([[-w,-h],[w,-h],[w,h],[-w,h]].map(([off,rr],q)=>this.pt([x+off,y+(r+rr)*c,z+(r+rr)*s],mat,q/3,k/n,j)))}for(let k=0;k<n;k++)for(let q=0;q<4;q++)this.quad(rings[k][q],rings[(k+1)%n][q],rings[(k+1)%n][(q+1)%4],rings[k][(q+1)%4])}
 beam(a,b,wide,deep,mat,j=0){this.skin([[...a,wide,deep,j],[...b,wide,deep,j]],4,mat,Math.abs(unit(sub(b,a))[0])>.8?[0,1,0]:[1,0,0],PI/4)}
}

// Join the croup, ribcage, shoulder, jaw and four legs into a single hide. Each
// station contributes an elliptical muscle section. Surface Nets gives each
// boundary cell one shared vertex, including where the shoulder meets the barrel.
class HorseHide {
 constructor(){ this.paths=[]; }
 skin(rows,blend=.096){
  const joints=[];
  for(let i=1;i<rows.length;i++){
   const a=rows[i-1],b=rows[i], d=sub(b.slice(0,3),a.slice(0,3)),len=Math.hypot(...d);
   const vy=d[1]/len,vz=d[2]/len;
   joints.push({a,b,d,len,vy,vz});
  }
  const bounds=[0,1,2].map(k=>[Math.min(...rows.map(r=>r[k]-Math.max(r[3],r[4])))-.12,
                                Math.max(...rows.map(r=>r[k]+Math.max(r[3],r[4])))+.12]);
  this.paths.push({joints,bounds,blend});
 }
 distance(x,y,z){
  let result=1.0;
  for(const {joints,bounds,blend} of this.paths){
   if(x<bounds[0][0]||x>bounds[0][1]||y<bounds[1][0]||y>bounds[1][1]||z<bounds[2][0]||z>bounds[2][1])continue;
   let local=1.;
   for(const {a,b,d,len,vy,vz} of joints){
    const px=x-a[0],py=y-a[1],pz=z-a[2];
    const along=(px*d[0]+py*d[1]+pz*d[2])/len;
    const t=clamp(along/len),rx=a[3]+(b[3]-a[3])*t,rd=a[4]+(b[4]-a[4])*t;
    const across=(px-d[0]*t)/rx,deep=(py*vz-pz*vy)/rd;
    const cap=(along-len*t)/Math.max(.035,(rd+rx)*.35);
    local=Math.min(local,(Math.sqrt(across*across+deep*deep+cap*cap)-1)*Math.min(rx,rd));
   }
   const join=blend,h=clamp(.5+.5*(local-result)/join);
   result=local+(result-local)*h-join*h*(1-h);
  }
  return result;
 }
 build(mesh,partial=false){
  const pitch=partial?.125:.055;
  const origin=partial?[-.54,-.046,-1.09]:[-.48,-.042,-1.040];
  const size=partial?[11,16,18]:[19,38,45],jump=[1,size[0],size[0]*size[1]];
  const count=size[0]*size[1]*size[2];
  const values=new Float32Array(count),cells=new Int32Array(count).fill(-1);
  const corners=[0,1,2,3,4,5,6,7].map(i=>[i&1,(i>>1)&1,(i>>2)&1]);
  const offsets=corners.map(c=>dot(c,jump));
  for(let z=0;z<size[2];z++)for(let y=0;y<size[1];y++)for(let x=0;x<size[0];x++)
   values[x+y*jump[1]+z*jump[2]]=this.distance(origin[0]+x*pitch,origin[1]+y*pitch,origin[2]+z*pitch);
  for(let z=0;z<size[2]-1;z++)for(let y=0;y<size[1]-1;y++)for(let x=0;x<size[0]-1;x++){
   const at=x+y*jump[1]+z*jump[2], v=offsets.map(off=>values[at+off]);
   if(v.every(q=>q<0)||v.every(q=>q>=0))continue;
   const p=[0,0,0];let crossings=0;
   for(let i=0;i<8;i++)for(let a=0;a<3;a++){
    let j=i^(1<<a);
    if(j<i || (v[i]<0)===(v[j]<0))continue;
    const t=v[i]/(v[i]-v[j]);
    for(let k=0;k<3;k++)p[k]+=corners[i][k]+(corners[j][k]-corners[i][k])*t;
    crossings++;
   }
   for(const [a,coord] of [x,y,z].entries())p[a]=origin[a]+(coord+p[a]/crossings)*pitch;
   const [l,h,f]=p;
   let joint=0,weight=1;
   if(h<1.34 && Math.abs(l)>.058 && (f>.12||f<-.22)){
    const hind=f<0, centre=hind?(-.64+.10*clamp((h-.57)/.57)):(.42-.08*clamp((h-.58)/.57));
    const width=hind?.32:.27;
    const influence=clamp((1.34-h)/.48)*clamp((width-Math.abs(f-centre))/.105);
    if(influence>0){joint=(hind?3:1)+(l>0?1:0);weight=influence*influence*(3.-2.*influence);}
   }
   if(f>.28 && h>1.12){joint=11;weight=clamp((f-.32)*1.15+(h-1.19)*.89)}
   cells[at]=mesh.pt(p,COAT,clamp((f+.95)/2.25),clamp((1.95-h)/1.92),joint,weight);
  }
  const firstCell=cells.find(id=>id>=0);
  for(let z=1;z<size[2]-1;z++)for(let y=1;y<size[1]-1;y++)for(let x=1;x<size[0]-1;x++){
   const at=x+y*jump[1]+z*jump[2];
   for(let a=0;a<3;a++){
    if((values[at]<0)===(values[at+jump[a]]<0))continue;
    const j=jump[(a+1)%3],k=jump[(a+2)%3];
    const q=[cells[at],cells[at-j],cells[at-j-k],cells[at-k]];
    if(q.every(id=>id>=0))mesh.quad(...(values[at]<0?q:q.reverse()));
   }
  }
  // Sample a short spatial average of the continuous muscle field.  Surface
  // net cell positions determine silhouette; contours can cross the voxels
  // without snapping to a ring of equal lighting values.
  for(let i=firstCell;i<mesh.p.length;i++){
   const [x,y,z]=mesh.p[i];
   if(y<.56 || z>.69)continue;
   const h=partial?.066:.047;
   const gradient=(h)=>{
    return [this.distance(x+h,y,z)-this.distance(x-h,y,z),
            this.distance(x,y+h,z)-this.distance(x,y-h,z),
            this.distance(x,y,z+h)-this.distance(x,y,z-h)];
   }
   const near=unit(gradient(h)),wide=unit(gradient(h*1.85));
   const smooth=unit(add(mul(near,.58),mul(wide,.42)));
   const area=unit(mesh.n[i]),weight=clamp((y-.57)/.30)*clamp((.72-z)/.16);
   mesh.n[i]=unit(add(mul(area,1.-weight),mul(smooth,weight)));
  }
 }
}

// The cheek, poll, nasal bridge and lips form a continuous falling line.
const neckStations=[[0,1.116,.264,.235,.251,11,0],[0,1.238,.369,.232,.289,11,.10],
 [0,1.384,.490,.204,.264,11,.31],[0,1.536,.586,.162,.216,11,.54],
 [0,1.662,.682,.130,.164,11,.78],[0,1.756,.765,.108,.106,11,.98]];
const skullStations=[[0,1.726,.718,.077,.098,11],[0,1.751,.788,.141,.139,11],
 [0,1.723,.856,.149,.167,11],[0,1.685,.940,.132,.151,11],
 [0,1.653,1.015,.112,.123,11],[0,1.606,1.089,.090,.091,11],
 [0,1.562,1.156,.086,.078,11],[0,1.537,1.203,.097,.065,11],
 [0,1.515,1.245,.088,.049,11],[0,1.504,1.264,.062,.027,11]];

function fitFace(m,hide,detail){
 // Seat the orbit and nostril onto the actual signed-distance cheek, on
 // both sides. Sparse distant faces keep their same orbital and nasal cues.
 function width(y,z) {
  let low=0,high=.24;
  for(let step=0;step<17;step++){const x=(low+high)*.5;if(hide.distance(x,y,z)>0)high=x;else low=x;}
  return low;
 }
 for(const side of [-1,1]){
  function face(y,z,depth=.002){return [side*(width(y,z)+depth),y,z];}
  function mark(y,z,ys,zs,tilt,tile,steps,bulge) {
   const ps=[];
   const centre=m.pt(face(y,z,bulge),tile,.5,.5,11);
   for(let i=0;i<steps;i++){
    const a=TAU*i/steps, long=zs*Math.cos(a), high=ys*Math.sin(a);
    const yy=y+high+tilt*long, zz=z+long;
    ps.push(m.pt(face(yy,zz,.0035),tile,.5+.48*Math.cos(a),.5+.48*Math.sin(a),11));
   }
   for(let i=0;i<steps;i++)m.tri(centre,side<0?ps[(i+1)%steps]:ps[i],side<0?ps[i]:ps[(i+1)%steps]);
  }
  mark(1.761,.879,.013,.032,.17,EYE,detail?10:6,.010);
  // The opening of the nares faces out AND forward. A side-projected
  // flat dot vanishes when the game camera looks along the nasal ridge.
  const nares=face(1.544,1.226,.004);
  const outward=unit([side*.72,.22,.66]);
  const along=unit([-side*.55,-.36,.72]);
  const across=unit(cross(outward,along));
  const root=add(nares,mul(outward,.003));
  const inner=[],outer=[];
  const count=detail?10:6;
  const dark=m.pt(add(root,mul(outward,.011)),EYE,.47,.44,11);
  for(let i=0;i<count;i++){
   const a=TAU*i/count, long=Math.cos(a),short=Math.sin(a);
   const pos=add(root,add(mul(along,.031*long),mul(across,.014*short*(1.-.24*long))));
   const lip=add(root,add(mul(along,.039*long),mul(across,.021*short)));
   const lift=.008+.005*short;
   inner.push(m.pt(add(pos,mul(outward,lift+.003)),EYE,.5+.46*long,.5+.46*short,11));
   outer.push(m.pt(add(lip,mul(outward,lift)),MUZZLE,.5+.45*long,.5+.45*short,11));
  }
  for(let i=0;i<count;i++){
   let j=(i+1)%count;
   m.tri(dark,inner[i],inner[j]);
   // Make the rim a separate island; a triangle cannot span texture swatches.
   const a=m.pt(m.p[inner[i]],MUZZLE,.46,.54,11),c=m.pt(m.p[inner[j]],MUZZLE,.54,.46,11);
   m.quad(a,outer[i],outer[j],c);
  }
  if(detail){
   // Fleshy outer wing, dark almond opening and lower-lip crease. The
   // forehead stays open between the brow and the bridle cheekpiece.
   m.line([face(1.767,.853,.007),face(1.779,.872,.008),face(1.778,.890,.008),face(1.766,.910,.004)],[.003,.007,.007,.003],POINT,5,11);

   m.line([face(1.501,1.169,.003),face(1.492,1.198,.003),face(1.489,1.231,.004),face(1.498,1.254,.004)],[.003,.005,.006,.003],POINT,4,11);
   mark(1.766,.887,.0036,.0039,0,FLAX,6,.0105);
  }
 }
}

function riverMane(m,close){
 // A horse's mane falls off the crest to one side. Four broad overlapping
 // locks protect its silhouette in motion; the root line also marks the wither.
 const locks=[
  [.282,1.472,.421,1.612,.175,.99], [.392,1.589,.536,1.738,.156,.78],
  [.506,1.702,.638,1.815,.137,.74], [.604,1.790,.751,1.858,.112,.70]];
 for(let k=0;k<locks.length;k++){
  const [z0,y0,z1,y1,depth,bias]=locks[k], l=[],r=[];
  for(const t of [0,.38,.74,1]){
   const fall=depth*t, back=t*(.066+.025*bias);
   const root=-.015-.078*Math.sin(t*1.47);
   const pinch=t*t*(.62+.04*k);
   l.push([root-.013*t, y0-fall+.014*Math.sin(t*PI), z0-back+pinch*(z1-z0)*.30]);
   r.push([root-.030*Math.sin(t*PI), y1-fall-.035*t, z1-back-pinch*(z1-z0)*.55]);
  }
  m.strip(l,r,HAIR,11);
 }
 // Forelock comes forward between the ears, then parts onto the visible brow.
 m.skin([[0,1.864,.766,.037,.027,11],[-.007,1.875,.817,.046,.028,11],
         [-.038,1.859,.861,.048,.024,11],[-.056,1.823,.908,.029,.014,11],
         [-.050,1.800,.920,.006,.006,11]],close?7:4,HAIR);
}
// Ordered by Z. The croup descends to the tailhead, the loin dips under
// the back of the saddle, and a deep heart-girth sits behind the elbow.
// Smooth centre/width/depth values before constructing the distance field.
const barrelStations=[
 [0,1.025,-.868,.067,.083],[0,1.031,-.812,.183,.161],
 [0,1.054,-.703,.251,.245],[0,1.084,-.552,.288,.287],
 [0,1.085,-.417,.297,.289],[0,1.068,-.252,.292,.265],
 [0,1.052,-.086,.300,.271],[0,1.046,.070,.309,.300],
 [0,1.058,.212,.310,.335],[0,1.087,.348,.290,.339],
 [0,1.111,.462,.252,.296],[0,1.102,.568,.184,.235],[0,1.077,.650,.080,.142]];
function smoothBarrel() {
 const rows=[];
 for(let i=0;i<barrelStations.length-1;i++){
  const a=barrelStations[i],b=barrelStations[i+1],prev=barrelStations[Math.max(0,i-1)],next=barrelStations[Math.min(barrelStations.length-1,i+2)];
  rows.push(a);
  const middle=a.map((v,k)=>(a[k]+b[k])*.5+((b[k]-prev[k])-(next[k]-a[k]))*.0625);
  rows.push(middle);
 }
 rows.push(barrelStations.at(-1));return rows;
}
function legStations(hind){
 // The oblique shoulder blade runs from the withers toward the point of the
 // shoulder; the gaskin rises toward the hip before the upper thigh turns back.
 return hind?[
  [.137,1.257,-.465,.114,.156],[.173,1.177,-.536,.146,.178],
  [.195,1.084,-.578,.131,.171],[.214,.982,-.566,.124,.151],
  [.216,.868,-.488,.103,.121],[.216,.783,-.478,.090,.096],
  [.216,.689,-.567,.077,.094],[.217,.554,-.679,.057,.077],
  [.219,.50,-.706,.050,.064],[.217,.447,-.677,.041,.050],
  [.216,.238,-.637,.036,.045],[.216,.167,-.636,.052,.052],[.216,.110,-.608,.045,.043]]:
  [[.137,1.287,.235,.108,.158],[.174,1.203,.318,.134,.155],
   [.206,1.106,.394,.131,.153],[.215,.996,.394,.117,.135],
   [.218,.898,.356,.095,.115],[.218,.795,.332,.081,.094],
   [.219,.698,.357,.068,.079],[.219,.588,.396,.058,.066],
   [.219,.505,.426,.055,.066],[.219,.447,.419,.041,.048],
   [.219,.236,.408,.033,.040],[.219,.166,.414,.049,.051],[.219,.109,.446,.042,.041]];
}
function buildBarrel(hide,rank=false){
 hide.skin(smoothBarrel(),.113);
 for(const side of [-1,1]){
  for(const hind of [false,true]){
   const sections=legStations(hind).filter(row=>!rank || row[1]>=.50).map(([x,y,z,rx,rz])=>[side*x,y,z,rx,rz]);
   hide.skin(sections,hind?.139:.130);
  }
 }
}

// A felt pad rests over both ribs. The deep rear corners hang behind the
// stirrup; exposed withers, tack and all rider/contact sockets stay clear.
function saddleFelt(m,side,close) {
 const fall=[
   [-.564,1.150,.245],[-.541,1.025,.282],[-.463,.946,.310],[-.279,.961,.323],
   [-.070,.985,.335],[.110,1.018,.340],[.247,1.071,.304],[.289,1.160,.270]];
 const stations=close?fall:fall.filter((_,i)=>[0,2,3,5,7].includes(i));
 const rows=stations.map(([z,h,x])=>[
   [0,1.391,z],[side*.160,1.361,z],[side*.252,1.292,z],
   [side*(x-.016),h+.091,z],[side*x,h,z]]);
 m.panel(rows,WOOL);
 const edge=rows.map(row=>row.at(-1));
 m.strip(edge.map(p=>add(p,[side*.002,.006,0])),edge.map(p=>add(p,[side*.002,.038,0])),PIPING);
 m.strip(edge.map(p=>add(p,[side*.003,.042,0])),edge.map(p=>add(p,[side*.004,.089,0])),BLUE);
 if(close) {
   for(const i of [0,rows.length-1]){
     const rim=rows[i];
     const inward=i===0?.024:-.024;
     m.strip(rim.map(p=>add(p,[side*.002,.005,0])),rim.map(p=>add(p,[side*.004,.006,inward])),BLUE);
   }
 }
}

function horse(m, high, draught){
 const hide=new HorseHide();
 const limb=high?8:5, small=high?7:5;
 // Barrel: croup, tucked flank, deep rib cage and prominent withers. Ventral line rises aft.
 buildBarrel(hide);
 // Neck incl. crest, throat and jaw: the taper follows a rising diagonal rather than a cone.
 hide.skin(neckStations);
 hide.skin(skullStations);
 // Large upper cheek behind a slim nasal bridge. The throat is left open.
 for(const side of [-1,1])hide.skin([[side*.052,1.677,.810,.084,.102],[side*.052,1.626,.868,.083,.107],[side*.044,1.602,.951,.057,.064]]);
 fitFace(m,hide,true);
 // Two ears, dark inner pinnae, black eyes under an orbital ridge and fleshy nostrils.
 for(const s of [-1,1]){
  m.skin([[s*.079,1.831,.765,.047,.059,11],[s*.094,1.895,.765,.045,.052,11],[s*.116,1.960,.758,.030,.035,11],[s*.126,1.993+s*.009,.759+s*.022,.006,.010,11]],high?7:4,POINT,[1,0,0]);
  if(high){
   m.strip([[s*.077,1.863,.797],[s*.083,1.924,.797],[s*.126,1.971,.769]],[[s*.110,1.865,.786],[s*.125,1.923,.779],[s*.128,1.972,.766]],MUZZLE,11)
  }
 }
 if(high){
  // An irregular central ridge sits directly on the top of the skull. Its
  // quiet light plane leads to the dark upper lip under an overhead camera.
  const bridge=[[.841,-.004,.025],[.876,-.009,.037],[.924,.003,.027],[.987,.007,.019],
                [1.053,-.002,.015],[1.104,-.006,.015],[1.143,-.004,.006]];
  function upper(x,z){
   let lo=1.53,hi=1.95;
   for(let i=0;i<17;i++){const y=(lo+hi)*.5;if(hide.distance(x,y,z)>0) hi=y;else lo=y;}
   return [x,lo+.004,z];
  }
  m.panel(bridge.map(([z,x,w])=>[upper(x-w,z),upper(x,z),upper(x+w,z)]),LIGHT,11);
 }
 // Mane skin sections, separate forelock and one coherent tapering tail.
 let crest=[[0,1.47,.257,.042,.055,11,0],[-.018,1.57,.346,.054,.069,11,.1],[-.030,1.702,.47,.047,.063,11,.43],[-.034,1.819,.603,.043,.052,11,.73],[-.018,1.877,.72,.032,.038,11,1],[0,1.867,.794,.028,.026,11,1]];
 m.skin(crest,high?7:5,HAIR);

 riverMane(m,high);
 m.skin([[0,1.299,-.696,.073,.060,12,0],[0,1.237,-.826,.094,.090,12,.10],[-.014,1.026,-.904,.097,.104,12,.33],[-.012,.816,-.952,.086,.100,12,.56],[-.042,.608,-1.018,.066,.084,12,.85],[-.079,.450,-1.077,.014,.041,12,1]],high?9:5,HAIR)
 for(const s of [-1,1]){
  // Front: pectoral overlap → elbow → carpus → fetlock → inclined pastern and hoof.
  // Back: gluteal → stifle (forward) → projecting hock → cannon/pastern.
  for(const hind of [false,true]){
   const g=(hind?3:1)+(s>0?1:0);
   let z=hind?-.607:.447,x=s*.218; m.skin([[x,.128,z,.044,.051,g],[x,.095,z+.008,.051,.06,g],[x,.041,z+.031,.064,.08,g],[x,.013,z+.035,.062,.080,g]],limb,HOOF)
  }
 }
 hide.build(m);
 // Noseband and browband roll around the skull with cheekpieces joining a tangible bit ring.
 for(const [y,z,w,h] of [[1.639,1.097,.104,.108],[1.780,.837,.145,.112]]){
  let cp=[];for(let k=0;k<=10;k++){let a=TAU*k/10;cp.push([w*Math.cos(a),y+.78*h*Math.sin(a),z+.56*h*Math.sin(a)])}
  m.line(cp,.013,STRAP,high?5:3,11,[0,0,1]);
 }
 for(const s of [-1,1]){
  m.line([[s*.075,1.847,.751],[s*.145,1.78,.789],[s*.149,1.716,.858],[s*.114,1.619,1.057],[s*.100,1.563,1.163]],high?[.013,.016,.013,.013,.013]:.013,HIDE,high?5:3,11)
  if(high){let ring=[];for(let i=0;i<=8;i++){let a=TAU*i/8;ring.push([s*.107,1.559+Math.cos(a)*.03,1.153+Math.sin(a)*.03])}m.line(ring,.0065,BRASS,4,11,[1,0,0])}
  // Reins carry head motion at the bit, tapering to zero movement at the seat/driver.
  let reins=draught?[[s*.105,1.56,1.147],[s*.246,1.427,.72],[s*.332,1.34,.09],[s*.397,1.30,-.55],[s*.34,1.43,-1.105],[s*.18,1.66,-1.60]]:[[s*.107,1.56,1.147],[s*.190,1.476,.934],[s*.245,1.433,.672],[s*.244,1.49,.47],[s*.17,1.594,.24]];
  m.skin(reins.map((p,k)=>[...p,.009,.012,11,1-k/(reins.length-1)]),high?5:3,STRAP,[1,0,0]);
 }
 if(!draught){
  // Sculpted saddle blanket draped over both ribs, with a shaped front and a bound cloth hem.
  for(const s of [-1,1]){
   saddleFelt(m,s,true);
   m.line([[s*.234,1.355,-.043],[s*.314,1.184,-.053],[s*.324,.958,-.071],[s*.321,.851,-.056]],.015,HIDE,high?5:4);
   let iron=[[s*.32,.873,-.064],[s*.324,.835,-.121],[s*.323,.753,-.124],[s*.324,.746,.007],[s*.323,.831,.006],[s*.32,.873,-.064]];m.line(iron,.014,IRON,high?5:3);
   m.strip([[s*.269,1.28,.171],[s*.316,1.13,.127],[s*.30,.897,.093],[s*.212,.775,.070]],[[s*.271,1.279,.225],[s*.319,1.131,.184],[s*.302,.898,.155],[s*.215,.773,.134]],STRAP)
  }
  // Seat and heavy cantle share a worn dark hide. Paper-thin saddle
  // ends disappear under the rider; the rear rim follows the loin.
  m.skin([[0,1.376,-.347,.080,.014],[0,1.400,-.302,.169,.049],
          [0,1.407,-.225,.197,.051],[0,1.391,-.043,.180,.052],
          [0,1.401,.127,.174,.040],[0,1.437,.188,.170,.056],
          [0,1.418,.236,.110,.027]],12,STRAP);
 }else{
  // Padded breast collar (not a rider saddle), traces lead rearward to each shaft.
  for(const s of [-1,1]){m.skin([[s*.258,1.255,.29,.04,.049],[s*.309,1.129,.405,.047,.06],[s*.314,.99,.483,.055,.061],[s*.21,.935,.561,.054,.057],[0,.907,.595,.041,.048]],small,HIDE);m.line([[s*.31,1.015,.453],[s*.365,.940,-.004],[s*.443,.911,-.675],[s*.54,.836,-1.237]],.017,STRAP,small);}
  m.strip([[-.29,1.12,-.031],[-.20,1.343,-.031],[0,1.397,-.031],[.20,1.343,-.031],[.29,1.12,-.031]],[[-.29,1.12,.044],[-.20,1.343,.044],[0,1.397,.044],[.20,1.343,.044],[.29,1.12,.044]],HIDE);
 }
}

// Distance version is separately authored. Keep forward face, raised hocks, saddlecloth,
// hoof tips and rein silhouette; omit overlap shells, eye glints and individual bridles.
function rankHorse(m,tow){
 // The croup, dipped loin and withers each have an independent station in the
 // small screen silhouette. Keep the original saddle, poll and draught sockets.
 // Only the torso and leg roots need the shared hide in this LOD. The thin
 // lower cannon stays accurately spaced on the original foot joints.
 const barrel=new HorseHide();buildBarrel(barrel,true);
 barrel.build(m,true);
 m.skin(neckStations.filter((_,i)=>i!==1),8,COAT);
 m.skin(skullStations.filter((_,i)=>i!==3 && i!==6),8,COAT);
 const cheek=new HorseHide();cheek.skin(skullStations);
 fitFace(m,cheek,false);
 riverMane(m,false);
 m.skin([[0,1.467,.251,.041,.053,11,0],[-.024,1.567,.343,.060,.069,11,.13],
         [-.034,1.699,.473,.057,.068,11,.42],[-.027,1.810,.605,.045,.053,11,.75],
         [0,1.866,.760,.036,.035,11,1]],6,HAIR);
 m.skin([[0,1.289,-.70,.065,.068,12,0],[-.014,1.026,-.904,.096,.103,12,.33],[-.013,.790,-.963,.082,.098,12,.65],[-.079,.450,-1.077,.017,.034,12,1]],5,HAIR)
 for(const s of [-1,1]){
  m.skin([[s*.08,1.829,.765,.045,.051,11],[s*.10,1.92,.759,.04,.044,11],[s*.126,1.993+s*.009,.759+s*.022,.005,.009,11]],4,POINT);
  for(const h of [false,true]){
   let j=(h?3:1)+(s>0?1:0),x=s*.217,z=h?-.608:.446;
   let leg=h?[[1.14,-.56,.119,.147],[.826,-.479,.099,.115],[.502,-.705,.054,.068],[.171,-.637,.043,.049],[.113,z,.039,.041]]:[[1.145,.368,.123,.152],[.816,.329,.087,.105],[.509,.425,.051,.064],[.177,.413,.045,.052],[.113,z,.039,.041]];
   // The narrow cannon and the thicker fetlock break up the straight shank.
   leg.splice(3,0,[.414,h?-.682:.417,.041,.053]);
   const distal=[[.57,h?-.69:.404,.057,.066],...leg.filter(q=>q[0]<.56)];
   m.skin(distal.map(r=>[x,r[0],r[1],r[2],r[3],j]),6,COAT);
   m.skin([[x,.124,z,.045,.044,j],[x,.035,z+.034,.062,.078,j],[x,.012,z+.035,.06,.073,j]],4,HOOF);
  }
  let r=tow?[[s*.105,1.563,1.14],[s*.32,1.34,.04],[s*.36,1.41,-1.10],[s*.18,1.66,-1.60]]:[[s*.105,1.563,1.14],[s*.244,1.445,.70],[s*.17,1.594,.24]];
  // Weight the bit but hold the rider/driver end, as on the close mesh.
  m.skin(r.map((p,k)=>[...p,.009,.011,11,1-k/(r.length-1)]),3,STRAP);
  if(!tow){
   saddleFelt(m,s,false);
  }else{m.line([[s*.30,1.17,.365],[s*.316,.992,.491],[0,.913,.59]],.042,HIDE,4);m.line([[s*.31,1.013,.452],[s*.44,.89,-.68],[s*.54,.836,-1.237]],.016,STRAP,3);}
 }
 if(!tow)m.skin([[0,1.379,-.343,.085,.023],[0,1.406,-.270,.173,.051],
                 [0,1.391,-.025,.18,.052],[0,1.437,.188,.17,.056]],6,STRAP);
}

function cart(m,high){
 // Seat lies over the axle, 1.83 m behind the draught horse (the actual gameplay socket).
 // Each wheel is a complete hoop with projecting hub, iron tyre, and radial turned spokes.
 const slices=high?24:12, spokes=high?12:6;
 m.beam([-.91,.548,-1.83],[.91,.548,-1.83],.092,.083,WOOD);
 for(const s of [-1,1]){
  let x=s*.80,j=14;
  m.tyre(x,.55,-1.83,.505,.041,.041,WOOD,j,slices);
  m.tyre(x,.55,-1.83,.547,.045,.009,IRON,j,slices);
  m.line([[s*.699,.55,-1.83],[s*.79,.55,-1.83],[s*.867,.55,-1.83],[s*.943,.55,-1.83]],[.095,.107,.084,.06],WOOD,high?10:6,j,[0,1,0]);
  m.line([[s*.896,.55,-1.83],[s*.944,.55,-1.83]],.062,IRON,smallWheel(high),j,[0,1,0])
  for(let i=0;i<spokes;i++){let a=TAU*i/spokes,rad=r=>[x,.55+Math.cos(a)*r,-1.83+Math.sin(a)*r];m.line([rad(.083),rad(.24),rad(.47)],[.022,.024,.015],WOOD,high?5:3,j)}
  // Shafts, visible leather breast-strap attachment, and the diagonal braces bearing the bed.
  m.line([[s*.59,.78,-2.39],[s*.61,.79,-1.64],[s*.51,.81,-1.15],[s*.37,.94,-.31],[s*.342,1.01,.36]],[.062,.061,.054,.042,.033],WOOD,smallWheel(high))
  for(const z of [-2.30,-1.36])m.beam([s*.58,.80,z],[s*.68,.62,-1.83],.045,.045,WOOD)
 }
 m.beam([-.62,.791,-1.23],[.62,.791,-1.23],.073,.072,WOOD);
 m.beam([-.62,.787,-2.378],[.62,.787,-2.378],.07,.07,WOOD)
 // Individual deck boards have working dimension and a believable load-bearing perimeter.
 const planks=high?7:4;
 for(let k=0;k<planks;k++){let x=-.614+(k+.5)*1.228/planks,w=.606/planks;const qs=[[[x-w,.885,-2.428],[x+w,.885,-2.428],[x+w,.885,-1.207],[x-w,.885,-1.207]],[[x-w,.945,-2.428],[x+w,.945,-2.428],[x+w,.945,-1.207],[x-w,.945,-1.207]]];if(!high){qs[1].forEach(p=>p[1]=.925)}m.panel([qs[1].slice(0,2),[qs[1][3],qs[1][2]]],WOOD);for(let i=0;i<4;i++){let n=(i+1)%4;m.panel([[qs[0][i],qs[0][n]],[qs[1][i],qs[1][n]]],WOOD)}}
 // Open rear entry. Cut-away waist rail and leather-lashed corners keep the passenger visible.
 for(const s of [-1,1]){
  const x=s*.622;for(const [z,y] of [[-2.39,1.125],[-1.78,1.30],[-1.227,1.372]]){
   m.line([[x,.887,z],[x,y+.031,z]],[.037,.027],WOOD,smallWheel(high));
   if(high)m.line([[x,y-.031,z],[x,y+.014,z]],.036,STRAP,6);
  }
  m.line([[x,1.125,-2.39],[x,1.267,-1.875],[x,1.37,-1.227]],[.029,.029,.036],WOOD,smallWheel(high))
  m.line([[x,1.015,-2.38],[x,1.103,-1.78],[x,1.142,-1.227]],[.024,.025,.025],WOOD,smallWheel(high))
 }
 m.line([[-.63,1.37,-1.228],[.63,1.37,-1.228]],.036,WOOD,smallWheel(high))
 m.line([[-.63,1.145,-1.228],[.63,1.145,-1.228]],.027,WOOD,smallWheel(high))
 if(high){for(let k=0;k<9;k++){let x=(k-4)*.131;m.line([[x-.042,.956,-1.226],[x+.039,1.145,-1.226]],[.012,.012],HIDE,4)}}
}
function smallWheel(high){return high?7:4}
// The hand-directed atlas uses coarse to fine strokes along hair, woven warp/weft, 
// worn edges, hammered metal and growth rings. Avoid specular "plastic" on the cloth.
const palette=[[112,83,68],[155,126,102],[64,51,44],[71,65,57],[48,42,40],[93,80,73],[111,71,46],[71,51,39],[126,68,54],[54,68,75],[177,139,81],[140,110,67],[128,94,57],[73,76,73],[37,32,26],[197,177,138]];
function noise(x,y,seed){let v=Math.imul(x+seed*631,0x1e35a7bd)^Math.imul(y+seed*97,0x48d2a33d);v=Math.imul(v^(v>>>16),0x45d9f3b);return ((v^(v>>>13))>>>0)/4294967296}
// Broad anatomical colour planes read in the real cavalry view. The ribs turn
// under the saddle, the flank tucks up behind them and the cheek meets a dark muzzle.
function coatPlanes(u,v){
 const z=(u-.03125)/.9375*2.25-.95, y=1.95-(v-.03125)/.9375*1.92;
 function wash(cz,cy,rz,ry,slope=0){
  const x=(z-cz)/rz,h=(y-cy-slope*(z-cz))/ry;
  return Math.exp(-x*x-h*h);
 }
 return 12*wash(-.54,1.13,.24,.166,.49)-10*wash(-.34,.975,.166,.131,-.69)
       +7*wash(-.523,.939,.118,.217,-.61)-6*wash(-.675,.924,.058,.174,.63)
       +13*wash(.34,1.12,.151,.194,-.58)-10*wash(.17,1.018,.122,.167,-.51)
       -16*wash(-.02,.78,.51,.115)+15*wash(.58,1.47,.19,.088,1.14)
       -22*wash(.68,1.50,.18,.077,.98)+16*wash(.91,1.669,.11,.09,-.39)
       -25*wash(1.17,1.573,.135,.075,-.32)+8*wash(-.04,1.30,.32,.092);
}
function atlas(){
 const px=new Uint8Array(N*N*3);
 for(let y=0;y<N;y++)for(let x=0;x<N;x++){
  const tile=(x>>6)+4*(y>>6),u=x%T,v=y%T,X=(u+.5)/64,Y=(v+.5)/64;
  const grit=noise(u,v,tile)-.5, low=(noise(u>>3,v>>3,tile)-.5),ang=TAU*(X+.03*Math.sin(8*Y)),i=(y*N+x)*3;
  let a=2*grit,b=0;
  if(tile<=2||tile===4||tile===15){let drift=5*Math.sin(.035*v+tile)+3*Math.sin(.071*v);let fur=noise(Math.floor((u+drift)*1.3),v>>3,tile+5)-.5; a=8*fur+8*grit+8*Math.sin(ang-.58)*Math.sin(Math.PI*Y)+3*low;b=2.3*Math.sin(Y*PI);}
  else if(tile===3){a=11*Math.cos(2*PI*(X*11+.04*Math.sin(Y*7)))+6*grit+12*(Y-.5)}
  else if(tile===5||tile===14){a=4*grit+11*Math.cos(ang)*Math.cos(3*Y);}
  else if(tile===6||tile===7){let pores=noise(u>>1,v>>1,tile);a=9*grit+4*low-8*(pores>.88?1:0)+4*Math.sin((X+.03*Math.sin(Y*8))*17);b=-2*Math.sin(5*Y)}
  else if(tile>=8&&tile<=10){const warp=((u+Math.floor(v/9))%3===0)?4:-2,weft=(v%4===0)?4:-1;a=warp+weft+6*grit+4*low;if(tile===10)a+=Math.sin(TAU*(u/12+v/30))*4;}
  else if(tile===12){a=7*Math.sin((X+0.035*Math.sin(Y*8)+.02*Math.sin(Y*13+X*3))*TAU*6)+5*Math.sin((X+.015*Math.sin(Y*12))*TAU*18)+4*grit+3*low;}
  else {a=12*grit+8*low+4*Math.sin(5*ang+Y);b=tile===11?3*low:0;}
  if(tile===COAT||tile===LIGHT) a=coatPlanes(X,Y)+2.8*grit+2.0*low;
  if(tile===HAIR) a=.36*a+3*Math.sin((X+.09*Y)*PI*3);
  if(tile===WOOL) {
   // Two quiet dyes alternate along the exposed lower border of the felt.
   const edge=Math.abs(Math.abs((Y*3+.5)%1-.5)-(.15+.42*(1.-X)));
   a=3*low+1.4*grit+(X>.72 && edge<.064 ? 11 : 0);
  }
  for(let c=0;c<3;c++)px[i+c]=clamp(Math.round(palette[tile][c]+a*(1.0-c*.1)+b*(1-c)),0,255)
 }
 return px;
}
const u32be=x=>new Uint8Array([x>>>24,(x>>>16)&255,(x>>>8)&255,x&255]);
function pngRGB(w,h,p){
 const tab=new Uint32Array(256);for(let i=0;i<256;i++){let x=i;for(let j=0;j<8;j++)x=(x&1)?(0xedb88320^(x>>>1)):x>>>1;tab[i]=x}
 const crc=a=>{let v=0xffffffff;for(let b of a)v=tab[(v^b)&255]^(v>>>8);return(v^0xffffffff)>>>0};
 const chunk=(name,data)=>{let body=concat([Array.from(name,c=>c.charCodeAt(0)),data]);return concat([u32be(data.length),body,u32be(crc(body))])};
 let raw=new Uint8Array((w*3+1)*h);for(let y=0;y<h;y++)raw.set(p.slice(y*w*3,(y+1)*w*3),y*(1+w*3)+1);
 let A=1,B=0;for(let b of raw){A=(A+b)%65521;B=(B+A)%65521}
 let z=[new Uint8Array([0x78,0x01])];for(let i=0;i<raw.length;i+=65535){let n=Math.min(65535,raw.length-i),m=(~n)&65535;z.push(new Uint8Array([i+n===raw.length?1:0,n&255,n>>8,m&255,m>>8]),raw.slice(i,i+n))}
 z.push(u32be(((B<<16)|A)>>>0));return concat([[137,80,78,71,13,10,26,10],chunk('IHDR',concat([u32be(w),u32be(h),[8,2,0,0,0]])),chunk('IDAT',concat(z)),chunk('IEND',[])])
}

function bake(){
 const models=[['SaddleClose',true,false],['SaddleRank',false,false],['DraughtClose',true,true],['DraughtRank',false,true]];
 const gltf={asset:{version:'2.0',generator:'Luanshi / original river gate mount sculpture'},scene:0,scenes:[{name:'RiverGateMounts',nodes:[0,1,2,3]}],nodes:[],meshes:[],bufferViews:[],buffers:[],accessors:[],images:[{uri:'mount-atlas.png'}],textures:[{source:0}],materials:[{name:'SaddleryAtlas',doubleSided:true,pbrMetallicRoughness:{baseColorTexture:{index:0},metallicFactor:0,roughnessFactor:.78}}]};
 const parts=[];let size=0;
 function view(a,comp,count,type,normalized=false,mn=null,mx=null,target=34962){let pad=(-size)&3;if(pad){parts.push(new Uint8Array(pad));size+=pad}let ix=gltf.bufferViews.length,bytes=new Uint8Array(a.buffer,a.byteOffset,a.byteLength);parts.push(bytes);gltf.bufferViews.push({buffer:0,byteOffset:size,byteLength:a.byteLength,target});size+=a.byteLength;let out={bufferView:ix,componentType:comp,count,type};if(normalized)out.normalized=true;if(mn)out.min=mn;if(mx)out.max=mx;return gltf.accessors.push(out)-1}
 let stats=[];
 for(let [name,high,tow] of models){
  const m=new Sculpt();if(high)horse(m,true,tow);else rankHorse(m,tow);if(tow)cart(m,high);
  if(m.p.some(p=>p.some(v=>!Number.isFinite(v)))||m.i.some(i=>i>=m.p.length))throw Error('invalid geometry');
  const canonical=x=>{const q=Math.round(Math.abs(x)*1e5+1e-7)/1e5;return q===0?0:Math.sign(x)*q};
  const p=new Float32Array(m.p.flat().map(canonical)),nn=new Float32Array(m.n.map(unit).flat().map(canonical)),t=new Uint16Array(m.t.flat().map(normUV)),j=new Uint16Array(m.j.flat().map(normUV));let mn=[0,1,2].map(axis=>Math.fround(Math.min(...m.p.map(v=>canonical(v[axis]))))),mx=[0,1,2].map(axis=>Math.fround(Math.max(...m.p.map(v=>canonical(v[axis])))));let v=m.p.length;
  let prim={attributes:{POSITION:view(p,5126,v,'VEC3',false,mn,mx),NORMAL:view(nn,5126,v,'VEC3'),TEXCOORD_0:view(t,5123,v,'VEC2',true),TEXCOORD_1:view(j,5123,v,'VEC2',true)},indices:view(new Uint16Array(m.i),5123,m.i.length,'SCALAR',false,null,null,34963),material:0,mode:4};
  gltf.nodes.push({name,mesh:gltf.meshes.length});gltf.meshes.push({name,primitives:[prim]});stats.push([name,v,m.i.length/3]);
 }
 gltf.buffers.push({uri:'mounts.bin',byteLength:size});return {gltf:JSON.stringify(gltf,null,2)+'\n',bin:concat(parts),png:pngRGB(N,N,atlas()),stats}
}

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const outdir=fileURLToPath(new URL('../../assets/art/mounts/',import.meta.url));
const cooked=bake();
const check=process.argv.includes('--check');
if(!check)mkdirSync(outdir,{recursive:true});
for(const [name,val] of [['mounts.gltf',cooked.gltf],['mounts.bin',cooked.bin],['mount-atlas.png',cooked.png]]){
 const dest=path.join(outdir,name), buf=Buffer.from(val);
 if(check){if(!readFileSync(dest).equals(buf))throw Error('Stale authored asset: '+name)}else writeFileSync(dest,buf);
}
console.log(JSON.stringify(cooked.stats));
