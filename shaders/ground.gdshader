shader_type spatial;
render_mode cull_disabled;
uniform vec4 dark_color = vec4(0.3,0.15,0.08,1.0);
uniform vec4 light_color = vec4(0.4,0.2,0.12,1.0);
uniform float grain_scale = 1.0;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz*grain_scale;
 float mottling=noise(p*0.8)*0.65+noise(p*9.0)*0.25+noise(p*70.0)*0.1;
 ALBEDO=mix(dark_color.rgb,light_color.rgb,mottling);
 ROUGHNESS=0.97;
}
