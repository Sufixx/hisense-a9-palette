#!/usr/bin/env python3
"""Generate the e-ink colour overlay (input for `cmd overlay fabricate --file`).

SystemUI's monet overlays (com.android.systemui:neutral/accent/dynamic) give a tinted
off-white UI (#f3f0f1 Settings background). This overrides the same framework colours,
light-mode only: pure white surfaces, black text/primary/outlines, untinted greys.
Dark-mode (*_dark) colours are left alone.
Usage: eink_palette.py > eink.xml
"""

WHITE, BLACK = 0xFFFFFFFF, 0xFF000000


def grey(v):
    return 0xFF000000 | v << 16 | v << 8 | v


colors = {}

# Tonal palettes, untinted. neutral 10/50/100 = backgrounds (100 = shade) -> white; accents get darker
# sooner than stock so legacy "accent1_600" UI (switches, links) comes out black.
neutral = {10: 0xFF, 50: 0xFF, 100: 0xFF, 200: 0xD0, 300: 0xB0, 400: 0x90, 500: 0x70,
           600: 0x50, 700: 0x38, 800: 0x24, 900: 0x12, 1000: 0x00}
accent = {10: 0xFF, 50: 0xF0, 100: 0xDD, 200: 0xBB, 300: 0x88, 400: 0x55, 500: 0x33,
          600: 0x00, 700: 0x00, 800: 0x00, 900: 0x00, 1000: 0x00}
for pal, tones in (("neutral1", neutral), ("neutral2", neutral),
                   ("accent1", accent), ("accent2", accent), ("accent3", accent)):
    for tone, v in tones.items():
        colors[f"system_{pal}_{tone}"] = grey(v)

light = {
    # surfaces: white; only the "highest" containers (QS tiles, text fields) stay light grey
    "background": WHITE, "surface": WHITE, "surface_bright": WHITE,
    "surface_container_lowest": WHITE, "surface_container_low": WHITE,
    "surface_container": WHITE, "surface_container_high": WHITE,
    "surface_container_highest": grey(0xE8), "surface_variant": grey(0xE8),
    "surface_dim": grey(0xE0),
    "on_background": BLACK, "on_surface": BLACK, "on_surface_variant": grey(0x1A),
    # outlines/dividers dark so shapes read as drawn lines on e-ink
    "outline": BLACK, "outline_variant": grey(0x40),
    "control_normal": BLACK, "control_activated": BLACK,
    "error": BLACK, "on_error": WHITE, "error_container": grey(0xE8), "on_error_container": BLACK,
}
for role in ("primary", "secondary", "tertiary"):
    light[role] = BLACK
    light[f"on_{role}"] = WHITE
    light[f"{role}_container"] = grey(0xD8)
    light[f"on_{role}_container"] = BLACK
for name, v in light.items():
    colors[f"system_{name}_light"] = v

for role in ("primary", "secondary", "tertiary"):  # fixed roles have no light/dark variant
    colors[f"system_{role}_fixed"] = grey(0xD8)
    colors[f"system_{role}_fixed_dim"] = grey(0xB8)
    colors[f"system_on_{role}_fixed"] = BLACK
    colors[f"system_on_{role}_fixed_variant"] = grey(0x22)

print("<overlay>")
for name, v in sorted(colors.items()):
    print(f'  <item target="color/{name}" type="0x1c" value="0x{v:08x}" />')
print("</overlay>")
