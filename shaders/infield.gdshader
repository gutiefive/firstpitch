shader_type spatial;
render_mode cull_disabled;
uniform sampler2D condition_mask : filter_nearest, repeat_disable;
uniform sampler2D moisture_mask : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D puddle_mask : hint_default_black, filter_nearest, repeat_disable;
uniform sampler2D rut_mask : hint_default_black, filter_nearest, repeat_disable;
uniform vec2 field_origin=vec2(0.0);
uniform vec2 field_size=vec2(1.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec4 state=texture(condition_mask,(world_pos.xz-field_origin)/field_size);
 vec2 p=world_pos.xz;
 float clumps=noise(p*6.0);
 float footprints=step(0.80,noise(p*1.8))*0.035;
 vec3 rough=mix(vec3(0.25,0.105,0.047),vec3(0.39,0.18,0.08),clumps)-footprints;
 vec2 direction=state.gb*2.0-1.0;
 vec2 across=vec2(-direction.y,direction.x);
 float line_coord=dot(p,across)*55.0;
 float detail_fade=1.0-smoothstep(0.5,2.5,fwidth(line_coord));
 float lines=sin(line_coord)*0.012*detail_fade;
 vec3 smooth_dirt=vec3(0.46,0.25,0.12)+lines+noise(p*35.0)*0.012;
 vec3 protected_dirt=mix(vec3(0.31,0.14,0.065),vec3(0.38,0.18,0.09),noise(p*3.0));
 ALBEDO=mix(protected_dirt,mix(rough,smooth_dirt,state.r),state.a);
 float moisture=texture(moisture_mask,(world_pos.xz-field_origin)/field_size).r*state.a;
 ALBEDO*=mix(1.0,0.48,moisture);
 float puddle=texture(puddle_mask,(world_pos.xz-field_origin)/field_size).r;
 float rut=texture(rut_mask,(world_pos.xz-field_origin)/field_size).r;
 float gouge=step(0.5,sin(dot(p,across)*18.0));
 ALBEDO*=mix(1.0,0.65+0.12*gouge,rut);
 ALBEDO*=mix(1.0,0.58,puddle);
 ROUGHNESS=mix(mix(mix(1.0,0.91,state.r),0.62,moisture),0.12,puddle);
}
