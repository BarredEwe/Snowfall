# Rendering performance

Measured on 8 November 2026 on an Apple M3 Max (14 CPU / 30 GPU cores, 36 GiB RAM), macOS 26.2, one 3456×2234 Retina display. Both builds used 2000 particles and window interaction. Results are specific to this machine and workload.

| Metric | Previous renderer | Optimized renderer |
|---|---:|---:|
| Physical footprint | 475.64 MiB | 249.30 MiB |
| Metal resource allocation | 91.34 MiB | 16.13 MiB |
| GPU command-buffer time per second | 114.65 ms | 1.48 ms |
| Mean CPU, percent of one core | 4.37% | 3.38% |
| Frame rate | 59.97 | 30.00 |
| Drawable size | 3456×2234 | 1728×1117 |

GPU command-buffer time fell by about 98.7%; physical footprint fell by about 47.6%. CPU improvement is smaller and variable: other exploratory runs of the optimized renderer averaged about 1.8%. The table uses the final matched comparison rather than the most favorable run.

The controlled pause test measured 25.53 MiB footprint and 0.49% mean CPU (1.8% maximum), with no GPU reports during its stable 10-second sampling window. GPU rendering resumed afterward. This test posts app-local sleep/wake notifications; it does not put the actual display to sleep. Automatic visibility handling is also checked with a real AppKit window being hidden. The browser fullscreen check was interrupted by window changes and is not considered a verified fullscreen performance measurement.

Machine-readable measurements are in [performance-results-2026-11-08.json](performance-results-2026-11-08.json). Raw `top`, `footprint`, `sample`, and GPU logs are retained locally in `build/performance/`.

## What changed

- Particle physics runs on the CPU. Two protected shared buffers hand immutable particle snapshots to a single GPU render pass. There is no per-frame compute pass or CPU wait for GPU completion.
- A display's drawable is limited to 2,073,600 pixels and two drawable buffers. Simulation coordinates remain in display pixels; the shader scales particle size to preserve its apparent size. Reduced resolution can soften very small flakes.
- Rendering uses 30 FPS, or 20 FPS in Low Power Mode and serious/critical thermal states. Travel speed remains based on elapsed time, so reducing frame rate does not slow the snowfall. Motion is less smooth than the previous 60 FPS setting.
- Hidden overlays, sleeping displays and inactive user sessions pause their render loop. Metal buffers, pipeline and queue are released while paused, then recreated on resume without discarding particle positions. A late timer callback safely exits after resources are released.
- Displays share one cached window-list query per 500 ms. Launchpad detection uses that same list. Temporary objects are drained each frame.

The active renderer still has a substantial driver graphics footprint, separate from the 16 MiB of Metal resources. A Core Graphics experiment reduced footprint to roughly 40–43 MiB but consumed more than 20% CPU, so it is excluded from the product. There is one rendering implementation and no alternate renderer selected at runtime.

## Reproduce

Run only one Snowfall process at a time. Close its settings panel and keep the display, preset and window interaction settings unchanged between runs. Background applications affect measurements.

```sh
xcodebuild -project SnowfallApp.xcodeproj -scheme SnowfallApp \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/ProfileOptimized build \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=SNOWFALL_PROFILING \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual

bash scripts/profile-rendering.sh \
  build/ProfileOptimized/Build/Products/Release/SnowfallApp.app optimized

python3 scripts/profile-idle.py \
  build/ProfileOptimized/Build/Products/Release/SnowfallApp.app

bash scripts/test-rendering.sh
```

The profiling flag compiles in five-second stdout counters using `MTLCommandBuffer.gpuStartTime` / `gpuEndTime` and `MTLDevice.currentAllocatedSize`. The profiling-only `--profile-pause` argument emits app-local sleep/wake notifications at 10 and 30 seconds. These counters and controls are absent from normal release builds.

GPU timings measure Snowfall's command buffers, not total GPU occupancy, watts or WindowServer composition. System `powermetrics` requires administrator credentials and was unavailable. Other GPU activity was present on the machine, so global GPU utilization cannot be attributed to Snowfall. CPU percentages are per core; 100% represents one fully occupied core. `footprint` includes driver graphics allocations that RSS does not expose.

The regression executable checks particle motion, melting, wrapping, mouse interaction, preset ranges, travel speed at 30/60 FPS, render pixel budgets, energy policy, pause/resume resource ownership, a queued callback after pause, and actual Metal pixel output at two drawable scales. Multi-display runtime, Intel runtime and physical sleep/wake remain unmeasured; the release archive is built for both arm64 and x86_64.
