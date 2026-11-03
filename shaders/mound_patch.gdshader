shader_type spatial;
render_mode cull_disabled;
uniform float compaction=0.0;
uniform vec4 dark_color=vec4(0.4,0.12,0.05,1.0);
uniform vec4 light_color=vec4(0.51,0.19,0.08,1.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float radius=length((UV-0.5)*2.0);
 if(radius>1.0) { discard; }
 vec2 p=world_pos.xz*1.3;
 float grain=noise(p*0.8)*0.65+noise(p*9.0)*0.25+noise(p*70.0)*0.1;
 vec3 base=mix(dark_color.rgb,light_color.rgb,grain);
 float wear=(1.0-smoothstep(0.2,1.0,radius))*(1.0-compaction);
 vec3 scuffed=base*mix(0.32,0.7,noise(world_pos.xz*25.0));
 ALBEDO=mix(base,scuffed,wear);
 ROUGHNESS=0.97;
}
