shader_type canvas_item;

// 石龙身体：把贴片按竖条切片做横向波状位移，看起来像龙在蠕动。
// 位移幅度必须小于贴片的羽化宽度（13px），否则贴片边缘会露出硬切边。
uniform float amp_y = 3.6;
uniform float amp_x = 0.9;
uniform float wave_len = 96.0;
uniform float t = 0.0;
uniform vec2 px_size = vec2(268.0, 244.0);

void fragment() {
	float cx = UV.x * px_size.x;
	float ph = (cx / wave_len) * 6.28318530718;
	float dy = amp_y * sin(ph - t * 0.92);
	float dx = amp_x * sin(ph * 1.55 - t * 1.2);
	vec2 uv = vec2(UV.x - dx / px_size.x, UV.y - dy / px_size.y);
	COLOR = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
}
