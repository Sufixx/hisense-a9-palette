#!/bin/bash
# Capture the same set of screens for the README comparison: scripts/screenshots.sh <out-dir>
# The phone must be unlocked and left alone while this runs (~30 s). Screenshots are taken before
# the display's colour filters (e.g. grayscale), so they show the colours apps actually draw.
set -euo pipefail
out=${1:?output dir}
mkdir -p "$out"
shot() {  # shot <name> <shell commands that bring the screen up>
  adb shell "su -c 'input keyevent KEYCODE_WAKEUP; $2; sleep 2; screencap -p /data/local/tmp/shot.png; chmod 644 /data/local/tmp/shot.png'"
  adb pull /data/local/tmp/shot.png "$out/$1.png" >/dev/null
  adb shell "su -c 'cmd statusbar collapse; rm -f /data/local/tmp/shot.png'"
  echo "$out/$1.png"
}
shot 1-settings "am force-stop com.android.settings; am start -W -a android.settings.SETTINGS >/dev/null"
shot 2-display "am force-stop com.android.settings; am start -W -a android.settings.DISPLAY_SETTINGS >/dev/null"
shot 3-sound "am force-stop com.android.settings; am start -W -a android.settings.SOUND_SETTINGS >/dev/null"
shot 4-battery-saver "am force-stop com.android.settings; am start -W -a android.settings.BATTERY_SAVER_SETTINGS >/dev/null"
shot 5-quick-settings "cmd statusbar expand-settings"
shot 6-notifications  "cmd statusbar expand-notifications"
adb shell "input keyevent KEYCODE_HOME"
