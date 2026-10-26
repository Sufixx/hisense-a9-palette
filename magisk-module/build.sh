#!/bin/bash
# Build the release file magisk-module/out/hisense-a9-palette-magisk-<version>.zip (all-in-one
# Magisk module: palette + keeper + quick-settings outlines) and its SHA256SUMS.
# Needs what overlay-systemui/build.sh needs (BUILD_TOOLS, FRAMEWORK_RES or a connected phone, a JDK)
# plus python3.
set -euo pipefail
cd "$(dirname "$0")"
version=$(sed -n 's/^version=//p' module.prop)

../overlay-systemui/build.sh
rm -rf out && mkdir -p out/stage

cp module.prop customize.sh service.sh action.sh uninstall.sh common.sh out/stage/
cp -R META-INF out/stage/
cp ../magisk/eink-palette.sh out/stage/
python3 -I ../palette/eink_palette.py > out/stage/eink.xml
cp -R ../overlay-systemui/out/module/system out/stage/

(cd out/stage && zip -qr -X "../hisense-a9-palette-magisk-$version.zip" . -x '*.DS_Store')
rm -rf out/stage
(cd out && shasum -a 256 *.zip > SHA256SUMS && cat SHA256SUMS)
