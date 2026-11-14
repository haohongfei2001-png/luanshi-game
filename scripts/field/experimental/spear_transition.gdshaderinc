// Research-only material, installed for one selected actor by the capture harness.
// 48 vec4 = 768 bytes per actor; no added texture lookups. Not production enabled.
uniform vec4 spear_delta_x[16];
uniform vec4 spear_delta_y[16];
uniform vec4 spear_delta_z[16];
void spear_delta(int bone,vec3 point,vec3 normal,out vec3 p,out vec3 n) {
    vec4 v=vec4(point,1.);
    vec4 d=vec4(normal,0.);
    p=vec3(dot(spear_delta_x[bone],v),dot(spear_delta_y[bone],v),dot(spear_delta_z[bone],v));
    n=vec3(dot(spear_delta_x[bone],d),dot(spear_delta_y[bone],d),dot(spear_delta_z[bone],d));
}
