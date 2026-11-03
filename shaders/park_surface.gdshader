shader_type spatial;
uniform vec4 base_color = vec4(0.5,0.5,0.5,1.0);
uniform int surface_kind = 0; // 0 paint, 1 timber, 2 concrete, 3 cloth, 4 rubber
varying vec3 world_position;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float broad=noise(world_position*1.7);
 float detail=noise(world_position*55.0);
 float variation=0.94+0.055*broad+0.025*detail;
 ROUGHNESS=0.72;
 if(surface_kind==1) {
  float grain=noise(world_position*vec3(1.0,45.0,17.0));
  variation=0.84+0.12*broad+0.06*grain;
  ROUGHNESS=0.9;
 } else if(surface_kind==2) {
  variation=0.86+0.12*broad+0.035*detail;
  ROUGHNESS=0.97;
 } else if(surface_kind==3) {
  variation=0.94+0.04*detail;
  ROUGHNESS=0.98;
 } else if(surface_kind==4) {
  variation=0.87+0.08*broad;
  ROUGHNESS=0.94;
 }
 ALBEDO=base_color.rgb*variation;
 SPECULAR=surface_kind==0 ? 0.32 : 0.18;
}
