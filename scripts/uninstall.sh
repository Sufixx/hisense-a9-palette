#!/bin/bash
# Undo scripts/install.sh (and, if installed, the SystemUI outline module).
# The fabricated overlay stays registered but disabled: Android 14's `cmd overlay` cannot unregister
# fabricated overlays. A disabled overlay has no effect.
set -euo pipefail
adb shell "su -c '
  # stop the keeper first, otherwise it reacts to the changes below
  # (not pkill -f: that would match this shell, whose command line contains the pattern)
  for pid in \$(ps -A -o pid,args | grep \"busybox inotifyd /data/adb/service.d/eink-palette.sh\" | grep -v grep | awk \"{print \\\$1}\"); do
    kill \$pid
  done
  rm -f /data/adb/service.d/eink-palette.sh
  cmd overlay disable com.android.shell:eink 2>/dev/null || true
  rm -f /data/system/eink.xml
  if [ -f /data/system/eink-prev-theme.json ]; then
    prev=\$(cat /data/system/eink-prev-theme.json)
    if [ \"\$prev\" = null ]; then settings delete secure theme_customization_overlay_packages
    else settings put secure theme_customization_overlay_packages \"\$prev\"; fi
    rm /data/system/eink-prev-theme.json
  fi
  if [ -d /data/adb/modules/eink_systemui_overlay ]; then
    touch /data/adb/modules/eink_systemui_overlay/remove
    echo \"outline module marked for removal: reboot to finish\"
  fi
  echo done
'"
