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
 pt(p,mat,u,v,j=0,w=1){const k=this.p.length;this.p.push(p);this.n.push([0,0,0]);this.t.push(atlasUV(mat,u,v));this.j.push([(j+.5)/32,w]);return k}
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

function horse(m, high, draught){
 const body=high?14:8, neck=high?12:8, limb=high?8:5, small=high?7:5;
 // Barrel: croup, tucked flank, deep rib cage and prominent withers. Ventral line rises aft.
 m.skin([[0,1.035,-.85,.085,.09],[0,1.085,-.77,.245,.223],[0,1.085,-.60,.319,.302],[0,1.065,-.43,.335,.306],[0,1.045,-.20,.295,.28],[0,1.047,.04,.315,.316],[0,1.06,.26,.333,.342],[0,1.087,.44,.295,.342],[0,1.083,.58,.198,.255],[0,1.077,.65,.087,.153]],body,COAT)
 // Neck incl. crest, throat and jaw: the taper follows a rising diagonal rather than a cone.
 m.skin([[0,1.115,.28,.238,.26,11,0],[0,1.24,.37,.238,.30,11,.08],[0,1.365,.49,.202,.268,11,.23],[0,1.52,.60,.155,.21,11,.53],[0,1.66,.694,.137,.172,11,.77],[0,1.76,.758,.111,.119,11,.96]],neck,COAT)
 m.skin([[0,1.722,.695,.064,.095,11],[0,1.753,.763,.139,.149,11],[0,1.732,.862,.15,.18,11],[0,1.694,.958,.122,.147,11],[0,1.624,1.067,.096,.108,11],[0,1.58,1.151,.096,.088,11],[0,1.56,1.187,.082,.068,11]],neck,COAT)
 m.skin([[0,1.592,1.119,.090,.074,11],[0,1.56,1.183,.099,.075,11],[0,1.543,1.231,.086,.053,11],[0,1.544,1.244,.066,.035,11]],small,MUZZLE)
 // Two ears, dark inner pinnae, black eyes under an orbital ridge and fleshy nostrils.
 for(const s of [-1,1]){
  m.skin([[s*.079,1.831,.765,.047,.059,11],[s*.094,1.895,.765,.045,.052,11],[s*.116,1.960,.758,.030,.035,11],[s*.13,2.005,.75,.007,.011,11]],high?7:4,POINT,[1,0,0]);
  if(high){
   m.strip([[s*.077,1.863,.797],[s*.083,1.924,.797],[s*.126,1.971,.769]],[[s*.110,1.865,.786],[s*.125,1.923,.779],[s*.128,1.972,.766]],MUZZLE,11)
   m.oval([s*.138,1.751,.898],[.012,.026,.039],EYE,8,11)
   m.line([[s*.124,1.771,.929],[s*.148,1.786,.89],[s*.145,1.782,.848]],[.008,.016,.009],POINT,5,11)
   m.oval([s*.148,1.763,.906],[.003,.006,.005],FLAX,5,11)
   m.oval([s*.0855,1.574,1.214],[.007,.02,.025],EYE,7,11)
   m.line([[s*.083,1.513,1.185],[s*.070,1.515,1.228],[s*.043,1.521,1.246]],.0055,POINT,4,11)
  }else{m.oval([s*.142,1.754,.898],[.009,.018,.029],EYE,5,11)}
 }
 if(high){
  // A narrow irregular forehead star continues into a broken strip along the nasal bridge.
  m.strip([[-.022,1.884,.835],[-.031,1.875,.884],[-.010,1.843,.933],[-.012,1.755,1.031]],[[.014,1.884,.835],[.031,1.875,.883],[.020,1.843,.933],[.002,1.755,1.031]],FLAX,11)
 }
 // Mane skin sections, separate forelock and one coherent tapering tail.
 let crest=[[0,1.47,.257,.042,.055,11,0],[-.018,1.57,.346,.054,.069,11,.1],[-.030,1.702,.47,.047,.063,11,.43],[-.034,1.819,.603,.043,.052,11,.73],[-.018,1.877,.72,.032,.038,11,1],[0,1.867,.794,.028,.026,11,1]];
 m.skin(crest,high?7:5,HAIR);
 m.skin([[0,1.861,.76,.034,.033,11],[-.025,1.877,.824,.047,.033,11],[-.043,1.848,.884,.035,.027,11],[-.064,1.816,.922,.007,.008,11]],small,HAIR)
 if(high) for(let i=0;i<7;i++){
  let t=i/7,z=.30+.398*t,y=1.445+.397*t; m.strip([[-.042,y+.043,z+.025],[-.064,y+.021,z-.019],[-.116,y-.05,z-.075]], [[-.041,y+.04,z+.084],[-.083,y+.006,z+.03],[-.117,y-.05,z-.072]],HAIR,11)
 }
 m.skin([[0,1.299,-.696,.073,.060,12,0],[0,1.237,-.826,.094,.090,12,.10],[-.014,1.026,-.958,.079,.107,12,.33],[-.029,.813,-1.005,.072,.11,12,.56],[-.052,.608,-1.006,.049,.077,12,.85],[-.064,.474,-1.036,.011,.033,12,1]],high?9:5,HAIR)
 for(const s of [-1,1]){
  // Front: pectoral overlap → elbow → carpus → fetlock → inclined pastern and hoof.
  // Back: gluteal → stifle (forward) → projecting hock → cannon/pastern.
  for(const hind of [false,true]){
   const g=(hind?3:1)+(s>0?1:0);
   const profile=hind?[[.190,1.215,-.56,.145,.196],[.215,1.029,-.6,.132,.167],[.215,.833,-.488,.096,.117],[.212,.744,-.511,.094,.094],[.217,.553,-.679,.055,.073],[.219,.50,-.706,.049,.065],[.217,.447,-.677,.041,.049],[.216,.238,-.637,.036,.045],[.216,.167,-.636,.052,.052],[.216,.110,-.608,.045,.043]]:
    [[.191,1.20,.356,.125,.158],[.212,1.012,.40,.134,.152],[.218,.850,.34,.091,.117],[.218,.775,.335,.081,.094],[.219,.588,.396,.058,.064],[.219,.505,.426,.055,.066],[.219,.447,.419,.041,.048],[.219,.236,.408,.033,.040],[.219,.166,.414,.049,.051],[.219,.109,.446,.042,.041]];
   let pp=profile.map(q=>[s*q[0],q[1],q[2],q[3],q[4],g]);
   m.skin(high?pp:pp.filter((v,i)=>[0,2,4,5,8,9].includes(i)),limb,COAT);
   let bot=pp.slice(5).map(r=>[r[0],r[1],r[2],r[3]+.0025,r[4]+.0025,g]);m.skin(high?bot:[bot[0],bot[2],bot[4]],limb,POINT);
   let z=hind?-.607:.447,x=s*.218; m.skin([[x,.128,z,.044,.051,g],[x,.095,z+.008,.051,.06,g],[x,.041,z+.031,.064,.08,g],[x,.013,z+.035,.062,.080,g]],limb,HOOF)
  }
 }
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
   let zs=[-.5,-.40,-.17,.05,.226,.282],ns=[1.078,1.02,.995,1.015,1.045,1.115];let rows=[];
   for(let k=0;k<zs.length;k++){let z=zs[k],y=ns[k];rows.push([[0,1.392,z],[s*.180,1.354,z],[s*.274,1.256,z],[s*.298,y+.06,z],[s*.309,y,z]])}
   m.panel(rows,WOOL);m.strip(rows.map(r=>add(r[4],[s*.002,.012,0])),rows.map(r=>add(r[4],[s*.003,.045,0])),PIPING);
   if(high){m.strip(rows.map(r=>add(r[4],[s*.004,.054,0])),rows.map(r=>add(r[4],[s*.004,.080,0])),BLUE)}
   m.line([[s*.234,1.355,-.043],[s*.314,1.184,-.053],[s*.324,.958,-.071],[s*.321,.851,-.056]],.015,HIDE,high?5:4);
   let iron=[[s*.32,.873,-.064],[s*.324,.835,-.121],[s*.323,.753,-.124],[s*.324,.746,.007],[s*.323,.831,.006],[s*.32,.873,-.064]];m.line(iron,.014,IRON,high?5:3);
   m.strip([[s*.269,1.28,.171],[s*.316,1.13,.127],[s*.30,.897,.093],[s*.212,.775,.070]],[[s*.271,1.279,.225],[s*.319,1.131,.184],[s*.302,.898,.155],[s*.215,.773,.134]],STRAP)
  }
  m.skin([[0,1.389,-.38,.11,.020],[0,1.426,-.326,.212,.084],[0,1.412,-.225,.207,.053],[0,1.392,-.04,.183,.055],[0,1.403,.115,.186,.042],[0,1.439,.193,.18,.059],[0,1.42,.243,.117,.032]],high?12:7,HIDE);
 }else{
  // Padded breast collar (not a rider saddle), traces lead rearward to each shaft.
  for(const s of [-1,1]){m.skin([[s*.258,1.255,.29,.04,.049],[s*.309,1.129,.405,.047,.06],[s*.314,.99,.483,.055,.061],[s*.21,.935,.561,.054,.057],[0,.907,.595,.041,.048]],small,HIDE);m.line([[s*.31,1.015,.453],[s*.365,.940,-.004],[s*.443,.911,-.675],[s*.54,.836,-1.237]],.017,STRAP,small);}
  m.strip([[-.29,1.12,-.031],[-.20,1.343,-.031],[0,1.397,-.031],[.20,1.343,-.031],[.29,1.12,-.031]],[[-.29,1.12,.044],[-.20,1.343,.044],[0,1.397,.044],[.20,1.343,.044],[.29,1.12,.044]],HIDE);
 }
}

// Distance version is separately authored. Keep forward face, raised hocks, saddlecloth,
// hoof tips and rein silhouette; omit overlap shells, eye glints and individual bridles.
function rankHorse(m,tow){
 m.skin([[0,1.065,-.841,.073,.091],[0,1.088,-.594,.314,.299],[0,1.047,-.169,.292,.296],[0,1.071,.313,.332,.345],[0,1.077,.605,.164,.208]],7,COAT)
 m.skin([[0,1.146,.3,.225,.26,11,0],[0,1.447,.539,.18,.24,11,.43],[0,1.757,.753,.106,.109,11,1]],6,COAT)
 m.skin([[0,1.728,.709,.083,.10,11],[0,1.739,.861,.143,.168,11],[0,1.636,1.047,.096,.103,11],[0,1.554,1.208,.082,.054,11]],5,COAT)
 m.skin([[0,1.563,1.17,.097,.068,11],[0,1.541,1.239,.074,.04,11]],5,MUZZLE)
 m.skin([[0,1.474,.253,.037,.048,11,0],[-.02,1.693,.467,.053,.065,11,.4],[0,1.865,.761,.036,.034,11,1]],4,HAIR)
 m.skin([[0,1.289,-.70,.065,.068,12,0],[-.01,1.04,-.943,.085,.107,12,.33],[-.031,.769,-1.005,.064,.094,12,.65],[-.067,.474,-1.036,.017,.027,12,1]],5,HAIR)
 for(const s of [-1,1]){
  m.skin([[s*.08,1.829,.765,.045,.051,11],[s*.10,1.92,.759,.04,.044,11],[s*.13,2.005,.75,.005,.009,11]],4,POINT);
  for(const h of [false,true]){
   let j=(h?3:1)+(s>0?1:0),x=s*.217,z=h?-.608:.446;
   let leg=h?[[1.14,-.56,.119,.147],[.826,-.479,.099,.115],[.502,-.705,.054,.068],[.171,-.637,.043,.049],[.113,z,.039,.041]]:[[1.145,.368,.123,.152],[.816,.329,.087,.105],[.509,.425,.051,.064],[.177,.413,.045,.052],[.113,z,.039,.041]];
   m.skin(leg.map(r=>[x,r[0],r[1],r[2],r[3],j]),4,COAT);
   m.skin([[x,.124,z,.045,.044,j],[x,.035,z+.034,.062,.078,j],[x,.012,z+.035,.06,.073,j]],4,HOOF);
  }
  let r=tow?[[s*.105,1.563,1.14],[s*.32,1.34,.04],[s*.36,1.41,-1.10],[s*.18,1.66,-1.60]]:[[s*.105,1.563,1.14],[s*.244,1.445,.70],[s*.17,1.594,.24]];
  m.strip(r.map(p=>add(p,[0,-.011,0])),r.map(p=>add(p,[0,.011,0])),STRAP,11)
  if(!tow){
   let left=[[0,1.387,-.46],[s*.24,1.286,-.455],[s*.304,1.022,-.426]],right=[[0,1.387,.255],[s*.24,1.285,.254],[s*.307,1.067,.231]];
   m.panel([left,right],WOOL);m.strip([left[2],right[2]],[add(left[2],[s*.002,.042,0]),add(right[2],[s*.002,.04,0])],PIPING)
  }else{m.line([[s*.30,1.17,.365],[s*.316,.992,.491],[0,.913,.59]],.042,HIDE,4);m.line([[s*.31,1.013,.452],[s*.44,.89,-.68],[s*.54,.836,-1.237]],.016,STRAP,3);}
 }
 if(!tow)m.skin([[0,1.426,-.337,.199,.073],[0,1.391,-.025,.18,.052],[0,1.439,.192,.174,.059]],6,HIDE);
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
const palette=[[124,77,53],[142,90,61],[69,47,36],[72,67,56],[47,38,33],[90,72,64],[111,71,46],[71,51,39],[126,68,54],[54,68,75],[177,139,81],[140,110,67],[128,94,57],[73,76,73],[37,32,26],[197,177,138]];
function noise(x,y,seed){let v=Math.imul(x+seed*631,0x1e35a7bd)^Math.imul(y+seed*97,0x48d2a33d);v=Math.imul(v^(v>>>16),0x45d9f3b);return ((v^(v>>>13))>>>0)/4294967296}
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
  const p=new Float32Array(m.p.flat()),nn=new Float32Array(m.n.map(unit).flat()),t=new Uint16Array(m.t.flat().map(normUV)),j=new Uint16Array(m.j.flat().map(normUV));let mn=[0,1,2].map(axis=>Math.fround(Math.min(...m.p.map(v=>v[axis])))),mx=[0,1,2].map(axis=>Math.fround(Math.max(...m.p.map(v=>v[axis]))));let v=m.p.length;
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
