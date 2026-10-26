#!/system/bin/sh
# Magisk runs this when the module is removed, early in boot, before Android's services exist and
# just before it deletes the module directory. So it leaves a one-shot script in service.d, which
# Magisk runs later in the same boot, to switch the palette off and restore the theme.
mkdir -p /data/adb/service.d
cat > /data/adb/service.d/eink-palette-cleanup.sh <<'CLEANUP'
#!/system/bin/sh
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 5; done
sleep 10
cmd overlay disable com.android.shell:eink 2>/dev/null
PREV=/data/system/eink-prev-theme.json
if [ -f $PREV ]; then
  prev=$(cat $PREV)
  if [ "$prev" = null ]; then settings delete secure theme_customization_overlay_packages >/dev/null
  else settings put secure theme_customization_overlay_packages "$prev"; fi
  rm $PREV
fi
rm -f /data/system/eink.xml
log -t eink-palette "module removed: palette off, theme restored"
rm -f /data/adb/service.d/eink-palette-cleanup.sh
CLEANUP
chmod 755 /data/adb/service.d/eink-palette-cleanup.sh
