extends Node
class_name UIConstants


## 五行色（全局）：传统色相保留，亮度/饱和度收到水墨底上能读的区间。
const ELEMENT_COLORS = {
	"金": Color(0.900, 0.780, 0.440, 1.0), 
	"木": Color(0.460, 0.700, 0.500, 1.0), 
	"水": Color(0.480, 0.640, 0.800, 1.0), 
	"火": Color(0.820, 0.400, 0.320, 1.0), 
	"土": Color(0.700, 0.580, 0.400, 1.0), 
	"天": Color(0.860, 0.760, 0.560, 1.0), 
	"普通": Color(0.5, 0.5, 0.5, 1.0)
}


## 品质色（全局）：色相保留、饱和度压低一档。
## 原版是荧光绿/亮蓝/纯金，压在宣纸墨底上会把画面拽回科技风；
## 这里统一成"矿物颜料"的明度，跨页面（背包/仓库/图鉴/排行榜）共用一套。
const RARITY_COLORS = {
	"common": Color(0.925, 0.898, 0.840), 
	"uncommon": Color(0.440, 0.740, 0.560), 
	"rare": Color(0.490, 0.700, 0.870), 
	"epic": Color(0.700, 0.540, 0.800), 
	"legendary": Color(0.960, 0.760, 0.390), 
	"mythic": Color(0.900, 0.520, 0.440), 
	"divine": Color(1.000, 0.860, 0.400)
}


const FONT_SIZE_SMALL = 12
const FONT_SIZE_NORMAL = 14
const FONT_SIZE_MEDIUM = 16
const FONT_SIZE_LARGE = 20
const FONT_SIZE_TITLE = 24
const FONT_SIZE_BIG_TITLE = 32


const BTN_SIZE_SMALL = Vector2(80, 35)
const BTN_SIZE_NORMAL = Vector2(100, 40)
const BTN_SIZE_LARGE = Vector2(120, 45)
const BTN_SIZE_WIDE = Vector2(200, 45)

const WINDOW_SIZE_SMALL = Vector2(400, 300)
const WINDOW_SIZE_NORMAL = Vector2(400, 350)
const WINDOW_SIZE_LARGE = Vector2(500, 400)
const WINDOW_SIZE_PET = Vector2(600, 700)
const WINDOW_SIZE_MAP = Vector2(550, 600)


const SEPARATION_SMALL = 6
const SEPARATION_NORMAL = 10
const SEPARATION_LARGE = 15
const SEPARATION_XLARGE = 20


const MARGIN_DEFAULT = Vector4(20, 20, 20, 20)
const MARGIN_SMALL = Vector4(10, 10, 10, 10)


const FOOT_SHADOW_WIDTH_RATIO: = 0.86
const FOOT_SHADOW_HEIGHT_RATIO: = 0.26
const FOOT_SHADOW_Y_DOWN_RATIO: = 0.38
const FOOT_SHADOW_MAX_ALPHA: = 0.88
const FOOT_SHADOW_BODY_OFFSET_Y: = 0.0
const FOOT_SHADOW_PLAYER_BODY_OFFSET_Y: = 15.0
const FOOT_SHADOW_Z_INDEX: = 5
