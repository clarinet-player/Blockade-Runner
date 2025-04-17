shader_type spatial;
render_mode depth_test_disabled, unshaded;

uniform vec4 outline_color : source_color;
uniform float alpha = 0.33;

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = alpha;
}	