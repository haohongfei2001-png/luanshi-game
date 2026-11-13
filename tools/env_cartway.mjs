// Draw the worn surface between the central bridge and River Gate in ground metres.
import {readFileSync,writeFileSync} from "node:fs";
const root=new URL("../assets/environment/",import.meta.url);
const road=JSON.parse(readFileSync(new URL("foothills.json",root))).roads[0].points;
const marks=['<svg xmlns="http://www.w3.org/2000/svg" width="1792" height="400" viewBox="-25 -8 72 16" preserveAspectRatio="none">','<rect x="-25" y="-8" width="72" height="16" fill="#000"/>'];
let seed=99817;
const random=()=>((seed=(Math.imul(seed,1664525)+1013904223)>>>0)/4294967296);
const range=(low,high)=>low+(high-low)*random();
function center(x) {
    const k=Math.max(0,road.findIndex((p,i)=>i+1<road.length&&road[i+1][0]>=x));
    const a=road[k],b=road[k+1],u=(x-a[0])/(b[0]-a[0]);
    const y0=road[Math.max(0,k-1)][1],y1=a[1],y2=b[1],y3=road[Math.min(road.length-1,k+2)][1];
    return .5*(2*y1+(y2-y0)*u+(2*y0-5*y1+4*y2-y3)*u*u+(-y0+3*y1-3*y2+y3)*u*u*u);
}
const xyz=(x,z)=>[+x.toFixed(3),+(center(x)+z).toFixed(3)].join(" ");
function polygon(upper,lower,ink) {
    const points=upper.concat(lower.reverse());
    marks.push('<path fill="'+ink+'" d="M'+points.join(" L")+' Z"/>');
}
function colour(r,g,b) {return "#"+[r,g,b].map(v=>Math.round(v).toString(16).padStart(2,"0")).join("");}
function wheel(x,side) {
    return .19*Math.sin(x*.28)+.073*Math.sin(x*.83+.35)+side*(1.10+.10*Math.sin(.18*x+1.8));
}
// Compaction varies from a broad hollow in damp earth to barely a line on stone.
// The two tracks share a route but lose and regain their edges at different points.
for (const side of [-1,1]) {
    let x=-26+range(0,1.5);
    while (x<48) {
        const length=range(1.8,6.7),width=range(.105,.235),phase=range(0,6.28);
        const top=[],bottom=[],inside=[],outside=[];
        const sections=Math.max(5,Math.ceil(length/.32));
        for (let i=0;i<=sections;i++) {
            const t=i/sections,at=x+length*t,z=wheel(at,side);
            const taper=Math.pow(Math.max(0,Math.sin(Math.PI*t)),.49);
            const w=width*taper*(.95+.20*Math.sin(t*8+phase));
            const lip=z-w*.89;
            top.push(xyz(at,z+w));bottom.push(xyz(at,z-w));
            inside.push(xyz(at,lip+w*.11));outside.push(xyz(at,lip-w*.22));
        }
        polygon(top,bottom,colour(range(84,158),0,0));
        polygon(inside,outside,colour(0,range(54,132),0));
        x+=length+range(.24,2.45);
    }
}
// Low scalloped bites in the sod, just outside the worn road. Group them at
// bends and leave long stretches of plain verge for the line of battle.
for (const [start,side,count] of [[-21,-1,4],[-13,1,3],[-7,-1,7],[.8,1,6],[4,-1,5],[13,-1,6],[23,1,7],[34,-1,6],[39,1,5]]) {
    let x=start;
    for(let cut=0;cut<count;cut++) {
        const len=range(.60,2.30),z=side*range(3.51,4.20),d=range(.27,.61);
        const top=[],bottom=[];
        for(let i=0;i<=6;i++){
            const t=i/6,at=x+len*t;
            const push=Math.sin(Math.PI*t)*(d+.06*Math.sin(11*t));
            top.push(xyz(at,z+side*push));
            bottom.push(xyz(at,z-side*push*.53));
        }
        polygon(top,bottom,colour(0,0,range(98,164)));
        x+=len*range(.88,1.72);
    }
}
// Broad flat chips accumulate on the inner shoulder and the stonier gate approach.
// Each is a low asymmetric lozenge with a worn light end, grouped rather than tiled.
for (const [where,side,number] of [[-19,1,9],[-8,-1,7],[1,-1,13],[8,1,10],[16,-1,11],[27,1,14],[36,-1,17],[42,1,21]]) {
    for(let i=0;i<number;i++){
        const x=where+range(-1.4,2.3),z=side*range(2.04,3.49);
        const l=range(.10,.44),h=range(.05,.15),lean=range(-.29,.29)*l;
        const coords=[[x-l*.91,z-h*.28],[x-l*.53,z-h*.82],[x+l*.42,z-h+lean*.4],[x+l,z-h*.18+lean],[x+l*.57,z+h*.50+lean],[x-l*.30,z+h]];
        const top=coords.map(([a,b])=>xyz(a,b));
        polygon(top,[],colour(0,range(82,172),0));
    }
}
const asset=marks.join("\n")+"\n</svg>\n";
const dst=new URL("river-cartway.svg",root);
if (process.argv.includes("--check")) {
    if (readFileSync(dst,"utf8")!==asset) throw new Error("River cartway atlas differs from authoring source");
} else writeFileSync(dst,asset);
