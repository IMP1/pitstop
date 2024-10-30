shader_type canvas_item;
render_mode blend_mix,light_only;

uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	// TODO: Have a better progression
	//       Maybe use another texture that's drawn to as the player interacts?
	//       Maybe just have a zig-zag or spiral pattern like what a window-cleaner would do
	if (UV.x < progress) {
		discard;
	}
}