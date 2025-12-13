<div align="center">

# ❄️ Snowfall

**Beautiful interactive snowfall overlay for macOS**

A lightweight menubar app that brings winter magic to your desktop with GPU-accelerated snowflakes that interact with your windows.

[Features](#-features) • [Installation](#-installation) • [Demo](#-demo) • [Configuration](#%EF%B8%8F-configuration) • [Privacy](#-privacy)

[![macOS](https://img.shields.io/badge/macOS-11.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Metal](https://img.shields.io/badge/Metal-GPU-green.svg)](https://developer.apple.com/metal/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## ✨ Features

### Core Functionality
- **🎨 GPU-Accelerated Rendering** — Powered by Metal for smooth performance with thousands of particles
- **🪟 Window Collision Physics** — Snowflakes realistically melt when landing on window borders
- **🖱️ Mouse Interaction** — Snowflakes react dynamically to cursor movement
- **🌬️ Wind Simulation** — Adjustable wind strength affects snowflake trajectories
- **🖥️ Multi-Monitor Support** — Works seamlessly across all connected displays

### Customization
- **3 Built-in Presets**: Light Snow, Comfortable Background, Blizzard
- **Granular Controls**:
  - Speed range (0.1–8.0)
  - Size range (1–25)
  - Particle count (100–10,000)
  - Wind strength (0–500)
- **Privacy-Focused** — All processing happens locally; no data collection

---

## 📦 Installation

### Homebrew (Recommended)
Get automatic updates via [Homebrew](https://brew.sh/):

```
brew install --cask barredewe/cask/snowfall
```

### Manual Installation
1. Download the latest release from [Releases](https://github.com/barredewe/snowfall/releases)
2. Unzip and move `Snowfall.app` to `/Applications`
3. Launch and grant Screen Recording permission when prompted


### App Store

`// TODO`

---

## 🎬 Demo

<div align="center">

<img src="Resources/Snowfall-example.gif"/>

</div>

---

## ⚙️ Configuration

Access settings via the menubar icon (❄️):

### Presets

| Mode | Particles | Speed | Size | Wind | Best For |
|------|-----------|-------|------|------|----------|
| **Light Snow** | 800 | 0.2–1.5 | 2–12 | 0.5 | Minimal distraction |
| **Comfortable** | 2,000 | 0.5–3.0 | 3–15 | 1.0 | Balanced aesthetics |
| **Blizzard** | 6,000 | 2.0–8.0 | 2–20 | 4.0 | Maximum winter vibes |
| **Custom** | — | — | — | — | Manual tuning |

### Advanced Settings

**Window Interaction**  
Toggle collision physics for performance-critical workflows. When enabled:
- Uses `CGWindowListCopyWindowInfo` API to detect window positions
- Processes data in RAM only (no recording/storage)
- Snowflakes melt gradually upon contact

**Mouse Influence Radius**: 50px default

---

## 🏗️ Technical Architecture

### Technology Stack
- **Language**: Swift 5.9+ with SwiftUI
- **Graphics**: Metal API for compute & render pipelines
- **Physics**: Custom particle system with SIMD2 vectors
- **Platform**: macOS 11.0+ (Big Sur and later)

### Key Components

```
SnowfallApp/
├── Common/
│   ├── Views/
│   │   ├── MenuBarSettings.swift      # SwiftUI preferences UI
│   │   └── MetalSnowViewController.swift  # MTKView controller
│   ├── Settings.swift                 # Codable configuration
│   ├── Snowflake.swift                # Particle data structure
│   ├── SnowRenderer.swift             # Metal pipeline manager
│   └── WindowInfo.swift               # CGWindowListCopyWindowInfo wrapper
├── SnowfallApp.swift                  # App entry point
└── SnowShader.metal                   # GPU kernels (compute + render)
```

### Performance Optimization
- **Compute Shader**: Parallel particle updates on GPU
- **Instanced Rendering**: Single draw call for all particles
- **Adaptive Caching**: Window positions refreshed every 500ms
- **Point Primitives**: Efficient anti-aliased circles via fragment shader

---

## 🛠️ Building from Source

### Requirements
- Xcode 15.0+
- macOS 13.0+ SDK
- Swift 5.9+

### Build Steps

```
# Clone repository
git clone https://github.com/barredewe/snowfall.git
cd snowfall

# Open in Xcode
open Snowfall.xcodeproj

# Build & Run (⌘R)
```

---

## 🔒 Privacy

**Zero Data Collection Policy**

Snowfall operates entirely offline:
- ✅ No network requests
- ✅ No analytics/tracking
- ✅ No third-party SDKs
- ✅ All settings stored locally (`UserDefaults`)

**Permissions Explained**:
- **Screen Recording**: Required only for window collision detection
- **Accessibility**: Alternative permission for older macOS versions

See [PRIVACY.md](PRIVACY.md) for full policy.

---

## 🤝 Contributing

Contributions are welcome!

**Development Setup**:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
4. Submit PR with detailed description

---

## 📄 License

Apache 2.0 License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Metal framework by Apple
- Inspiration from classic screensavers
- Icon design: SF Symbols

---

## 📧 Contact

**Barredewe**  
📮 barredewe@gmail.com  
🐙 [GitHub](https://github.com/barredewe)

---

<div align="center">

**If you enjoy Snowfall, please ⭐ star this repository!**

Made with ❄️ in Russia

</div>
