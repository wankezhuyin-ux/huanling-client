#!/bin/bash
# 模拟器自动化：登录 → 关掉各种弹窗 → 切主城 → 收集 PROBE 日志
# 用途：性能探针测量（弹窗时序每次都不一样，手点太慢）
set -u
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
APK="${1:-/Users/a1111/Documents/Codex/2026-10-21/n/outputs/build/幻灵归虚-probe.apk}"
USER_NAME="${2:-probe1}"
PASS="${3:-probe1123}"

adb install -r "$APK" >/dev/null 2>&1
adb shell pm clear com.huanling.game.local >/dev/null 2>&1
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
