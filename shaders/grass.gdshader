shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_mask : filter_nearest, repeat_disable;
uniform bool inspection_enabled=false;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec4 state=texture(state_mask,UV);
 if(state.a<0.5) { discard; }
 float variation=noise(world_pos.xz*1.2)*0.7+noise(world_pos.xz*22.0)*0.3;
 vec3 uncut=mix(vec3(0.075,0.19,0.055),vec3(0.10,0.24,0.065),variation);
 vec3 cut=mix(vec3(0.16,0.32,0.08),vec3(0.23,0.40,0.10),state.g);
 cut*=0.95+0.1*variation;
 ALBEDO=mix(uncut,cut,state.r);
 ROUGHNESS=mix(0.97,0.85,state.r);
 if(inspection_enabled) {
  EMISSION=mix(vec3(0.75,0.50,0.14),vec3(0.04,0.13,0.10),state.r);
  ALBEDO=vec3(0.0);
  SPECULAR=0.0;
  ROUGHNESS=1.0;
 }
}
