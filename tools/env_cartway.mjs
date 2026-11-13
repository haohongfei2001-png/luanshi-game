// Paint cart wear in world metres between the central bridge and the gate.
import { readFileSync, writeFileSync } from "node:fs";

const directory = new URL("../assets/environment/", import.meta.url);
const road = JSON.parse(readFileSync(new URL("foothills.json", directory), "utf8")).roads[0].points;
const marks = [
    '<svg xmlns="http://www.w3.org/2000/svg" width="1792" height="400" viewBox="-25 -8 72 16" preserveAspectRatio="none">',
    '<rect x="-25" y="-8" width="72" height="16" fill="#000"/>',
];

let seed = 99817;
function range(low, high) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return low + (high - low) * (seed / 4294967296);
}

// The soil map uses the same Catmull-Rom centre through these waypoints.
function roadCenter(x) {
    const segment = road.findIndex((point, i) => i + 1 < road.length && road[i + 1][0] >= x);
    const start = road[segment], end = road[segment + 1];
    const t = (x - start[0]) / (end[0] - start[0]);
    const before = road[Math.max(0, segment - 1)][1], after = road[Math.min(road.length - 1, segment + 2)][1];
    const y = start[1], nextY = end[1];
    return 0.5 * (2 * y + (nextY - before) * t + (2 * before - 5 * y + 4 * nextY - after) * t * t
        + (-before + 3 * y - 3 * nextY + after) * t * t * t);
}

function point(x, offset) {
    return Number(x.toFixed(3)) + " " + Number((roadCenter(x) + offset).toFixed(3));
}

function polygon(upper, lower, ink) {
    const outline = upper.concat(lower.slice().reverse());
    marks.push('<path fill="' + ink + '" d="M' + outline.join(" L") + ' Z"/>');
}

function colour(red, green, blue) {
    return "#" + [red, green, blue].map(channel => Math.round(channel).toString(16).padStart(2, "0")).join("");
}

function wheelOffset(x, side) {
    const drift = 0.19 * Math.sin(x * 0.28) + 0.073 * Math.sin(x * 0.83 + 0.35);
    return drift + side * (1.10 + 0.10 * Math.sin(0.18 * x + 1.8));
}

// The wheels share an axle, but both sides do not stay pressed into the soil
// on every stretch. Each hollow tapers into the existing compacted road.
for (const side of [-1, 1]) {
    let x = -26 + range(0, 1.5);
    while (x < 48) {
        const length = range(1.8, 6.7), width = range(0.105, 0.235), phase = range(0, 6.28);
        const upper = [], lower = [], innerLip = [], outerLip = [];
        const sections = Math.max(5, Math.ceil(length / 0.32));
        for (let i = 0; i <= sections; i++) {
            const t = i / sections, at = x + length * t, z = wheelOffset(at, side);
            const taper = Math.pow(Math.max(0, Math.sin(Math.PI * t)), 0.49);
            const halfWidth = width * taper * (0.95 + 0.20 * Math.sin(t * 8 + phase));
            const lip = z - halfWidth * 0.89;
            upper.push(point(at, z + halfWidth));
            lower.push(point(at, z - halfWidth));
            innerLip.push(point(at, lip + halfWidth * 0.11));
            outerLip.push(point(at, lip - halfWidth * 0.22));
        }
        polygon(upper, lower, colour(range(84, 158), 0, 0));
        polygon(innerLip, outerLip, colour(0, range(54, 132), 0));
        x += length + range(0.24, 2.45);
    }
}

// Group short cuts by bends, with strips of undisturbed sod between them.
const sodCuts = [
    [-21, -1, 4], [-13, 1, 3], [-7, -1, 7], [0.8, 1, 6], [4, -1, 5],
    [13, -1, 6], [23, 1, 7], [34, -1, 6], [39, 1, 5],
];
for (const [start, side, count] of sodCuts) {
    let x = start;
    for (let cut = 0; cut < count; cut++) {
        const length = range(0.60, 2.30), z = side * range(3.51, 4.20), depth = range(0.27, 0.61);
        const upper = [], lower = [];
        for (let i = 0; i <= 6; i++) {
            const t = i / 6, at = x + length * t;
            const reach = Math.sin(Math.PI * t) * (depth + 0.06 * Math.sin(11 * t));
            upper.push(point(at, z + side * reach));
            lower.push(point(at, z - side * reach * 0.53));
        }
        polygon(upper, lower, colour(0, 0, range(98, 164)));
        x += length * range(0.88, 1.72);
    }
}

// The stone shoulder becomes more continuous towards the city.
const stoneBeds = [
    [-19, 1, 9], [-8, -1, 7], [1, -1, 13], [8, 1, 10],
    [16, -1, 11], [27, 1, 14], [36, -1, 17], [42, 1, 21],
];
for (const [start, side, count] of stoneBeds) {
    for (let i = 0; i < count; i++) {
        const x = start + range(-1.4, 2.3), z = side * range(2.04, 3.49);
        const length = range(0.10, 0.44), height = range(0.05, 0.15), lean = range(-0.29, 0.29) * length;
        const corners = [
            [x - length * 0.91, z - height * 0.28], [x - length * 0.53, z - height * 0.82],
            [x + length * 0.42, z - height + lean * 0.4], [x + length, z - height * 0.18 + lean],
            [x + length * 0.57, z + height * 0.50 + lean], [x - length * 0.30, z + height],
        ];
        polygon(corners.map(([at, offset]) => point(at, offset)), [], colour(0, range(82, 172), 0));
    }
}

const asset = marks.join("\n") + "\n</svg>\n";
const destination = new URL("river-cartway.svg", directory);
if (process.argv.includes("--check")) {
    if (readFileSync(destination, "utf8") !== asset) {
        throw new Error("River cartway atlas differs from its authoring source");
    }
} else {
    writeFileSync(destination, asset);
}
