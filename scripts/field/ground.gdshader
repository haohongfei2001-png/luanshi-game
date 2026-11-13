shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D fieldbed : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D joinery : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D cartway : filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D soil_cover : filter_linear_mipmap, repeat_disable;
uniform sampler2D field_margins : filter_linear_mipmap, repeat_disable;
uniform sampler2D valley_wash : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 turf_sheltered : source_color = vec4(.195,.277,.201,1.0);
uniform vec4 turf_open : source_color = vec4(.445,.517,.308,1.0);
uniform vec4 clay_bed : source_color = vec4(.435,.337,.242,1.0);
uniform vec4 clay_dry : source_color = vec4(.672,.555,.375,1.0);
uniform sampler2D shale_paint : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D meadow_paint : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grazing_detail : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D track_detail : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D lane_paint : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D verge_track : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 river_silt : source_color = vec4(.39,.40,.31,1.);
uniform vec4 deep_water : source_color = vec4(.13,.31,.34,1.0);
uniform vec4 shallows : source_color = vec4(.33,.48,.42,1.0);
varying vec3 local_pos;
varying vec3 local_normal;
varying float part;
varying vec3 pigment;

void vertex() {
	if(UV2.x>14.5 && UV2.x<15.5) {
		float loose=clamp((6.18-VERTEX.y)/1.7,0.0,1.0);
		VERTEX.x+=loose*.10*sin(TIME*2.2+VERTEX.z*1.9);
	}
	local_pos=VERTEX;
	local_normal=NORMAL;
	part=UV2.x;
	// The builder records the artist’s sRGB swatch in UV and UV2.y as well as COLOR.
	// Keep the compatibility palette and decode it once for a linear colour target.
	if (OUTPUT_IS_SRGB) {
		pigment=pow(max(COLOR.rgb,vec3(0.0)),vec3(1.30));
	} else {
		vec3 swatch=pow(clamp(vec3(UV,UV2.y),vec3(0.0),vec3(1.0)),vec3(1.30));
		vec3 linear_swatch=mix(swatch/12.92,pow((swatch+.055)/1.055,vec3(2.4)),step(vec3(.04045),swatch));
		// Measured against the reference art under the river gate sun and sky.
		// Only vertex-painted surfaces share this calibration. Scanned soil has its own albedo.
		pigment=min(linear_swatch*vec3(2.02,1.92,1.76),vec3(1.0));
	}
}

// Work in painted value for the mask, independent of the renderer's light space.
float paint_value(vec3 albedo) {
	vec3 ink=albedo;
	if (!OUTPUT_IS_SRGB) {
		ink=mix(12.92*albedo,1.055*pow(max(albedo,vec3(0.0)),vec3(1.0/2.4))-.055,step(vec3(.0031308),albedo));
	}
	return dot(ink,vec3(.26,.58,.16));
}

vec3 painted_ground(vec2 p, float shore) {
	vec2 mapped=(p+vec2(168.,108.))/vec2(336.,216.);
	vec4 cover=texture(soil_cover,mapped);
	vec3 margin=texture(field_margins,mapped).rgb;
	vec2 meadow_uv=vec2(p.x*.069+p.y*.021,p.y*.077-p.x*.019);
	vec2 loess_uv=vec2(p.y*.067+p.x*.012,-p.x*.082+p.y*.023);
	// Mirror the edge of each painting. The change of direction happens
	// continuously; no square border is exposed when a squad crosses a tile.
	vec2 bend=vec2(sin(.17*p.y+.071*p.x),sin(.16*p.x-.057*p.y))*.067;
	vec2 turf_tile=1.-abs(2.*fract((meadow_uv+bend)*.5)-1.);
	vec2 dirt_tile=1.-abs(2.*fract((loess_uv-bend)*.5)-1.);
	vec3 meadow=texture(meadow_paint,turf_tile).rgb;
	float grass=paint_value(meadow);
	float soil=paint_value(texture(lane_paint,dirt_tile).rgb);
	vec3 verge_marks=texture(verge_track,meadow_uv*1.41).rgb;
	float grass_shape=smoothstep(.28,.70,grass)*.78+.22*smoothstep(.25,.69,verge_marks.r);
	float dry_shape=smoothstep(.31,.73,soil);
	// Large shape and small-scale painting occupy different world footprints.
	// Averaging the swatches erased the dark grass at the feet and all of the
	// cartway grain in the regular 22 metre view.
	vec2 brush_uv=vec2(p.x*.134+p.y*.025,p.y*.141-p.x*.022);
	// At a player's distance a tuft is a group of blades. Sample a broad
	// colour island before the short verge marks; keep wheel tracks continuous.
	float footprint=max(length(dFdx(p)),length(dFdy(p)));
	float army_view=smoothstep(.012,.070,footprint);
	vec3 grass_brush=texture(grazing_detail,brush_uv+bend,.8+army_view*1.4).rgb;
	vec3 earth_brush=texture(track_detail,vec2(brush_uv.y,-brush_uv.x)*.87+bend*.67,.65+army_view).rgb;
	float tuft=smoothstep(.32,.62,grass)*.64+smoothstep(.28,.74,verge_marks.r)*.36;
	float shelter=clamp(.19+.42*grass_shape+.20*cover.b-.29*margin.g+.15*margin.r,0.,1.);
	vec3 blade=mix(vec3(dot(grass_brush,vec3(.29,.57,.14))),grass_brush,.61);
	vec3 loess=mix(vec3(dot(earth_brush,vec3(.29,.57,.14))),earth_brush,.37);
	blade*=OUTPUT_IS_SRGB?vec3(.73,.83,.87):vec3(.59,.68,.75);
	loess*=OUTPUT_IS_SRGB?vec3(.78,.78,.84):vec3(.62,.63,.73);
	vec3 bed=mix(turf_sheltered.rgb,turf_open.rgb,shelter+.18*(tuft-.5));
	vec3 turf=mix(blade,bed,.39+.07*army_view)*(.89+.19*tuft);
	turf*=mix(vec3(1.),vec3(.87,.96,1.08),margin.g*.72);
	turf*=mix(vec3(1.),vec3(1.09,1.01,.91),margin.r*.68);
	vec3 dust=mix(clay_bed.rgb,clay_dry.rgb,.15+.68*dry_shape);
	vec3 clay=mix(loess,dust,.36+.04*army_view)*(.92+.15*dry_shape);
	float centre=1.-smoothstep(.57,.99,cover.a);
	float fallow=smoothstep(.24,.58,cover.r)*(1.-smoothstep(.73,.9,cover.r))*(1.-centre);
	float edge=cover.r-.21*fallow+(.53-grass_shape)*.20+(.50-verge_marks.r)*.09;
	float road=smoothstep(.30,.76,edge);
	vec3 colour=mix(turf,clay,road);
	float lip=4.*road*(1.-road);
	colour*=1.-lip*(.05+.065*grass_shape);
	colour=mix(colour,clay,margin.b*(1.-road)*(.12+.18*dry_shape));
	float rut=1.-smoothstep(.027,.095,abs(cover.a-.385+(.5-verge_marks.g)*.036));
	float surviving=smoothstep(.37,.73,verge_marks.g*.53+dry_shape*.47);
	colour*=1.-.19*rut*road*surviving;
	if (p.x > -25. && p.x < 47. && p.y > -8. && p.y < 8.) {
		vec3 wear=texture(cartway,(p+vec2(25.,8.))/vec2(72.,16.)).rgb;
		colour*=1.-.22*wear.r*(.63+.37*dry_shape);
		colour=mix(colour,clay_dry.rgb,wear.g*.29);
		colour=mix(colour,mix(turf,clay_bed.rgb,.58),wear.b*.68);
	}
	// The old non-repeating survey painting carries the cuts of the real
	// field banks, woodlots and river gravels beneath the sparser surface art.
	vec3 survey=texture(valley_wash,mapped).rgb;
	float survey_value=paint_value(survey);
	float bank_wash=smoothstep(.24,.54,survey_value);
	colour*=.92+.11*bank_wash;
	colour=mix(colour,survey,.10*(1.-road)+.035);
	float wet=smoothstep(.19,.98,max(cover.g,shore));
	return mix(colour,mix(clay_bed.rgb,river_silt.rgb,.73),.79*wet);
}

void fragment() {
	vec2 p=local_pos.xz;
	vec3 color=pigment;
	float roughness=0.92;
	float specularity=0.13;
	if (part>0.5 && part<1.5) {
		// This painting fixes the routes, old fields, headlands and canopy beds in
		// world space. Fine surface marks disappear into mipmaps at army scale.
		color=painted_ground(p,0.0);
	} else if (part>1.5 && part<2.5) {
		float bank=abs(p.x+32.0);
		float turn=sin(p.y*.42)*.42+sin(p.y*.15+1.1)*.30;
		vec2 flow=vec2(p.x*.27+turn*.33,p.y*.052-TIME*.017);
		float ripple=texture(fieldbed,flow).r;
		float web=texture(fieldbed,flow*vec2(.57,2.5)+vec2(.19,.28)).g;
		float edge=smoothstep(2.6,5.28,bank+turn*.44);
		float current=texture(fieldbed,vec2(p.x*.058+turn*.09,p.y*.036-TIME*.0033)).g;
		color=mix(deep_water.rgb,shallows.rgb,.84*edge+.09*web)*(.80+.13*ripple+.12*current);
		// Broken highlights follow water along the channel and round the gravel bars.
		float stream=(p.x+.27*sin(p.y*.64-TIME*.40)+1.18*web+.51*current)*3.51;
		float hair=abs(fract(stream)-.5);
		float thread=1.0-smoothstep(.034,.086+min(.13,fwidth(stream)*.62),hair);
		float broken=smoothstep(.46,.65,.59*ripple+.41*web);
		float glass=dot(color,vec3(.24,.60,.16));
		color=mix(vec3(glass),color,.67)*vec3(.77,.83,.91);
		vec3 glint=OUTPUT_IS_SRGB?vec3(.40,.49,.46):vec3(.21,.30,.29);
		color=mix(color,glint,thread*broken*(.25+.45*edge));
		float wake=abs(fract((bank+turn*.34+.65*web)*1.48)-.50);
		float foam=(1.0-smoothstep(.028,.12,wake))*smoothstep(3.40,4.60,bank)*smoothstep(.46,.67,ripple);
		color=mix(color,glint,foam*.41);
		roughness=.49; specularity=.29;
	} else if (part>2.5) {
		float side=abs(local_normal.x)>abs(local_normal.z)?local_pos.z:local_pos.x;
		float across=abs(local_normal.y)>0.6?local_pos.z:local_pos.y;
		if (part<3.5 || (part>9.5 && part<11.5)) {
			vec2 grain_uv=vec2(local_pos.x*0.31,(local_pos.z+local_pos.y)*0.94);
			if (part>9.5) grain_uv=part>10.5?vec2(local_pos.y*0.31,(local_pos.x+local_pos.z)*0.94):vec2(local_pos.z*0.31,(local_pos.x+local_pos.y)*0.94);
			float grain=texture(joinery,grain_uv).r;
			color*=0.86+grain*0.26;
			roughness=0.84;
		} else if (part<4.5) {
			float block=texture(joinery,vec2(side,across)*vec2(0.22,0.32)).g;
			color*=0.77+0.39*block;
		} else if (part<5.5) {
			float course=texture(joinery,p*0.48).b;
			// Tile butt overlaps run across both pitches. The existing raised ribs
			// run with the water. World-space derivatives soften a row under one pixel.
			float across_pitch=abs(local_normal.x)>abs(local_normal.z)?p.x:p.y;
			float run=across_pitch*2.52+local_pos.y*.68;
			float seam=abs(fract(run+.5)-.5);
			float mortar=1.0-smoothstep(.035,.088+min(.18,fwidth(run)*.6),seam);
			float wear=smoothstep(.46,.71,texture(fieldbed,p*.28).r);
			color*=(.84+.23*course+.08*wear)*(1.0-.19*mortar);
			roughness=0.75; specularity=0.24;
		} else if (part<6.5) {
			float weave=texture(joinery,vec2(side*0.85,across*1.3)).b;
			color*=0.84+0.28*weave;
		} else if (part<7.5) {
			vec3 foliage=texture(fieldbed,vec2(local_pos.x*0.64+local_pos.z*0.35,local_pos.y*0.48)).rgb;
			color*=0.79+foliage.g*0.40;
		} else if (part<8.5) {
			vec2 bank_uv=vec2(side*0.31,across*0.87);
			float compact=texture(joinery,bank_uv).r;
			float lift=texture(fieldbed,vec2(side*0.068,across*0.73)).r;
			float drip=texture(fieldbed,vec2(side*.12,across*.035)).g;
			float footing=1.0-smoothstep(.55,1.56,local_pos.y+drip*.23);
			float rain=smoothstep(.43,.71,drip)*smoothstep(.18,2.4,local_pos.y);
			float strata=across*2.13+.12*(compact-.5);
			float joint=1.0-smoothstep(.025,.085+min(.14,fwidth(strata)*.55),abs(fract(strata+.5)-.5));
			color*=.74+.29*compact+.16*lift-.105*footing-.065*rain;
			color*=1.0-joint*(.050+.07*rain);
		} else if (part>11.5 && part<12.5) {
			vec3 r=texture(fieldbed,vec2(side*.35,across*.51)).rgb;
			color*=.76+.36*r.r+.09*r.b;
		} else if (part>12.5 && part<13.5) {
			float bank=abs(p.x+32.0);
			float lip=bank+.28*sin(p.y*.39)+.14*sin(p.y*.87+.44);
			color=painted_ground(p,1.0-smoothstep(4.38,6.58,lip));
		} else if(part>15.5 && part<16.5) {
			float grain=texture(joinery,vec2(local_pos.z*.31,(local_pos.x+local_pos.y)*.94)).r;
			float z=abs(p.y);
			float cross_distance=min(z,abs(z-35.0));
			float board=fract((p.x+32.0)/.482+.5);
			float weather=texture(fieldbed,p*vec2(.28,.61)).r;
			float worn=1.0-smoothstep(.12,.46,abs(cross_distance-1.20+.13*(weather-.5)));
			float peg=(1.0-smoothstep(.10,.21,abs(board-.44)))*(1.0-smoothstep(.08,.14,abs(cross_distance-3.41)));
			// The wheel paths bleach the same boards; occasional repairs remain visible at the landings.
			float traffic=.66+.34*smoothstep(.30,.72,texture(fieldbed,p*vec2(.10,.22)).g);
			color*=.78+.31*grain+.19*worn*traffic*(.48+.52*weather)-.16*peg;
			roughness=.91-.14*worn;
		} else if(part>18.5 && part<19.5) {
			// One projection per face; even short, walkable fragments show bedding
			// that continues across the tilted ridgeline, buried edge and talus.
			vec3 n=abs(local_normal);
			vec2 rock_uv=n.y>max(n.x,n.z)*.72?vec2(p.x*.42+p.y*.12,p.y*.46-p.x*.15):
				vec2((n.x>n.z?p.y:p.x)*.51+local_pos.y*.21,local_pos.y*.74+p.x*.12);
			vec3 shale=texture(shale_paint,rock_uv).rgb;
			float facet=.88+.17*clamp(local_normal.y,0.0,1.0);
			vec3 stone=mix(shale*facet,color,.28);
			// Pieces on walkable ground are shallow by design. Let their buried
			// toes inherit the exact same turf, instead of drawing a polygon rim.
			bool on_land=abs(p.x+32.0)>5.1;
			if(on_land) {
				vec2 ridge=(p-vec2(9.0,-36.0))/vec2(34.0,16.0);
				vec2 east=(p-vec2(77.0,43.0))/vec2(30.0,13.0);
				float relief=pow(max(0.,1.-dot(ridge,ridge)),2.)*3.9+pow(max(0.,1.-dot(east,east)),2.)*1.8;
				relief-=(1.-clamp((abs(p.x+32.)-3.9)/2.4,0.,1.))*.92;
				float lift=local_pos.y-relief;
				float exposed=smoothstep(.024,.153,lift);
				color=mix(painted_ground(p,0.0),stone*.90,exposed*.90);
			} else color=stone;
		} else if(part>19.5 && part<20.5) {
			// The low bedding seam lies within the sod, where cart wheels
			// clear soil around the first exposed stones of the pasture.
			color=mix(painted_ground(p,0.0),color,.08+.22*(1.0-smoothstep(.35,.78,local_normal.y)));
		} else if(part>20.5 && part<21.5) {
			// Broken grey sandstone forms broad, thin beds. Its wet toe is
			// dark, with lighter horizontal surfaces emerging from the water.
			vec3 n=abs(local_normal);
			vec2 stone_uv=local_normal.y>.55?p*.34:vec2((n.x>n.z?p.y:p.x)*.45,local_pos.y*.53);
			vec3 shale=texture(shale_paint,stone_uv).rgb;
			float above=smoothstep(-.31,-.04,local_pos.y);
			color=mix(color,shale,.24)*mix(vec3(.58,.69,.71),vec3(.96),above);
		} else if(part>=17.5 && part<18.5) {
			vec2 face_uv=vec2(local_pos.z*.39,local_pos.y*2.93);
			float grit=texture(fieldbed,face_uv).r;
			float roots=texture(joinery,vec2(local_pos.z*.48,local_pos.y*2.10)).r;
			color=mix(vec3(.055,.068,.045),vec3(.130,.113,.072),.32+.37*grit+.23*roots);
		}
	}
	ALBEDO=color;
	ROUGHNESS=roughness;
	SPECULAR=specularity;
}
