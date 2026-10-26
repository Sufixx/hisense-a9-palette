#!/bin/bash
# Install the SystemUI outline module built by overlay-systemui/build.sh, then reboot and enable it.
# Escape hatch if SystemUI misbehaves afterwards:
#   adb shell su -c 'touch /data/adb/modules/eink_systemui_overlay/disable' && adb reboot
set -euo pipefail
cd "$(dirname "$0")/.."
zip=overlay-systemui/out/eink_systemui_overlay.zip
[ -f $zip ] || { echo "build it first: overlay-systemui/build.sh" >&2; exit 1; }
adb push $zip /data/local/tmp/eink_systemui_overlay.zip >/dev/null
adb shell "su -c 'magisk --install-module /data/local/tmp/eink_systemui_overlay.zip; rm /data/local/tmp/eink_systemui_overlay.zip'"
echo "rebooting so the overlay is scanned from /product/overlay ..."
adb reboot
adb wait-for-device
adb shell 'until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done'
sleep 10
# non-static overlays start disabled; enabling it is persistent
adb shell "su -c 'cmd overlay enable io.github.sufixx.eink.systemui && cmd overlay list com.android.systemui | grep eink'"
