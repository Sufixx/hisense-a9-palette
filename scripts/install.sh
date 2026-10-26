#!/bin/bash
# Install or refresh the e-ink palette on a rooted phone connected over adb.
#  1. generates the palette (palette/eink_palette.py) and registers it as the fabricated overlay
#     com.android.shell:eink (target: android),
#  2. installs the keeper (magisk/eink-palette.sh) into /data/adb/service.d and starts it,
#  3. switches the SystemUI theme style to MONOCHROMATIC (skip with --keep-theme-style); the
#     previous value is saved once to /data/system/eink-prev-theme.json for scripts/uninstall.sh.
# Re-running it is safe: values are replaced in place, the keeper is not started twice.
# Requirements: adb, python3, Magisk root with "Shell" allowed in Magisk > Superuser.
set -euo pipefail
cd "$(dirname "$0")/.."

keep_style=0
[ "${1:-}" = --keep-theme-style ] && keep_style=1

adb get-state >/dev/null
adb shell "su -c true" || { echo "root via Magisk su is required (allow Shell in Magisk > Superuser)" >&2; exit 1; }

tmp=$(mktemp -t eink).xml
python3 -I palette/eink_palette.py > "$tmp"
adb push "$tmp" /data/local/tmp/eink.xml >/dev/null
adb push magisk/eink-palette.sh /data/local/tmp/eink-palette.sh >/dev/null
rm -f "$tmp"

# The XML must live in /data/system: system_server cannot read /data/local/tmp (SELinux).
adb shell "su -c '
  set -e
  cp /data/local/tmp/eink.xml /data/system/eink.xml && rm /data/local/tmp/eink.xml
  chown system:system /data/system/eink.xml; chmod 644 /data/system/eink.xml
  restorecon /data/system/eink.xml 2>/dev/null || true
  # re-fabricating replaces the values in place; enabled fabricated overlays registered later win
  cmd overlay fabricate --target android --name eink --file /data/system/eink.xml
  cmd overlay enable com.android.shell:eink
  mkdir -p /data/adb/service.d
  mv /data/local/tmp/eink-palette.sh /data/adb/service.d/eink-palette.sh
  chown root:root /data/adb/service.d/eink-palette.sh; chmod 755 /data/adb/service.d/eink-palette.sh
'"

if [ $keep_style = 0 ]; then
  # MONOCHROMATIC makes the colours SystemUI computes by itself (not covered by the overlay) grey
  # instead of tinted. The JSON goes through two shells, hence the escaping.
  adb shell "su -c '
    [ -f /data/system/eink-prev-theme.json ] ||
      settings get secure theme_customization_overlay_packages > /data/system/eink-prev-theme.json
    settings put secure theme_customization_overlay_packages '\''{\"android.theme.customization.theme_style\":\"MONOCHROMATIC\",\"android.theme.customization.color_source\":\"preset\",\"android.theme.customization.system_palette\":\"333333\",\"android.theme.customization.accent_color\":\"333333\"}'\''
  '"
  sleep 3  # SystemUI re-applies its overlays now; the keeper (below) or the next line fixes the order
  adb shell "su -c 'cmd overlay fabricate --target android --name eink --file /data/system/eink.xml >/dev/null'"
fi

# Start the keeper unless it already runs (Magisk starts it at every boot). A process started from
# `adb shell su -c` dies with the session unless it is nohup+setsid, and then that adb session never
# returns, so run it in the background and drop the local adb client after 3 s.
if ! adb shell "su -c 'ps -A -o args'" | grep -q '^busybox inotifyd /data/adb/service.d/eink-palette.sh'; then
  adb shell "su -c 'nohup setsid /data/adb/service.d/eink-palette.sh </dev/null >/dev/null 2>&1 &'" &
  sleep 3; kill $! 2>/dev/null || true
fi

scripts/status.sh
