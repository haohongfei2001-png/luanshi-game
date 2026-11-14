// A north-up military survey of the shipping river map. Units and the view
// are drawn in Godot over this static, original illustration.
import {readFileSync,writeFileSync} from "node:fs";
const root=new URL("../assets/environment/",import.meta.url);
const plan=JSON.parse(readFileSync(new URL("foothills.json",root),"utf8"));

function survey(plan) {
    const parts=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 236 128" width="708" height="384">','<rect width="236" height="128" fill="#35463e"/>','<g transform="translate(118 64)">'];
    const add = tag => parts.push(tag);
    const fmt = value => value.toFixed(2);
    function ellipse(cx,cz,rx,rz,fill,angle=0) {
        add(`<ellipse cx="${fmt(cx)}" cy="${fmt(cz)}" rx="${fmt(rx)}" ry="${fmt(rz)}" transform="rotate(${fmt(angle)} ${fmt(cx)} ${fmt(cz)})" fill="${fill}"/>`);
    }
    const route=(points,colour,width)=>add(`<polyline points="${points.map(p=>p.map(fmt).join(",")).join(" ")}" fill="none" stroke="${colour}" stroke-width="${width}" stroke-linejoin="round" stroke-linecap="round"/>`);
    // These nested irregular contours correspond to the two real ridges.
    for (const [cx,cz,rx,rz] of [[9,-36,34,16],[77,43,30,13]]) {
        for (let tier=0;tier<3;tier++) {
            const scale=1-.27*tier, points=[];
            for(let i=0;i<40;i++) {
                const a=i*Math.PI/20, lip=1+.044*Math.sin(a*3+.8)+.033*Math.cos(a*5+tier);
                points.push([cx+rx*scale*lip*Math.cos(a),cz+rz*scale*lip*Math.sin(a)]);
            }
            add(`<polygon points="${points.map(p=>p.map(fmt).join(",")).join(" ")}" fill="${["#455448","#50604d","#58644f"][tier]}"/>`);
            if (tier!==2) route(points.slice(19,36),"#6b755b",.42);
        }
    }
    for (const [x,z,rx,rz,angle] of plan.fields) {
        ellipse(x,z,rx,rz,"#505b46",angle*180/Math.PI);
        for (const shift of [-.30,.26]) {
            const a=[x-rx*.58,z+rz*shift-rx*.58*Math.sin(angle)];
            const b=[x+rx*.58,z+rz*shift+rx*.58*Math.sin(angle)];
            route([a,b],"#677052",.48);
        }
    }
    for(const [x,z,r] of plan.groves) {
        ellipse(x,z,r*1.18,r*.78,"#283e34",-12);
        ellipse(x-r*.13,z-r*.12,r*.86,r*.52,"#344e3b",-19);
    }
    for(const k of [1,.76]) {
        const a=[],b=[];
        for(let z=-65;z<=65;z+=2){
            const drift=.39*Math.sin(z*.26)+.34*Math.sin(z*.103+.7);
            a.push([-32-5.9*k+drift,z]); b.push([-32+5.9*k+drift*.59,z]);
        }
        add(`<polygon points="${[...a,...b.reverse()].map(p=>p.map(fmt).join(",")).join(" ")}" fill="${k===1?"#728178":"#547c7a"}"/>`);
    }
    for (const road of plan.roads) {
        route(road.points,"#323b32",road.width*.76);
        route(road.points,road.width>2?"#ad956e":"#8d8161",road.width*.43);
    }
    for(const z of [-35,0,35]) {
        route([[-38,z],[-26,z]],"#ccb28a",2.1);
    }
    add('<path d="M48 -23H89V23H48ZM-94 -15H-75V15H-94Z" fill="#454941" stroke="#988c70" stroke-width="1.15"/>');
    for (const z of [-22,22]) {
        for (const x of [48,88]) add(`<rect x="${x-1.6}" y="${z-1.6}" width="3.2" height="3.2" fill="#b0a184"/>`);
    }
    for(const z of [-11,-4,4,11]) route([[-91,z],[-80,z]],"#7d8167",1);
    route([[50,0],[85,0]],"#83795d",1.3);
    return parts.join("\n")+"\n</g>\n</svg>\n";
}
const data=survey(plan);
const path=new URL("river-survey.svg",root);
if(process.argv.includes("--check")) {
    if(readFileSync(path,"utf8")!==data) throw Error("Rebake the river survey");
} else {
    writeFileSync(path,data);
}
