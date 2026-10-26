#!/bin/bash
# Show what is installed and whether the palette currently wins. Read-only.
set -uo pipefail
adb shell "su -c '
  echo \"== enabled overlays on android (later = wins; com.android.shell:eink must come after com.android.systemui:*)\"
  cmd overlay list android | grep \"^\[x\]\" | grep -E \"systemui:|shell:\"
  echo \"== resolved colours (expect #ffffffff / #ff000000)\"
  for c in system_neutral1_50 system_surface_light system_on_surface_light system_primary_light; do
    printf \"  %-28s %s\n\" \$c \$(cmd overlay lookup com.android.systemui android:color/\$c)
  done
  echo \"== install method\"
  [ -f /data/adb/service.d/eink-palette.sh ] && echo \"  computer-based: /data/adb/service.d/eink-palette.sh\"
  [ -d /data/adb/modules/eink_palette ] && echo \"  Magisk module eink_palette \$(ls /data/adb/modules/eink_palette | grep -E \"^(disable|remove)\$\")\"
  [ -d /data/adb/modules/eink_systemui_overlay ] && echo \"  outline-only module eink_systemui_overlay\"
  echo \"== keeper\"
  ps -A -o pid,args | grep \"busybox inotifyd .*eink-palette.sh\" | grep -v grep || echo \"  not running\"
  logcat -d -s eink-palette | tail -5
  echo \"== SystemUI outline overlay\"
  cmd overlay list com.android.systemui | grep io.github.sufixx.eink.systemui || echo \"  not installed\"
  echo \"== theme style\"
  settings get secure theme_customization_overlay_packages
'"
