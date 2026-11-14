// Pigment on the continuous anatomical surface. These fields cross UV seams
// smoothly; facial features retain the registered original three face paintings.
vec3 field_person_pigment(int panel, vec2 coordinates, vec3 point, float lot) {
    if (panel==34) {
        vec2 face_uv=vec2(fract(coordinates.x),coordinates.y);
        vec3 base=vec3(.7686,.5765,.4667);
        if (lot>.72) {face_uv+=vec2(.125,.25);base=vec3(.6784,.5020,.4000);}
        else if (lot>.31) {face_uv.y+=.25;base=vec3(.7176,.5333,.4353);}
        if (!OUTPUT_IS_SRGB) base=pow(base,vec3(2.2));
        vec3 face=texture(cloth_atlas,face_uv).rgb;
        float front=smoothstep(.028,.080,point.z)*(1.-smoothstep(.071,.092,abs(point.x)));
        float painted_value=dot(face,vec3(.28,.56,.16));
        float feature=1.-smoothstep(OUTPUT_IS_SRGB?.23:.042,OUTPUT_IS_SRGB?.49:.21,painted_value);
        vec3 pigment=mix(base,face,front*(.48+.52*feature));
        float hairline=1.590+.073*smoothstep(-.025,.090,point.z)-.010*smoothstep(.055,.085,abs(point.x));
        float hair=smoothstep(hairline-.0015,hairline+.0015,point.y);
        vec3 hair_ink=OUTPUT_IS_SRGB?vec3(.145,.127,.112):vec3(.0143,.0107,.0081);
        return mix(pigment,hair_ink,hair);
    }
    if (panel==35) {
        vec3 cloth=OUTPUT_IS_SRGB?vec3(.452,.420,.355):vec3(.174,.148,.103);
        float seam=abs(fract(point.y*28.+point.x*.8)-.5);
        float bound=1.-smoothstep(.025,.10,seam);
        return cloth*(1.-.13*bound);
    }
    // Wool breeches get their broad value changes from the actual knee and
    // calf surface. Keep one restrained cloth field over the whole bent leg.
    return OUTPUT_IS_SRGB?vec3(.310,.308,.292):vec3(.076,.075,.069);
}
