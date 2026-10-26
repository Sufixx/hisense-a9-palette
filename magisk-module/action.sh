#!/system/bin/sh
# Magisk app > Modules > Action: switch the palette and the outlines off or on.
MODDIR=${0%/*}
. "$MODDIR/common.sh"
if palette_is_on; then
  palette_off
  echo "E-ink palette OFF: stock colours and theme restored."
  echo "It stays off after reboots. Press Action again to switch it on."
else
  echo "Switching the e-ink palette on..."
  palette_on
  echo "E-ink palette ON."
fi
