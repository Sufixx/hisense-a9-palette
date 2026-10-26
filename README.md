# hisense-a9-palette

A pure **white / black Android UI for the Hisense A9 e-ink phone** running LineageOS 21
(Android 14). It replaces Android's generated "Material You" palette, which comes out as tinted,
off-white backgrounds and mid-grey accents, with colours that suit an e-ink panel:

- white backgrounds, panels and cards; black text, icons, switches, sliders and outlines;
- untinted greys only where a container has to be distinguishable (e.g. the main on/off bar);
- **black outlines on quick-settings tiles**.

## Why

On the A9, even the slightest greyish tint in a background causes heavy ghosting in every
refresh mode other than **Clear** (Balanced, Smooth, Speed): scrolling and switching screens leave
smeared remnants behind. The panel copes worst with changes that are not pure black-and-white, so
a light-grey background ghosts far more than a white one. Hisense's stock (Chinese) firmware is
almost purely black and white throughout the system UI for that reason, while LineageOS paints
everything in pale tinted greys. This puts the system UI back to white and black, which removes
most of that ghosting and makes the phone much more pleasant to use in the faster modes.

No ROM rebuild, no system partition edits: it is a runtime overlay, a small boot script and one
resource overlay, all switchable off.

## Before / after

Same screens, before and after. Screenshots are captured *before* the display's grayscale filter,
so on the device the "before" tints show up as light grey rather than pink. "Before" is damianmqr's
default theme (style SPRITZ, grey preset); both sides also have the system's bold text and
high-contrast text settings on, which are not part of this repo.

| | |
|---|---|
| ![Settings](screenshots/compare/1-settings.png) | ![Display](screenshots/compare/2-display.png) |
| ![Sound](screenshots/compare/3-sound.png) | ![Battery saver](screenshots/compare/4-battery-saver.png) |
| ![Quick settings](screenshots/compare/5-quick-settings.png) | ![Notifications](screenshots/compare/6-notifications.png) |

Raw captures are in [`screenshots/before`](screenshots/before) and [`screenshots/after`](screenshots/after).

## What it works on

Tested on exactly one setup:

| | |
|---|---|
| Device | Hisense A9 (`HLTE556N`, Snapdragon 662 / `bengal`, 824×1648 e-ink, 360 dpi) |
| ROM | damianmqr's Hisense A9 LineageOS 21 image **v3.8, microG variant** (A9 service `com.lmqr.ha9_comp_service` 3.8.1), from the [XDA Hisense A9 thread](https://xdaforums.com/t/hisense-a9-root-snapdragon-662.4495809/) (image `lineageos_21_microg_ha9_unofficial_damianmqr_patched_v3_8.img`) |
| Base | LineageOS 21 TrebleDroid GSI `lineage_arm64_bvN` 21.0-20240217, Android 14 `UQ1A.240205.004`, security patch 2024-02-05 |
| Root | Magisk 30.7 |
| Vendor | stock Hisense Android 11 vendor (`L2037.6.01.01`) |

It should also work on the **gapps** and **vanilla** variants of the same image (the parts
involved are the same), and very probably on other **rooted Android 14 builds with AOSP SystemUI**
(the colour part is plain AOSP). It has not been tried anywhere else. Android 15 and later changed
the theme code; expect differences there. Quick-settings outlines depend on SystemUI's drawable
names, which are build-specific.

## Installation

There are two ways to install. Use **one** of them, not both (the module refuses to run next to
the computer-based install and removes it).

| | Magisk module (recommended) | Computer-based install |
|---|---|---|
| For | everyone | development, changing the colours |
| Needs a computer to install | no | yes (`adb`, `python3`; build tools for the outlines) |
| Switch off / on | Magisk app → Action button | `adb` commands |
| Includes the outlines | yes | separate step, built from source |

### Method 1: Magisk module (recommended)

> [!WARNING]
> **Use at your own risk.** Installing needs no computer, but if something goes wrong the system
> UI can end up in a **crash loop** (status bar and shade flashing or black, launcher unusable).
> Then you **cannot fix it on the phone itself**: you need a **USB cable and a computer with ADB**,
> or a recovery. Before installing:
>
> - enable **USB debugging** (Settings → System → Developer options) and leave it on;
> - connect the phone to your computer once and accept the "Allow USB debugging" prompt, so that
>   `adb devices` lists it as `device`;
> - in Magisk → Superuser, allow root for **Shell** (run `adb shell su` once and accept);
> - keep a USB-C cable at hand.

**Install**

1. Download `hisense-a9-palette-magisk-v1.0.zip` from
   [Releases](https://github.com/Sufixx/hisense-a9-palette/releases) (optionally check it against
   `SHA256SUMS`).
2. Magisk → Modules → **Install from storage** → pick the zip.
3. Reboot. About 20 seconds after the boot finishes the colours switch to white/black, the theme
   style to monochrome, and the quick-settings tiles get outlines.

**Switch off / on without uninstalling:** Magisk → Modules → *E-ink palette (Hisense A9)* →
**Action**. Off restores the stock colours and your previous theme style and stays off after
reboots; Action again switches it back on. (Magisk's *disable* toggle is not a clean off switch:
it stops the boot script and the outlines, but leaves the colours on until SystemUI next re-applies
its theme. Use Action.)

**Uninstall / roll back**

1. Normal way: Magisk → Modules → *E-ink palette* → **Remove**, then reboot. About 10 seconds after
   that boot finishes, the palette is switched off and your previous theme style is restored.
2. **If the UI is unusable** (crash loop, flashing, no shade), from a computer over USB:
   ```sh
   adb shell su -c 'touch /data/adb/modules/eink_palette/remove' && adb reboot   # remove the module
   # or, to keep it installed but inactive:
   adb shell su -c 'touch /data/adb/modules/eink_palette/disable' && adb reboot
   ```
   If the palette colours are still on after that (possible after *disable*):
   `adb shell su -c 'cmd overlay disable com.android.shell:eink'`.
3. Last resort over ADB: `adb shell magisk --remove-modules` removes **all** Magisk modules and
   reboots.
4. Without a working ADB connection: boot Android's **safe mode**, in which Magisk disables all
   modules, then remove the module in the Magisk app; or, from a recovery that can access `/data`,
   delete `/data/adb/modules/eink_palette`. Neither of these was tested on the A9; this is why the
   warning above asks for working ADB first.

### Method 2: computer-based install (developers)

Installs the same palette from this repository over ADB. Use this to change the colours or work
on the code.

**Requirements:** Magisk root with Shell allowed in Magisk → Superuser (`adb shell su` must work),
a computer with `adb` and `python3`. For the outlines also Android SDK **build-tools** (tested
35.0.1: `aapt2`, `zipalign`, `apksigner`) and a **JDK 17+** (or Nix, which the build script falls
back to); Android Studio is not needed. For regenerating the README comparison images: Pillow.

```sh
# 1. colours (+ boot script in /data/adb/service.d, + monochrome theme style)
scripts/install.sh                 # or: scripts/install.sh --keep-theme-style
scripts/status.sh                  # check: eink after com.android.systemui:*, colours #ffffffff/#ff000000

# 2. optional: quick-settings outlines (needs one reboot)
BUILD_TOOLS=~/Library/Android/sdk/build-tools/35.0.1 overlay-systemui/build.sh
scripts/install-outlines.sh        # installs the outline-only Magisk module, reboots, enables it
```

Apps pick the new colours up immediately (they redraw on the configuration change); a reboot is
not needed for the colours. **Changing colours:** edit
[`palette/eink_palette.py`](palette/eink_palette.py) and run `scripts/install.sh` again.
**Changing the outline:** edit
[`overlay-systemui/res/drawable/qs_tile_background_shape.xml`](overlay-systemui/res/drawable/qs_tile_background_shape.xml),
rebuild, reinstall.

**Uninstall / roll back**

```sh
scripts/uninstall.sh   # stops and removes the boot script, disables the palette, restores the
                       # previous theme style, marks the outline module for removal
adb reboot             # only needed to finish removing the outline module
```

Quick off switch without uninstalling: `adb shell su -c 'cmd overlay disable com.android.shell:eink'`
(the boot script leaves a disabled palette alone). If the UI is unusable after installing the
outlines: `adb shell su -c 'touch /data/adb/modules/eink_systemui_overlay/disable' && adb reboot`.

### Building the Magisk module

```sh
BUILD_TOOLS=~/Library/Android/sdk/build-tools/35.0.1 magisk-module/build.sh
# -> magisk-module/out/hisense-a9-palette-magisk-<version>.zip + SHA256SUMS
```

It builds the outline overlay, generates the palette from `palette/eink_palette.py` and packs both
with the boot script. The APK is signed with a key generated on first build
(`overlay-systemui/key.jks`, not in the repository); keep it to sign later versions.

## How it works

Short version; details, the investigation and dead ends are in [docs/how-it-works.md](docs/how-it-works.md).

1. **Where the tint comes from.** On Android 12+ SystemUI's `ThemeOverlayController` generates
   three *fabricated* runtime overlays on the `android` package (`com.android.systemui:neutral`,
   `:accent`, `:dynamic`) that set the `system_neutral1_*`, `system_accent*_*` and Android 14's
   `system_*_light/dark` colour tokens from a seed colour. Every app using the Material 3 /
   DeviceDefault theme reads those. With this ROM's preset they gave e.g. a `#f3f0f1` Settings
   background.
2. **Palette overlay.** `palette/eink_palette.py` writes replacement values for the same 107
   colour resources (light mode only; dark-mode tokens are untouched). The installer (the Magisk
   module at its first boot, or `scripts/install.sh`) registers them as another fabricated overlay, `com.android.shell:eink`, with
   `cmd overlay fabricate --file` (root). When several enabled overlays set the same resource, the
   one registered last wins, so ours overrides SystemUI's.
3. **Boot script ("keeper").** SystemUI re-registers its overlays at boot, when it restarts and on
   every light/dark switch, which puts them back on top. `magisk/eink-palette.sh` runs at every
   boot (started by the module, or from Magisk's `service.d` with the computer-based install),
   re-registers the palette, then sleeps in busybox
   `inotifyd` on `/data/system`. When `overlays.xml` is rewritten it checks the order and, only if
   SystemUI's overlays are above ours, re-registers ours. It is event driven: no polling, no
   wakeups while the phone sleeps. A guard limits it to 3 re-registrations per minute.
4. **Theme style.** The installer also sets SystemUI's palette style to `MONOCHROMATIC`, so the
   few colours SystemUI computes by itself (not via the overlaid resources) come out grey instead
   of tinted. The previous setting is saved to `/data/system/eink-prev-theme.json` and restored when
   you switch off or uninstall.
5. **Quick-settings outlines.** Android 14's shell can only fabricate colour and integer
   values, so the outline is a classic resource overlay (RRO) APK targeting `com.android.systemui`.
   It replaces `drawable/qs_tile_background_shape` with the same rounded shape plus a 2 dp black
   stroke and `tintMode="multiply"`: SystemUI recolours the tile at runtime, and multiply changes
   the white fill to the tile colour but leaves the black stroke black. The APK goes into
   `/product/overlay` through Magisk, because SystemUI declares no overlayable resources and only
   preinstalled overlays may target it.
6. **The Magisk module** ([`magisk-module/`](magisk-module/)) bundles all of the above:
   `service.sh` copies the palette into `/data/system` at every boot, switches everything on at
   the first boot, then starts the keeper; `action.sh` is the Action button (off/on);
   `uninstall.sh` runs when Magisk removes the module, early in boot when Android's services do not
   exist yet, so it leaves a one-shot script in `service.d` that switches the palette off and
   restores the theme once the boot has finished.

## Risks

Read before installing.

- **Root-level changes to the system UI.** Everything can be undone (Action/Remove in Magisk, or
  `scripts/uninstall.sh`), but if the UI itself breaks you need a USB cable, a computer with working
  `adb` and root for Shell to undo it. Keep USB debugging and Magisk's Shell grant enabled.
- **Flicker loop (fixed, but know the symptom).** An earlier version of the boot script decided
  "ours is not on top" from the wrong list position after switching to gesture navigation and
  re-registered itself in a loop: the whole screen flashed and the launcher and shade stopped
  responding. The current check compares only with SystemUI's overlays and has a hard limit of 3
  re-registrations per minute. If you ever see repeated full-screen redraws, run
  `adb shell su -c 'logcat -d -s eink-palette'`, then stop it and reboot: with the module
  `adb shell su -c 'touch /data/adb/modules/eink_palette/disable'`, with the computer-based install
  `adb shell su -c 'rm /data/adb/service.d/eink-palette.sh'`.
- **SystemUI resource overlay.** A broken SystemUI overlay can make SystemUI crash-loop (black or
  flashing status bar, no shade). Escape hatch over adb:
  `adb shell su -c 'touch /data/adb/modules/eink_palette/disable' && adb reboot` (outline-only
  module: `eink_systemui_overlay`), or Android safe mode, in which Magisk disables all modules
  (untested on the A9). The shipped overlay only replaces one shape drawable.
- **Every re-registration redraws all apps** (it is a configuration change). Normally that happens
  once per boot and once per light/dark switch.
- **Dark mode.** Only light-mode tokens are replaced. Dark mode, including dark mode forced by some
  apps, keeps the stock dark palette.
- **ROM updates / other builds.** Resource names are stable within Android 14, but SystemUI
  drawables and theme internals change between versions and forks. After a ROM update, check
  `scripts/status.sh` before trusting it.
- **Leftover entry.** The fabricated overlay stays registered (disabled) after uninstalling;
  Android 14 offers no shell command to unregister it. It has no effect while disabled.
- **Not every app follows the system palette.** Apps with their own themes (many third-party apps)
  look exactly as before; the palette only changes apps that use the system colours (Settings,
  SystemUI, Material You apps).

## Limitations

- Fixed tinted spots: a few SystemUI surfaces (inactive tiles, notification cards) use colours
  computed in code at creation time and stay about 98 % white (`#fbf9f9`); with the grayscale
  filter that is indistinguishable from white.
- Outlines are added only to quick-settings tiles. Elsewhere you get the standard Material outlines
  (outlined buttons, text fields, switch tracks), now black.
- No settings screen. The module offers only off/on (Action button); different colours mean editing
  `palette/eink_palette.py` and rebuilding or using the computer-based install.

## Related device configuration

Settings that make the A9 nicer to use alongside this (animations off, grayscale, warm front light
at night, quick pulldown, …) with the exact commands: [docs/configuration.md](docs/configuration.md).
Troubleshooting: [docs/troubleshooting.md](docs/troubleshooting.md).

## Repository layout

| Path | What |
|---|---|
| `palette/eink_palette.py` | palette definition → overlay XML (stdout) |
| `magisk-module/` | the all-in-one Magisk module: `service.sh`, `action.sh`, `uninstall.sh`, `customize.sh`, `build.sh` |
| `magisk/eink-palette.sh` | boot script / keeper, used by both install methods |
| `scripts/install.sh`, `uninstall.sh`, `status.sh` | install, remove, diagnose (over adb) |
| `overlay-systemui/` | quick-settings outline RRO: sources, `build.sh`, outline-only `module.prop` |
| `scripts/install-outlines.sh` | computer-based install: outline-only module, reboot, enable |
| `scripts/screenshots.sh`, `compare.py` | capture the README screens, build the side-by-side images |
| `tools/frro_dump.py` | decode SystemUI's generated `.frro` palettes (investigation aid) |
| `docs/` | how it works, device configuration, troubleshooting |
| `AGENTS.md` | notes for AI coding agents working on this repo |

## Credits

- damianmqr for the Hisense A9 LineageOS images and the A9 patching service.
- The TrebleDroid / phh-treble GSI project and LineageOS, on which the ROM is based.
- topjohnwu for Magisk.

## License

[GPL-3.0](LICENSE). You may use, change and share this, including modified versions, as long as
what you distribute stays under the GPL with its source available.
`overlay-systemui/res/drawable/qs_tile_background_shape.xml` is a modified copy of an AOSP file
(Apache-2.0, © The Android Open Source Project), which is compatible with GPL-3.0.
