# Troubleshooting

Start with `scripts/status.sh`. It shows the overlay order, the resolved colours, whether the
keeper runs and its last log lines, the outline overlay state and the theme style.

## Colours are tinted / grey again

- **Order:** `com.android.shell:eink` must be listed *after* every `com.android.systemui:*` overlay
  in `cmd overlay list android`. If it isn't, check the keeper is running (status.sh) and see its
  log: `adb shell su -c 'logcat -d -s eink-palette'`. To fix by hand, run `scripts/install.sh`.
- **"skipped: already 3 fixes in the last minute"** in the log means something re-applied the
  theme more than 3 times in a minute. The keeper backs off; the next change after the minute
  fixes it. If it repeats, find what keeps changing overlays (`logcat -d | grep ThemeOverlayController`).
- **An app still looks the same:** it does not use the system palette. Nothing to do here.
- **Dark mode is on** (Settings → Display → Dark theme, or an app forcing it): only light-mode
  colours are replaced.

## Screen keeps flashing / shade and launcher unresponsive

That is the overlay loop described in [how-it-works.md](how-it-works.md#why-a-keeper-is-needed).
The current keeper has a guard against it. If it happens anyway:

```sh
adb shell su -c 'logcat -d -s eink-palette | tail'          # confirm: many "moved ... back on top"
adb shell su -c 'mv /data/adb/service.d/eink-palette.sh /data/adb/eink-palette.sh.off'
adb reboot
```

Do not stop it with `pkill -f eink-palette` inside `su -c '…'`: `-f` also matches that shell's own
command line and kills it first. Find the PID with `ps -A -o pid,args | grep inotifyd` and `kill` it.

## SystemUI crashes or the status bar is black after installing the outlines

```sh
adb shell su -c 'cmd overlay disable io.github.sufixx.eink.systemui'      # immediate
adb shell su -c 'touch /data/adb/modules/eink_systemui_overlay/disable' && adb reboot   # persistent
```

Without adb: boot Magisk safe mode (hold volume down during boot on most devices), which disables
all modules.

## Outline overlay is installed but not listed / not enabled

- It only appears after a reboot (it lives in `/product/overlay`). Check it with
  `adb shell su -c 'cmd overlay list com.android.systemui | grep eink'`.
- `[ ]` means installed but disabled: `cmd overlay enable io.github.sufixx.eink.systemui`.
- Not listed at all: check `ls /product/overlay/EinkPaletteSystemUI/` on the phone and
  `logcat -d | grep -i EinkPaletteSystemUI` for package-parsing errors (for example an unsigned APK).
- Still listed under an **old package name** after changing the manifest's `package`: the package
  manager keeps the name it recorded for that APK path. Change the directory/APK name (`NAME` in
  `overlay-systemui/build.sh`) together with the package name.

## `install.sh` hangs or the keeper does not start

The keeper is started detached with `nohup setsid`. That keeps the `adb shell` session open, so
the script drops the local adb client after 3 s; that is expected. Check that it runs:
`adb shell su -c "ps -A -o pid,args" | grep inotifyd`. Magisk starts it at every boot anyway.

## `cmd overlay fabricate` errors

| Message | Cause |
|---|---|
| `must be root to fabricate overlays through the shell` | not run through `su` (or quoting broke the `su -c '…'` string, e.g. an apostrophe in a comment) |
| `FileNotFoundException` for the XML | file in `/data/local/tmp`; system_server needs it in `/data/system` |
| `For input string: "#ffffffff"` | XML values must be `0xAARRGGBB` |
| `For input string: "dimen"` | `--file` only knows `color`/`string`/`drawable` targets |
| `dataType is out of range of [16, 31]` | only integer/colour types can be fabricated from the shell on Android 14 |
