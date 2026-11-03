shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_mask : filter_nearest, repeat_disable;
uniform vec2 field_origin=vec2(0.0);
uniform vec2 field_size=vec2(1.0);
varying vec2 mask_uv;
varying float height_fraction;
void vertex() {
 vec3 center=(MODEL_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
 mask_uv=(center.xz-field_origin)/field_size;
 height_fraction=UV.y;
 float fade=clamp((38.0-distance(CAMERA_POSITION_WORLD,center))/12.0,0.0,1.0);
 VERTEX.y*=fade;
 VERTEX.x+=sin(TIME*1.4+center.x*1.1+center.z)*0.025*UV.y*fade;
}
void fragment() {
 vec4 state=texture(state_mask,mask_uv);
 if(state.a<0.5 || state.r>0.5) { discard; }
 vec3 tint=mix(vec3(0.085,0.14,0.055),vec3(0.13,0.20,0.075),height_fraction);
 ALBEDO=tint;
 SPECULAR=0.15;
 ROUGHNESS=0.96;
}
