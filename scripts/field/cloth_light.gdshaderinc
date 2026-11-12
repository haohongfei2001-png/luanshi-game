// Two transitions across a curved form. Screen derivatives soften only the band edge.
void light() {
    float facing = dot(NORMAL, LIGHT);
    float width = clamp(fwidth(facing) * 0.85, 0.032, 0.13);
    float half_light = smoothstep(0.04 - width, 0.04 + width, facing);
    float lit = smoothstep(0.59 - width, 0.59 + width, facing);
    float diffuse = half_light * 0.55 + lit * 0.43;
    DIFFUSE_LIGHT += LIGHT_COLOR * (diffuse * ATTENUATION / PI);
}
