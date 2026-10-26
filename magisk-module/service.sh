#!/system/bin/sh
# Magisk late_start service: refresh the palette XML, switch the palette on at the first boot after
# installing, then hand over to the keeper (magisk/eink-palette.sh in the repo).
MODDIR=${0%/*}
. "$MODDIR/common.sh"

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
install_xml  # every boot, so a module update brings new colours
if [ ! -f "$MODDIR/.activated" ]; then
  sleep 15  # let SystemUI apply its own theme first
  palette_on
  touch "$MODDIR/.activated"
  log -t eink-palette "module: palette switched on (first boot)"
fi
# the keeper ignores a disabled palette, so the Action button's "off" survives reboots
exec "$MODDIR/eink-palette.sh"
