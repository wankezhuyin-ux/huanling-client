extends RefCounted
## 底包版本号（单一来源）。
##
## 为什么单独放一个文件：热更引导脚本 hotfix_bootstrap.gd 必须在挂载 pck **之前**
## 就知道底包版本（用来判断本地补丁是不是属于这个底包）。
## 以前它直接 load("res://main.gd") 取 CLIENT_VERSION，而 main.gd 里有
## `main_ui as MainUI`，编译时会解析 class_name MainUI → 把底包的 ui/main_ui.gd
## 提前拉进资源缓存。pck 挂载后即使 CACHE_MODE_REPLACE 也换不掉，
## 于是 main_ui 的热更永远不生效（黑屏修复、顶栏对齐等只能重打 APK）。
##
## 这个文件不引用任何 UI 类，提前编译也无副作用。

const VALUE := "2.12.0"
