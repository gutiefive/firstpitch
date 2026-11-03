shader_type spatial;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_position.xz/vec2(1.8,2.1);
 vec2 cell=floor(p);
 vec2 edge=min(fract(p),1.0-fract(p));
 vec2 aa=fwidth(p);
 float joint=min(smoothstep(0.005,0.005+aa.x,edge.x),smoothstep(0.005,0.005+aa.y,edge.y));
 float variation=0.96+0.04*hash(cell);
 float grit=hash(floor(world_position.xz*160.0));
 vec3 concrete=vec3(0.30,0.285,0.245)*variation*(0.97+grit*0.035);
 ALBEDO=mix(vec3(0.245,0.23,0.20),concrete,joint);
 ROUGHNESS=0.94;
 SPECULAR=0.18;
}
