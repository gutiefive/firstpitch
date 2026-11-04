shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never;
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
 vec2 local=(UV-0.5)*2.0;
 float irregularity=(noise(world_pos.xz*13.0)-0.5)*0.20;
 float radius=length(local*vec2(1.0,1.15))+irregularity;
 float edge=1.0-smoothstep(0.58,0.98,radius);
 float grain=noise(world_pos.xz*18.0);
 vec3 clay=mix(dark_color.rgb,light_color.rgb,grain);
 float scuff=(1.0-compaction)*(0.12+0.12*noise(world_pos.xz*32.0));
 ALBEDO=clay*(1.0-scuff);
 ALPHA=edge*(1.0-compaction);
 ROUGHNESS=0.98;
 SPECULAR=0.12;
}
