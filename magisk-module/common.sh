# Shared by service.sh and action.sh (sourced, runs as root on the booted phone).
XML=/data/system/eink.xml
PREV=/data/system/eink-prev-theme.json
OUTLINES=io.github.sufixx.eink.systemui
MONO='{"android.theme.customization.theme_style":"MONOCHROMATIC","android.theme.customization.color_source":"preset","android.theme.customization.system_palette":"333333","android.theme.customization.accent_color":"333333"}'

# system_server reads the XML, and SELinux lets it read /data/system but not the module directory
install_xml() {
  cp "$MODDIR/eink.xml" $XML
  chown system:system $XML
  chmod 644 $XML
  restorecon $XML 2>/dev/null
}

palette_on() {
  install_xml
  # remember the user's theme once, for palette_off and for removal
  [ -f $PREV ] || settings get secure theme_customization_overlay_packages > $PREV
  settings put secure theme_customization_overlay_packages "$MONO"
  sleep 3  # SystemUI re-registers its overlays now; ours has to come after them
  cmd overlay fabricate --target android --name eink --file $XML >/dev/null
  cmd overlay enable com.android.shell:eink
  cmd overlay enable $OUTLINES 2>/dev/null  # absent until the first boot with the module
}

palette_off() {
  cmd overlay disable com.android.shell:eink 2>/dev/null
  cmd overlay disable $OUTLINES 2>/dev/null
  restore_theme
}

restore_theme() {
  [ -f $PREV ] || return 0
  prev=$(cat $PREV)
  if [ "$prev" = null ]; then settings delete secure theme_customization_overlay_packages >/dev/null
  else settings put secure theme_customization_overlay_packages "$prev"; fi
  rm $PREV
}

palette_is_on() {
  cmd overlay list android | grep -q '^\[x\] com.android.shell:eink'
}
