shader_type canvas_item;
// 立绘水墨化：把带白色/天空底的角色方图压进暖墨底（角色页 hero 卡用）。
// 1) 去饱和一半  2) 混暖墨  3) 整体压暗  4) 椭圆边缘渐隐，方形边界消失在墨底里
// 人物本身是亮色（白衣/银发），去饱和后仍是主体，不会被压没。
uniform float desaturate : hint_range(0.0, 1.0) = 0.55;
uniform vec4 ink_tint : source_color = vec4(0.10, 0.085, 0.062, 1.0);
uniform float ink_mix : hint_range(0.0, 1.0) = 0.26;
uniform float darken : hint_range(0.0, 1.0) = 0.30;
uniform float vignette : hint_range(0.0, 1.0) = 0.95;
// 渐隐起止半径（UV 归一化，0.5 = 贴边）；按立绘在框里的实际占位调
uniform float vig_inner : hint_range(0.0, 1.0) = 0.30;
uniform float vig_outer : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(g), desaturate);
	col = mix(col, ink_tint.rgb, ink_mix);
	col *= (1.0 - darken);
	// 椭圆掩码：竖向按 UV.y 拉长，避免人物脚下先消失
	vec2 p = (UV - vec2(0.5, 0.5)) * vec2(1.0, 0.86);
	float d = length(p);
	float v = smoothstep(vig_inner, vig_outer, d);
	float a = c.a * (1.0 - v * vignette);
	COLOR = vec4(col, a);
}
