#!/bin/bash
# Build the SystemUI outline overlay (RRO) and wrap it in a Magisk module:
#   out/eink_systemui_overlay.zip
#
# Needs:
#   BUILD_TOOLS   Android SDK build-tools dir with aapt2, zipalign, lib/apksigner.jar
#                 (tested with 35.0.1; default: newest under $ANDROID_HOME/build-tools)
#   FRAMEWORK_RES framework-res.apk of the target phone, used only to resolve android: attributes
#                 (default: pulled from the connected phone into out/)
#   java          JDK 17+ for keytool/apksigner; if missing, `nix shell nixpkgs#jdk17_headless` is used
#
# Signing: a preinstalled (product partition) overlay may be signed with any key. A key is
# generated once into ./key.jks (gitignored); keep it to sign later updates with the same key.
set -euo pipefail
cd "$(dirname "$0")"

if [ -z "${BUILD_TOOLS:-}" ]; then
  sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}
  BUILD_TOOLS=$(ls -d "$sdk"/build-tools/* 2>/dev/null | sort -V | tail -1 || true)
fi
[ -x "${BUILD_TOOLS:-}/aapt2" ] || { echo "set BUILD_TOOLS to an Android build-tools directory" >&2; exit 1; }

NAME=EinkPaletteSystemUI
rm -rf out && mkdir -p out/module/system/product/overlay/$NAME
if [ -z "${FRAMEWORK_RES:-}" ]; then
  FRAMEWORK_RES=out/framework-res.apk
  adb pull /system/framework/framework-res.apk "$FRAMEWORK_RES" >/dev/null
fi

"$BUILD_TOOLS/aapt2" compile --dir res -o out/res.zip
"$BUILD_TOOLS/aapt2" link -o out/unsigned.apk -I "$FRAMEWORK_RES" --manifest AndroidManifest.xml \
  --min-sdk-version 34 --target-sdk-version 34 out/res.zip
"$BUILD_TOOLS/zipalign" -f -p 4 out/unsigned.apk out/aligned.apk

sign="
  set -e
  [ -f key.jks ] || keytool -genkeypair -keystore key.jks -storepass eink-overlay -alias eink \
    -keyalg RSA -keysize 2048 -validity 36500 -dname CN=eink-overlay >/dev/null 2>&1
  java -jar '$BUILD_TOOLS/lib/apksigner.jar' sign --v4-signing-enabled false \
    --ks key.jks --ks-pass pass:eink-overlay \
    --out out/module/system/product/overlay/$NAME/$NAME.apk out/aligned.apk
"
if command -v java >/dev/null && java -version >/dev/null 2>&1; then
  bash -c "$sign"
else
  nix shell nixpkgs#jdk17_headless -c bash -c "$sign"
fi

cp module.prop out/module/
cp -R ../magisk-module/META-INF out/module/  # standard Magisk installer stub
(cd out/module && zip -qr ../eink_systemui_overlay.zip .)
echo "built out/eink_systemui_overlay.zip"
