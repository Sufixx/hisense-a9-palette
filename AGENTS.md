# AGENTS.md

Notes for AI coding agents (and humans) changing this repository. Read
[docs/how-it-works.md](docs/how-it-works.md) first; it records the dead ends.

## What this is

A white/black system palette for the Hisense A9 e-ink phone on LineageOS 21 (Android 14). It is a
fabricated runtime overlay plus a Magisk boot script, and an RRO APK that adds outlines to
quick-settings tiles. Two install methods: the all-in-one Magisk module (`magisk-module/`, the
recommended one and the only release asset) and the computer-based scripts (`scripts/`). They must
never be active together: the module's `customize.sh` removes the scripts' keeper, and
`scripts/install.sh` refuses to run while the module is installed.

## Layout and responsibilities

- `palette/eink_palette.py`: the single source of the colours. Stdlib only, prints the overlay
  XML to stdout. Light-mode tokens only, on purpose.
- `magisk/eink-palette.sh`: the keeper, shared by both methods. Runs **on the phone** as root under
  `/system/bin/sh` (mksh/toybox, plus Magisk busybox). No bash-isms, no GNU options. It finds itself
  with `readlink -f "$0"`, so it works from `service.d` and from the module directory.
- `magisk-module/`: `common.sh` (palette_on/off, shared by `service.sh` and `action.sh`),
  `service.sh` (boot), `action.sh` (Magisk Action button), `uninstall.sh` (runs at removal, early in
  boot, so it defers its cleanup to a one-shot `service.d` script), `customize.sh` (install time:
  file operations only), `build.sh` (release zip). `customize.sh` and `uninstall.sh` must not call
  `cmd` or `settings`: Android is not up at those points (or may not be).
- `scripts/*.sh`: run **on the computer** (bash) and drive the phone over `adb shell "su -c '…'"`.
- `overlay-systemui/`: the RRO sources, `build.sh`, and the Magisk `module.prop`.
- `tools/frro_dump.py`: reads SystemUI's generated `.frro` palettes (for investigating).

## Rules that are easy to break

- **Quoting:** phone commands are nested in `adb shell "su -c '…'"`. A single apostrophe anywhere
  inside, even in a comment, ends the `su -c` string, and the rest runs unprivileged ("must be
  root to fabricate"). Escape `$` as `\$` for anything that must expand on the phone.
- **Never `pkill -f <pattern>` / `pgrep -f` inside `su -c`:** the su shell's own command line
  contains the pattern, so it kills or finds itself. Match `ps -A -o args` against an anchored
  pattern instead.
- **Keeper changes must stay loop-safe.** Every re-registration rewrites
  `/data/system/overlays.xml`, which wakes the keeper again, and makes every app redraw. Any order
  check must reach "nothing to do" after one fix, and the rate limit must stay. Test with gesture
  navigation enabled (it adds overlays listed after ours) and with
  `cmd uimode night yes; cmd uimode night no`, then watch `logcat -s eink-palette` for a minute.
- **No polling on the phone.** It is a battery-first e-ink device: event driven (inotifyd) only.
- **`cmd overlay fabricate` limits on Android 14:** XML file in `/data/system`, values `0x…`,
  types colour/integer only (see the table in docs/troubleshooting.md).
- **Overlay package name** `io.github.sufixx.eink.systemui` and module ids `eink_palette` /
  `eink_systemui_overlay` appear in the scripts and docs; rename everywhere at once. When renaming the package, also
  change `NAME` in `overlay-systemui/build.sh`: the package manager keeps the old package name
  for an APK path it already knows.
- **Signing key** (`overlay-systemui/key.jks`) is generated locally and gitignored. Never commit
  keys, APKs or zips (see `.gitignore`).

## Testing a change

There is no emulator setup; test on the phone:

1. `scripts/install.sh`, then `scripts/status.sh`: eink after `com.android.systemui:*`, colours
   resolve to `#ffffffff`/`#ff000000`.
2. Light/dark toggle (above) and `kill $(pidof com.android.systemui)`: the keeper logs exactly one
   "moved … back on top" per SystemUI re-apply, then stays quiet.
3. Reboot: the keeper runs (`ps -A -o args | grep inotifyd`) and status is green 30 s after boot.
4. Outline changes: `overlay-systemui/build.sh`, `scripts/install-outlines.sh`, open quick
   settings.
5. Module changes: `magisk-module/build.sh`, install the zip (`magisk --install-module`), reboot,
   `scripts/status.sh`; then Action off/on (`sh /data/adb/modules/eink_palette/action.sh`), off
   across a reboot, and removal (`touch .../remove`, reboot: stock colours and theme, no leftovers).
6. Screenshots for the README: `scripts/screenshots.sh screenshots/after` (the phone in English,
   unlocked, untouched), then `scripts/compare.py screenshots/before screenshots/after
   screenshots/compare`.

## Style

Shell: `set -euo pipefail` on the computer side, short comments that say *why*. Python: stdlib only
except `scripts/compare.py` (Pillow). Docs: plain English, concrete commands, no marketing.
