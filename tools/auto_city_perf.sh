#!/bin/bash
# 模拟器自动化：登录 → 关掉各种弹窗 → 切主城 → 收集 PROBE 日志
# 用途：性能探针测量（弹窗时序每次都不一样，手点太慢）
set -u
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
APK="${1:-/Users/a1111/Documents/Codex/2026-10-21/n/outputs/build/幻灵归虚-probe.apk}"
USER_NAME="${2:-probe1}"
PASS="${3:-probe1123}"
PKG="com.huanling.game.local"
AAPT="$HOME/Library/Android/sdk/build-tools/35.0.0/aapt2"

# ---- 安装，并且**必须校验真的装上了** ----------------------------------
# 踩过的坑：adb install 的增量安装会先报 INSTALL_FAILED_MEDIA_UNAVAILABLE，
# 回退到 streamed 安装才成功；如果这里把输出丢掉、不校验版本号，
# 就会出现「验证了半天，模拟器上跑的还是上一个包」——瀑布那次就是这么翻的车。
WANT_CODE="$("$AAPT" dump badging "$APK" 2>/dev/null | sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" | head -1)"
echo "--- 安装 $APK (versionCode=$WANT_CODE) ---"
for attempt in 1 2 3; do
  adb install -r -d "$APK" >/tmp/city_install.log 2>&1 && break
  echo "  第 $attempt 次安装失败，重试…（$(tail -1 /tmp/city_install.log)）"
  sleep 3
done
GOT_CODE="$(adb shell dumpsys package "$PKG" 2>/dev/null | sed -n "s/^\s*versionCode=\([0-9]*\).*/\1/p" | head -1)"
if [ -n "$WANT_CODE" ] && [ "$WANT_CODE" != "$GOT_CODE" ]; then
  echo "❌ 安装没生效：期望 versionCode=$WANT_CODE，模拟器上是 ${GOT_CODE:-未知}。"
  echo "   中止，避免拿旧包当新包验收。"
  exit 1
fi
echo "--- 已确认安装 versionCode=$GOT_CODE ---"
adb shell pm clear "$PKG" >/dev/null 2>&1
adb logcat -c
adb shell monkey -p com.huanling.game.local -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 26

# 登录页
adb shell input tap 540 860; sleep 2
adb shell input text "$USER_NAME"; sleep 1
adb shell input keyevent KEYCODE_TAB; sleep 1
adb shell input text "$PASS"; sleep 1
adb shell input tap 540 1092; sleep 12

# 关掉可能出现的弹窗：离线奖励(1146)、进入游戏(1256)、其它常见位置
for y in 1146 1256 1080 1140; do
  adb shell input tap 540 $y >/dev/null 2>&1
  sleep 3
done
sleep 6

echo "--- 切主城 ---"
adb logcat -c
adb shell input tap 540 1820
sleep 16
echo "--- 切战斗 ---"
adb shell input tap 110 1820
sleep 10
echo "--- 回主城 ---"
adb shell input tap 540 1820
sleep 10

adb logcat -d 2>/dev/null | grep -E "I godot.*PROBE" | grep -vE "flush#|节点来源"
adb shell screencap -p /sdcard/auto.png >/dev/null 2>&1
adb pull /sdcard/auto.png /tmp/apk_auto.png >/dev/null 2>&1
echo "截图: /tmp/apk_auto.png"
