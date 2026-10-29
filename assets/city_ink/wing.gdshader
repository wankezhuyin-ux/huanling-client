shader_type canvas_item;

// 光翼动态：UV 柔性扭动 + 流光 + 呼吸。
// 单张翼纹理 → 1 draw call，手机端几乎零成本。
uniform float phase = 0.0;       // 时间（秒），左右两翼给不同初值即可错拍
uniform float warp : hint_range(0.0, 0.05) = 0.012;   // 扭动幅度
uniform float flow : hint_range(0.0, 1.0) = 0.34;     // 流光强度
uniform float pulse : hint_range(0.0, 1.0) = 0.10;    // 整体呼吸
uniform float gain : hint_range(0.0, 2.0) = 1.0;      // 总亮度
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 uv = UV;

    // 翼尖方向（uv.x 越大越靠外）飘得越多，翼根几乎不动
    float t = smoothstep(0.05, 1.0, uv.x);

    // 两层不同频率的波：一层上下扫、一层顺着翼身跑，避免看出来是正弦
    float w1 = sin(uv.x * 5.4 - phase * 1.25 + uv.y * 2.6);
    float w2 = sin(uv.y * 7.1 + phase * 0.85 - uv.x * 1.7);
    uv.x += (w1 * 0.65 + w2 * 0.35) * warp * t;
    uv.y += (w2 * 0.70 - w1 * 0.30) * warp * 0.85 * t;

    vec4 c = texture(TEXTURE, uv);

    // 一道窄光从翼根流向翼尖
    float f = pow(max(0.0, sin((uv.x * 1.35 - phase * 0.42) * 6.28318)), 8.0);
    c.rgb += vec3(1.0, 0.93, 0.80) * f * flow * c.a;

    // 整体呼吸（两个不同周期叠加，不会看出规律）
    float br = 1.0 + pulse * (0.62 * sin(phase * 1.7) + 0.38 * sin(phase * 2.9 + 1.3));
    c.rgb *= br;

    COLOR = vec4(c.rgb, c.a) * tint;
}
