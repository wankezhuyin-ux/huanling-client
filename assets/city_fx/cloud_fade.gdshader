shader_type canvas_item;

// 云层贴片：横向照常平铺，只在纵向做羽化。
// 水墨底接近纸白，纯白云的矩形硬边会露出来，必须让上下边缘淡到 0。
uniform float top_fade = 0.22;
uniform float bot_fade = 0.26;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float a = smoothstep(0.0, top_fade, UV.y) * (1.0 - smoothstep(1.0 - bot_fade, 1.0, UV.y));
	COLOR.a *= t.a * a;
	COLOR.rgb *= t.rgb;
}
