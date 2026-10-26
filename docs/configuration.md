# Device configuration that goes well with the palette

Settings used on the reference phone (Hisense A9, damianmqr LineageOS 21 v3.8 microG). None of
them are required for the palette; they are collected here because they are hard to find. Each one
is a normal setting: you can also change it in the Settings app, and the adb command just does the
same thing. Commands marked *(root)* need `su`.

## E-ink appearance

| What | Settings app | adb |
|---|---|---|
| No animations | Accessibility → Colour and motion → Remove animations | `settings put global window_animation_scale 0`, the same for `transition_animation_scale` and `animator_duration_scale` |
| Grayscale | Accessibility → Colour correction → Greyscale | `settings put secure accessibility_display_daltonizer_enabled 1` and `settings put secure accessibility_display_daltonizer 0` |
| High-contrast text | Accessibility → High contrast text | `settings put secure high_text_contrast_enabled 1` |
| Bold text | Display → Bold text | `settings put secure font_weight_adjustment 300` |
| Light theme | Display → Dark theme off | `cmd uimode night no` |

With the animation scales at 0, opening apps, dialogs, the lock screen and the shade *settling* are
instant. Movement that follows your finger (pulling the shade down, swiping launcher pages) is a
gesture, not an animation, and cannot be switched off. List scrolling physics and the end-of-list
stretch are per app.

**Keyboard key-press popup** (AOSP keyboard `com.android.inputmethod.latin`): Settings → System →
Keyboard → Android Keyboard → Preferences → "Pop-up on key press" off. Note that this keyboard keeps
its preferences in device-protected storage,
`/data/user_de/0/com.android.inputmethod.latin/shared_prefs/com.android.inputmethod.latin_preferences.xml`
(key `popup_on`), not in `/data/data`.

**Quick pulldown** (LineageOS): swiping down on the right edge of the status bar opens quick
settings fully in one movement instead of notifications first. That is one slide redraw on e-ink
instead of two. Settings → System → Status bar → Quick pulldown, or *(root)*:

```sh
content insert --uri content://lineagesettings/system --bind name:s:qs_quick_pulldown --bind value:s:1
# 0 off, 1 right edge, 2 left edge, 3 always
```

(`content update` on that provider fails with "Invalid setting: null"; use `insert`, which replaces.)

## Front light: warm at night

The A9 front light has two LED channels per driver (`/sys/class/backlight/aw99703-bl-1..2`,
`ktd3137-bl-3..4`): one cold, one warm. On this ROM, **Android's Night Light switches between
them**. It is a switch, not a blend: with Night Light off only the cold channels (2, 4) are lit, and
with it on only the warm ones (1, 3), at the same level. The Night Light "intensity" slider has no
effect. The change takes effect at the next brightness update, i.e. the next time the screen wakes
or the slider moves.

Schedule it (Settings → Display → Night Light → Schedule). "Sunset to sunrise" needs a location
fix, which a degoogled phone with location off never gets, so use fixed times:

```sh
settings put secure night_display_custom_start_time 59400000   # 16:30, in ms after midnight
settings put secure night_display_custom_end_time   25200000   # 07:00
settings put secure night_display_auto_mode 1                  # 1 = custom times, 2 = sunset/sunrise
```

Switching Night Light by hand overrides the schedule until its next boundary; that is AOSP
behaviour.

**Dimmer and finer brightness:** turn on adaptive brightness and lower the A9 service's
"override max brightness" (A9 accessibility service settings; stored as `override_max_brightness`,
default 1000, reference phone 250). The whole slider then covers a smaller range, which gives
finer control at the low end.

## Battery

**EnforceDoze needs root mode for its radio options, and pre-granting its permissions breaks
that.** EnforceDoze (`com.akylas.enforcedoze`) asks Magisk for root *only if* `DUMP` and
`WRITE_SECURE_SETTINGS` are not already granted. If you granted them over adb (as many guides
suggest), it logs `SU available: false`, runs in non-root mode, and "turn off Wi-Fi / mobile data /
airplane mode in Doze" silently does nothing, even though its log says "Disabling WiFi". Fix:

```sh
adb shell pm revoke com.akylas.enforcedoze android.permission.DUMP
adb shell pm revoke com.akylas.enforcedoze android.permission.WRITE_SECURE_SETTINGS
adb shell pm revoke com.akylas.enforcedoze android.permission.READ_LOGS
# then open EnforceDoze once and grant root in the Magisk prompt; it re-grants the permissions
# itself and stores isSuAvailable=true
```

Note that "airplane mode in Doze" also blocks calls and SMS until you unlock.

**Always-on display:** the A9 ROM has an AOD quick-settings tile. *Active* AOD keeps waking the SoC
to redraw and stops ForceDoze-type apps from entering Doze; with it off, the e-ink panel simply
keeps showing the last image at no cost. `settings put secure doze_always_on 0`.
