# How it works (and what did not work)

Background for maintainers. Everything here was verified on the reference phone (Android 14,
LineageOS 21 GSI with damianmqr's A9 patches).

## Where the colours come from

Android 12+ derives the system palette from a seed colour. On Android 14 SystemUI's
`ThemeOverlayController` reads `settings secure theme_customization_overlay_packages`, e.g.

```json
{"android.theme.customization.theme_style":"SPRITZ",
 "android.theme.customization.color_source":"preset",
 "android.theme.customization.system_palette":"333333"}
```

and registers three **fabricated overlays** targeting `android`:

| Overlay | Resources |
|---|---|
| `com.android.systemui:neutral` | `system_neutral1_*`, `system_neutral2_*` (10…1000) |
| `com.android.systemui:accent` | `system_accent1_*` … `system_accent3_*` |
| `com.android.systemui:dynamic` | Android 14 tokens: `system_background_light`, `system_surface_container_*_light`, `system_on_surface_light`, `system_outline_light`, `system_primary_*`, … and their `_dark` twins |

They are stored as `/data/resource-cache/com.android.systemui-*-XXXX.frro`. The `.frro` format is a
header followed by a protobuf; the [notes below](#reading-frro-files) show how they
were read. With the ROM's preset the Settings background, `system_neutral1_50`, was `#f3f0f1`.

## The palette overlay

`cmd overlay fabricate` (root only) creates another fabricated overlay. On Android 14:

- One resource on the command line: `cmd overlay fabricate --target android --name NAME
  android:color/x 0x1c 0xffffffff`. Only data types 16–31 (integers and colours) are accepted.
  Dimensions fail with "dataType is out of range of [16, 31]".
- Many resources: `--file FILE` with
  ```xml
  <overlay>
    <item target="color/system_neutral1_50" type="0x1c" value="0xffffffff" />
  </overlay>
  ```
  `target` must be `type/name` with a type it knows (`color`, `string`, `drawable`, or a number);
  `dimen/...` fails with "For input string: dimen". Values must be `0x…` numbers, not `#rrggbb`.
- The file is read by **system_server**, which SELinux does not allow to read `/data/local/tmp`
  (FileNotFoundException). `/data/system/` works.
- The overlay is owned by the caller's package, so from `adb shell` it is `com.android.shell:NAME`.
  Re-running `fabricate` with the same name replaces the values in place and moves it to the end
  of the order.
- `cmd overlay set-priority` does not work on fabricated overlays ("Unable to retrieve overlay
  information").
- There is no shell command to unregister one; `disable` is the way to switch it off.

**Ordering:** when several enabled overlays define a resource, the one later in
`cmd overlay list android` wins. Ours must come after the three SystemUI ones.

## Why a keeper is needed

SystemUI re-registers its three overlays whenever it (re)applies the theme: at boot, when SystemUI
restarts, and on every light/dark switch (also `cmd uimode night yes|no`). Each time they land
after ours and the tinted palette returns. Battery Saver can also force dark mode, but on this ROM
the battery saver's `enable_night_mode` is false, so it does not.

The keeper, `magisk/eink-palette.sh`, does this:

1. At boot (Magisk `service.d`) it waits for `sys.boot_completed`, plus 15 s for SystemUI to apply
   its theme, and re-registers ours.
2. It then `exec`s Magisk's busybox `inotifyd` on `/data/system` (events `w` close-write and
   `y` moved-in). OverlayManagerService rewrites `/data/system/overlays.xml` on every overlay
   change, and inotifyd re-runs the script with `<event> <dir> <file>`.
3. For `overlays.xml` it compares the line numbers of `com.android.shell:eink` and the last
   `com.android.systemui:` entry among the *enabled* overlays. Only if SystemUI's come later does it
   re-register ours (at most 3 times a minute; timestamps in `/dev/eink-palette.stamps`).
4. If our overlay is disabled, it does nothing, so `cmd overlay disable` is a working off switch.

Being event driven, it costs nothing while the phone sleeps. The process sleeps in `inotify`
reads, and a suspended CPU is never woken for it.

**Bug found the hard way:** the first version checked "is ours the *last* enabled overlay". After
switching to gesture navigation, `com.android.internal.systemui.navbar.gestural` and
`org.lineageos.overlay.customization.navbar.nohint` were listed after ours. The check never passed,
so every re-registration rewrote `overlays.xml`, which triggered the next one, about once a second.
Each one is a configuration change, so all apps redrew and the screen flashed, with the launcher
and shade unusable. Hence the comparison with SystemUI's overlays only, plus the rate limit.

## Theme style

The tiles' fill and notification cards use colours SystemUI computes in code when it creates them,
not the overlaid resources, so they kept a slight tint. `MONOCHROMATIC` (an Android 14 style) makes
SystemUI's own palette chroma-free, which turns those into neutral greys. `install.sh` saves the
previous value to `/data/system/eink-prev-theme.json` for `uninstall.sh`.

## Quick-settings outlines

Things that did **not** work:

- `android:dimen/config_qsTileStrokeWidthInactive` / `…Active` exist in framework-res (value
  `-1dp`), but this SystemUI never reads them: neither resource ID appears in its dex files or
  compiled XML. Overriding them would do nothing, besides fabricated overlays not accepting
  dimensions anyway.
- Colours alone cannot add borders.

What works: SystemUI's `drawable/qs_tile_background` is a ripple whose mask and `@id/background`
layers both use `drawable/qs_tile_background_shape`, a white rounded rectangle (28 dp radius).
`QSTileViewImpl` recolours the background layer at runtime for the active, inactive and unavailable
states. The overlay replaces only the shape:

```xml
<shape android:shape="rectangle" android:tintMode="multiply">
    <corners android:radius="28dp" />
    <solid android:color="#ffffffff" />
    <stroke android:width="2dp" android:color="#ff000000" />
</shape>
```

With the default `SRC_IN` tint the stroke would take the fill colour and vanish. With `multiply`
the white fill becomes the tint colour (white × c = c) and the black stroke stays black (black ×
c = black). Unavailable tiles are drawn semi-transparent by SystemUI, so their outline shows grey.

Packaging: SystemUI declares no `<overlayable>`, so only overlays from a system partition (or
signed with the platform key) may target it. The Magisk module places the APK in
`/system/product/overlay/EinkPaletteSystemUI/`, which Magisk mounts into `/product/overlay`. The APK
must be signed, but any key is accepted for a preinstalled overlay. It is `isStatic="false"` so
it can be toggled with `cmd overlay enable|disable io.github.sufixx.eink.systemui`. A non-static
overlay starts disabled; it is enabled once after the first boot, and that state persists.

## Reading .frro files

```python
# header ("FRRO", version, crc, ...) then a protobuf
# (FabricatedOverlayInternal: packages → types → entries{name, value{data_type, data_value}})
b = open(path, 'rb').read()[0x30:]   # this ROM's files had the protobuf at offset 0x30
```

A 30-line varint walker is enough. Running `cmd overlay lookup com.android.systemui
android:color/<name>` is the simpler way to see the *resolved* value of any resource.
