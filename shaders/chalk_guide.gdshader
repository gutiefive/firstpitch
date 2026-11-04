shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float distance_fade=1.0-smoothstep(20.0,45.0,distance(CAMERA_POSITION_WORLD,world_position));
 vec3 gold=vec3(0.65,0.56,0.36);
 ALBEDO=OUTPUT_IS_SRGB ? gold : pow(gold,vec3(2.2));
 ALPHA=distance_fade*0.72;
}
