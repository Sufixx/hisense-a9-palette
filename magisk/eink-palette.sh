#!/system/bin/sh
# Magisk service.d script ("keeper"), installed as /data/adb/service.d/eink-palette.sh by scripts/install.sh.
# SystemUI re-registers its monet overlays (com.android.systemui:neutral/accent/dynamic) at boot,
# when it restarts and on dark/light switches; that puts them above our fabricated overlay
# com.android.shell:eink and the tinted palette comes back. Re-fabricating ours moves it back on top.
# Event driven: busybox inotifyd re-runs this script with "<event> <dir> <file>" whenever
# /data/system/overlays.xml is rewritten, so nothing polls while the phone sleeps.
SELF=/data/adb/service.d/eink-palette.sh
XML=/data/system/eink.xml

STAMPS=/dev/eink-palette.stamps  # tmpfs, cleared at boot

fix() {
  [ -f $XML ] || return 0
  enabled=$(cmd overlay list android | grep '^\[x\]')
  # compare with SystemUI's overlays only: other overlays (e.g. the gesture-navbar ones) may be
  # listed after ours, and checking "is ours last" made re-fabricating trigger itself forever
  ours=$(echo "$enabled" | grep -n 'com.android.shell:eink' | cut -d: -f1)
  [ -n "$ours" ] || return 0  # disabled on purpose: leave it alone
  theirs=$(echo "$enabled" | grep -n 'com.android.systemui:' | tail -1 | cut -d: -f1)
  [ -z "$theirs" ] || [ "$ours" -gt "$theirs" ] && return 0
  # loop guard: each re-fabricate makes every app redraw, so at most 3 per minute
  now=$(date +%s)
  recent=$(awk -v n=$now '$1 > n - 60' $STAMPS 2>/dev/null | wc -l)
  if [ "$recent" -ge 3 ]; then
    log -t eink-palette "skipped: already 3 fixes in the last minute"
    return 0
  fi
  echo $now >> $STAMPS
  cmd overlay fabricate --target android --name eink --file $XML &&
    cmd overlay enable com.android.shell:eink &&
    log -t eink-palette "moved com.android.shell:eink back on top"
}

if [ $# -ge 3 ]; then  # called by inotifyd
  [ "$3" = overlays.xml ] && fix
  exit 0
fi

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
sleep 15
fix
exec /data/adb/magisk/busybox inotifyd $SELF /data/system:wy
