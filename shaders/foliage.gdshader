shader_type spatial;
uniform vec4 leaf_color = vec4(0.12,0.19,0.09,1.0);
varying vec3 world_position;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float clusters=noise(world_position*2.2);
 float leaves=noise(world_position*18.0);
 ALBEDO=leaf_color.rgb*(0.82+0.26*clusters+0.08*leaves);
 ROUGHNESS=0.96;
 SPECULAR=0.15;
 EMISSION=leaf_color.rgb*0.035;
}
