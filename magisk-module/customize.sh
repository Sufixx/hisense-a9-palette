# Runs while installing (Magisk app). Only file operations here; switching the palette on needs a
# booted Android and happens in service.sh at the next boot.
set_perm "$MODPATH/eink-palette.sh" 0 0 0755
# an update must not switch the palette back on if the Action button switched it off
[ -f /data/adb/modules/eink_palette/.activated ] && touch "$MODPATH/.activated"

# The computer-based install (scripts/install.sh) and the old outline-only module do the same job.
# Two keepers would fight over the overlay order, and two copies of the outline APK conflict.
if [ -f /data/adb/service.d/eink-palette.sh ]; then
  rm -f /data/adb/service.d/eink-palette.sh
  ui_print "- Removed the boot script of the computer-based install (this module replaces it)"
fi
if [ -d /data/adb/modules/eink_systemui_overlay ]; then
  touch /data/adb/modules/eink_systemui_overlay/remove
  ui_print "- Old outline-only module marked for removal (included here)"
fi
ui_print "- Reboot. The palette switches on about 20 s after the boot finishes."
ui_print "- Off/on: Magisk > Modules > E-ink palette > Action"
