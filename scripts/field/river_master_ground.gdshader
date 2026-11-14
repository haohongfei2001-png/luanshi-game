shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D soil : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D leaves : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D gravel : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D soil_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D gravel_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform bool bridgehead = false;
uniform vec3 road_pigment : source_color = vec3(.53,.445,.33);
uniform vec3 grass_pigment : source_color = vec3(.255,.32,.19);
uniform vec3 litter_pigment : source_color = vec3(.37,.325,.23);
varying vec3 world;
varying vec3 terrain_normal;

void vertex() {
	world = (MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	terrain_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float noise(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.-2.*f);
	return mix(mix(hash(a),hash(a+vec2(1.,0.)),f.x),
		mix(hash(a+vec2(0.,1.)),hash(a+vec2(1.)),f.x),f.y);
}
vec3 linear_color(vec3 color) {
	if (!OUTPUT_IS_SRGB) return color;
	return mix(color/12.92,pow((color+vec3(.055))/1.055,vec3(2.4)),step(vec3(.04045),color));
}
vec3 render_color(vec3 color) {
	if (!OUTPUT_IS_SRGB) return color;
	color = max(color,vec3(0.));
	return mix(color*12.92,1.055*pow(color,vec3(1./2.4))-vec3(.055),step(vec3(.0031308),color));
}
vec3 surface_color(vec3 sample_color,vec3 pigment,float median) {
	sample_color = linear_color(sample_color);
	pigment = linear_color(pigment);
	float value = dot(sample_color,vec3(.2126,.7152,.0722));
	float pigment_value = dot(pigment,vec3(.2126,.7152,.0722));
	vec3 native_chroma = sample_color/max(value,.012);
	vec3 color = mix(native_chroma*pigment_value,pigment,.58);
	return color*pow(clamp(value/median,.28,2.3),.68);
}
vec3 surface_normal(vec2 xy) {
	return normalize(vec3(xy,sqrt(max(.02,1.-dot(xy,xy)))));
}
float forest_patch(vec2 p,vec2 center,vec2 radii) {
	return 1.-smoothstep(.62,1.15,length((p-center)/radii));
}
void fragment() {
	vec2 p = world.xz;
	float drift = .30*sin(p.x*.13)+.23*sin(p.x*.31+.4);
	float broken_edge = (noise(p*.63)-.5)*1.4+(noise(p*.14)-.5)*2.;
	float lane = 1.-smoothstep(3.,6.7,abs(p.y-drift)+broken_edge);
	float branches = 1.-smoothstep(1.8,4.6,abs(p.y-35.)+broken_edge);
	branches = max(branches,1.-smoothstep(1.8,4.6,abs(p.y+35.)+broken_edge));
	lane = max(lane,(1.-smoothstep(-36.,-17.,p.x))*branches);
	float court = smoothstep(47.,52.,p.x)*(1.-smoothstep(85.,90.,p.x))
		*(1.-smoothstep(15.,21.,abs(p.y)));
	lane = max(lane,court);
	float bank = 1.-smoothstep(4.9,8.4,abs(p.x+32.)+broken_edge*.65);
	if (bridgehead) {
		bank = max(bank,(1.-smoothstep(4.2,8.,abs(p.x-24.)+broken_edge*.65))
			*(1.-smoothstep(23.,29.,abs(p.y))));
	}
	float forest = max(forest_patch(p,vec2(38.,-19.),vec2(9.,11.)),
		forest_patch(p,vec2(39.,24.),vec2(10.,12.)));
	forest = max(forest,forest_patch(p,vec2(-2.,39.),vec2(20.,16.)));
	forest = max(forest,forest_patch(p,vec2(-87.,-44.),vec2(34.,19.)));
	forest = max(forest,forest_patch(p,vec2(-85.,42.),vec2(28.,17.)));
	forest = max(forest,forest_patch(p,vec2(94.,46.),vec2(31.,18.)));
	forest = max(forest,forest_patch(p,vec2(113.,-43.),vec2(21.,17.)));
	float patches = noise(p*.17)*.62+noise(p*.49)*.38;
	float grass_pockets = smoothstep(.35,.70,patches);
	vec2 dust_uv = p/2.6;
	vec2 turf_uv = mat2(vec2(.8,-.6),vec2(.6,.8))*p/3.;
	vec2 gravel_uv = p/2.5+vec2(.17,.43);
	vec3 dust = surface_color(texture(soil,dust_uv).rgb,road_pigment,.108);
	vec3 turf = surface_color(texture(grass,turf_uv).rgb,grass_pigment,.23);
	vec3 litter = surface_color(texture(leaves,p/3.8).rgb,litter_pigment,.107);
	vec3 stones = surface_color(texture(gravel,gravel_uv).rgb,road_pigment*.91,.16);
	float gravel_pockets = smoothstep(.44,.70,noise(p*.31+vec2(6.2,2.7)));
	float gravel_weight = gravel_pockets*clamp(.26+bank*.55+court*.40,0.,.85);
	dust = mix(dust,stones,gravel_weight);
	float bare = clamp(lane+bank*.62+(patches-.68)*.42,0.,1.);
	vec3 verge = mix(turf,mix(litter,turf,.24+.33*grass_pockets),forest*.86);
	vec3 col = mix(verge,dust,bare);
	float rut = 0.;
	for (int i=0;i<2;i++) {
		float lateral = i==0 ? -1.18 : 1.18;
		float d = (p.y-drift-lateral)/.16;
		rut += exp(-d*d);
	}
	col *= 1.-.12*rut*lane;
	ALBEDO = render_color(col*mix(.90,1.08,noise(p*.08))*(1.-forest*.14));
	vec2 dust_slope = texture(soil_normal,dust_uv).xy*2.-1.;
	vec2 turf_slope = texture(grass_normal,turf_uv).xy*2.-1.;
	turf_slope = mat2(vec2(.8,.6),vec2(-.6,.8))*turf_slope;
	vec2 gravel_slope = texture(gravel_normal,gravel_uv).xy*2.-1.;
	vec3 relief = surface_normal(mix(turf_slope,mix(dust_slope,gravel_slope,gravel_weight),bare)*.42);
	vec3 up = normalize(terrain_normal);
	vec3 east = normalize(vec3(1.,0.,0.)-up*up.x);
	vec3 south = normalize(cross(east,up));
	vec3 local_normal = east*relief.x-south*relief.y+up*relief.z;
	NORMAL = normalize((VIEW_MATRIX*vec4(local_normal,0.)).xyz);
	ROUGHNESS = .97;
	SPECULAR = .0;
}
