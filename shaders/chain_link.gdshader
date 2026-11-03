shader_type spatial;
render_mode cull_disabled;
uniform vec2 fence_size = vec2(3.0,2.4);
void fragment() {
 vec2 p = UV*fence_size;
 float a = abs(fract((p.x+p.y)/0.18)-0.5);
 float b = abs(fract((p.x-p.y)/0.18)-0.5);
 if(min(a,b)>0.035) { discard; }
 ALBEDO = vec3(0.24,0.32,0.31);
 ROUGHNESS = 0.8;
}
