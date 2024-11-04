shader_type canvas_item;

uniform sampler2D progress_texture;
uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	if (texture(progress_texture, UV).r < progress) {
		discard;
	}
}