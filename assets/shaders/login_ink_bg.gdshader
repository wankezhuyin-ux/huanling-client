shader_type canvas_item;
// 登录页 key art 水墨化：原图是蓝紫发光 key art，和游戏内暖墨金线不是一个世界。
// 做法：大幅去饱和（保留一点原色免得死灰）→ 用"暖墨 × 原图明度"重新上色 →
// 整体压暗 → 四角轻暗角。比叠半透明色块干净：色相被真正改掉，不是盖一层雾。
uniform float desaturate : hint_range(0.0, 1.0) = 0.74;
uniform vec4 ink_tone : source_color = vec4(0.34, 0.265, 0.155, 1.0);
uniform float tone_mix : hint_range(0.0, 1.0) = 0.50;
uniform float darken : hint_range(0.0, 1.0) = 0.20;
uniform float vignette : hint_range(0.0, 1.0) = 0.40;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(g), desaturate);
	// 用暖墨色 × 原图明度重上色：树/灵兽的高光变成暖金，暗部沉进墨里
	vec3 toned = ink_tone.rgb * (0.30 + g * 1.30);
	col = mix(col, clamp(toned, vec3(0.0), vec3(1.0)), tone_mix);
	col *= (1.0 - darken);
	float d = distance(UV, vec2(0.5, 0.46));
	col *= 1.0 - smoothstep(0.42, 0.98, d) * vignette;
	COLOR = vec4(col, c.a);
}
