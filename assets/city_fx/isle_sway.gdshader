shader_type canvas_item;

// 悬空岛下缘垂枝：按列给横向位移，越往下摆幅越大，像被风带着飘。
// 幅度沿用原型 2.6~2.9px，必须小于贴片羽化宽度，否则边缘会露出硬边。
uniform float sway = 2.9;
uniform float phase = 0.0;
uniform float t = 0.0;
uniform vec2 px_size = vec2(152.0, 202.0);

void fragment() {
	float tt = UV.x;
	float dx = sin(t * 1.05 + phase + tt * 3.4) * sway
	         + sin(t * 1.9 + tt * 7.1) * sway * 0.35;
	// 顶边（岛体）几乎不动，越靠岛下的垂枝越软
	float w = smoothstep(0.12, 0.95, UV.y);
	vec2 uv = vec2(UV.x - dx * w / px_size.x, UV.y);
	COLOR = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
}
