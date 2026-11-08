#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir="build/rendering-tests/RenderingTests.app/Contents"
mkdir -p "$test_dir/MacOS" "$test_dir/Resources"
xcrun metal -c SnowfallApp/Sources/Common/SnowShader.metal -o build/rendering-tests/SnowShader.air
xcrun metallib build/rendering-tests/SnowShader.air -o "$test_dir/Resources/default.metallib"
xcrun swiftc -O -parse-as-library \
  SnowfallApp/Sources/Common/Settings.swift \
  SnowfallApp/Sources/Common/Snowflake.swift \
  SnowfallApp/Sources/Common/SnowSimulation.swift \
  SnowfallApp/Sources/Common/SnowRenderPolicy.swift \
  SnowfallApp/Sources/Common/SnowRenderer.swift \
  SnowfallApp/Sources/Common/WindowInfo.swift \
  SnowfallApp/Sources/Views/MetalSnowViewController.swift \
  Tests/RenderingRegression.swift \
  -o "$test_dir/MacOS/RenderingTests"
"$test_dir/MacOS/RenderingTests"
