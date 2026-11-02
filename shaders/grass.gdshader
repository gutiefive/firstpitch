shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_mask : filter_nearest, repeat_disable;
void fragment() {
 vec4 state = texture(state_mask, UV);
 if (state.a < 0.5) { discard; }
 float noise = fract(sin(dot(floor(UV * vec2(1800.0,1320.0)),vec2(12.9898,78.233)))*43758.5453);
 vec3 tall = mix(vec3(0.10,0.26,0.08),vec3(0.14,0.31,0.10),noise);
 vec3 short_grass = mix(vec3(0.24,0.43,0.12),vec3(0.33,0.52,0.16),state.g);
 ALBEDO = mix(tall,short_grass,state.r);
 ROUGHNESS = mix(0.98,0.8,state.r);
}
