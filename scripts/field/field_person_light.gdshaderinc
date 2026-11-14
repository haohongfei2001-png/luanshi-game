// Three broad value regions on the smooth, posed person. Normalize after
// interpolation so triangle interiors keep the same lighting response as edges.
void light() {
    float facing=dot(normalize(NORMAL),normalize(LIGHT));
    float width=clamp(fwidth(facing)*1.05,.075,.15);
    float half_light=smoothstep(.04-width,.04+width,facing);
    float lit=smoothstep(.59-width,.59+width,facing);
    DIFFUSE_LIGHT+=LIGHT_COLOR*((half_light*.55+lit*.43)*ATTENUATION/3.14159265);
}
