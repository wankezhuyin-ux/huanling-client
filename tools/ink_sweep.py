import re, colorsys

def _ramp(stops, v):
    if v <= stops[0][0]: return stops[0][1]
    if v >= stops[-1][0]: return stops[-1][1]
    for i in range(len(stops)-1):
        v0,c0 = stops[i]; v1,c1 = stops[i+1]
        if v0 <= v <= v1:
            t=(v-v0)/(v1-v0) if v1>v0 else 0
            return tuple(c0[j]+(c1[j]-c0[j])*t for j in range(3))
    return stops[-1][1]

INK = [(0.00,(0.016,0.020,0.022)),(0.10,(0.042,0.051,0.054)),(0.22,(0.078,0.086,0.084)),
       (0.45,(0.290,0.283,0.263)),(0.65,(0.540,0.520,0.482)),(0.82,(0.760,0.740,0.680)),
       (1.00,(0.945,0.912,0.850))]
GOLD = [(0.00,(0.090,0.070,0.032)),(0.35,(0.360,0.285,0.130)),(0.60,(0.640,0.520,0.240)),
        (0.80,(0.788,0.635,0.294)),(1.00,(1.000,0.905,0.640))]

COLOR_RE = re.compile(r'Color\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)(\s*,[^)]*)?\)')

def is_cool(r,g,b):
    mx=max(r,g,b)
    if mx<=0.004: return False
    hd=colorsys.rgb_to_hls(r,g,b)[0]*360
    return 185 <= hd <= 285

def remap(r,g,b,role):
    mx=max(r,g,b); mn=min(r,g,b)
    sat=(mx-mn)/mx if mx>0 else 0
    if role=='border':
        return _ramp(GOLD, max(mx, 0.62))
    if role=='shadow':
        return (0.0, 0.0, 0.0)
    if role=='text':
        if sat >= 0.30 and mx >= 0.55:
            return _ramp(GOLD, mx)
        return _ramp(INK, max(mx, 0.72))
    # 底色/默认：一律墨色，且把亮度压进面板区间，避免大块棕金色块
    return _ramp(INK, min(mx, 0.20))

def role_of(context):
    c = context
    if 'border_color' in c: return 'border'
    if 'shadow_color' in c: return 'shadow'
    if 'font_color' in c or 'font_outline' in c or 'font_shadow' in c or 'color_override' in c: return 'text'
    if 'modulate' in c or '.color' in c: return 'text'
    if 'bg_color' in c: return 'bg'
    return 'bg'

def sweep_gd(text):
    n=0
    def sub(m):
        nonlocal n
        r,g,b=[float(x) for x in m.groups()[:3]]
        tail=m.group(4) or ''
        if not is_cool(r,g,b): return m.group(0)
        ctx = text[max(0,m.start()-90):m.start()]
        ctx = ctx.split('\n')[-1]   # 只看同一行
        c = remap(r,g,b, role_of(ctx))
        n+=1
        return 'Color(%.3f, %.3f, %.3f%s)'%(c[0],c[1],c[2],tail)
    return COLOR_RE.sub(sub, text), n

def sweep_tscn(text):
    out=[]; n=0
    for line in text.split('\n'):
        if 'Color(' in line and '=' in line:
            key=line.split('=')[0]
            role = 'border' if 'border_color' in key else ('shadow' if 'shadow_color' in key else ('text' if 'font' in key else 'bg'))
            def sub(m):
                nonlocal n
                r,g,b=[float(x) for x in m.groups()[:3]]
                tail=m.group(4) or ''
                if not is_cool(r,g,b): return m.group(0)
                c=remap(r,g,b,role); n+=1
                return 'Color(%.3f, %.3f, %.3f%s)'%(c[0],c[1],c[2],tail)
            line = COLOR_RE.sub(sub, line)
        out.append(line)
    return '\n'.join(out), n


## 用法（一次性清洗某批文件的冷色/圆角）：
##   python3 tools/ink_sweep.py ui/city/*.gd
## 判定规则：
##   只处理色相 185°~285°（青→蓝→紫）的颜色，其余（暖色/绿/红）不动；
##   按赋值位置分角色：bg→墨色（亮度压到面板区间）、border→金、font→纸白或金、
##   shadow→纯黑。早期版本按"亮度+饱和度"猜角色，会把调色板字典项（如五行色、
##   境界色）一起刷成墨黑导致文字看不见，所以现在必须按 role 来。
if __name__ == "__main__":
    import sys, glob
    targets = []
    for a in sys.argv[1:]:
        targets.extend(glob.glob(a) if any(ch in a for ch in "*?[") else [a])
    for p in targets:
        s = open(p, encoding='utf-8').read()
        s2, n = sweep_tscn(s) if p.endswith('.tscn') else sweep_gd(s)
        if s2 != s:
            open(p, 'w', encoding='utf-8').write(s2)
            print(f'{n:4d}  {p}')
