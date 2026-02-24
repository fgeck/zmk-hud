# ZMK HUD

A macOS app that displays a floating HUD showing your ZMK keyboard's active layer with real-time key highlighting and combo visualization.

![HUD Preview](docs/preview.png) <!-- TODO: Add screenshot -->

## Features

- **Live Layer Display** — See your current layer with full keymap visualization
- **Real-time Key Highlighting** — Visual feedback as you type
- **Combo Reference** — Dendron lines and side panels showing your combos
- **Keymap-Drawer Compatible** — Uses your existing `keymap_drawer.config.yaml` for styling
- **Dark Mode** — Follows system appearance
- **Configurable** — Position, opacity, combo display modes

## Installation

### macOS App

**Via Homebrew (Recommended):**
```bash
brew tap fgeck/tap
brew install --cask zmk-hud
```

**Manual Download:**
Download the latest `.app` from [Releases](../../releases).

### ZMK Firmware Module

The firmware module sends layer and key events from your keyboard to the app via USB HID.

#### 1. Add modules to `config/west.yml`

Add these remotes and projects to your existing `west.yml`:

```yaml
manifest:
  remotes:
    # ... your existing remotes ...
    - name: fgeck                    # ADD
      url-base: https://github.com/fgeck
    - name: zzeneg                   # ADD
      url-base: https://github.com/zzeneg
  projects:
    # ... your existing projects ...
    - name: zmk-hud                  # ADD
      remote: fgeck
      revision: main
    - name: zmk-raw-hid              # ADD
      remote: zzeneg
      revision: main
```

#### 2. Add shield to `build.yaml`

Add `raw_hid_adapter` to your **central side** (the USB-connected side):

```yaml
include:
  - board: nice_nano_v2
    shield: your_keyboard_left raw_hid_adapter   # ADD raw_hid_adapter here
  - board: nice_nano_v2
    shield: your_keyboard_right                  # peripheral - no changes
```

#### 3. Enable in `.conf`

Add to your central side's `.conf` file (e.g., `your_keyboard_left.conf`):

```ini
CONFIG_RAW_HID=y
CONFIG_ZMK_HUD=y
```

#### 4. Build and flash

```bash
west update
west build -b nice_nano_v2 -- -DSHIELD="your_keyboard_left raw_hid_adapter"
west flash
```

> 📖 **Detailed instructions**: See [firmware/README.md](firmware/README.md) for complete examples and troubleshooting.

## Configuration

The app reads your keymap files to display the correct layout:

| File | Purpose | Location |
|------|---------|----------|
| `*.keymap` | Key bindings and combos | Your zmk-config repo |
| `info.json` | Physical layout (QMK format) | Your zmk-config repo |
| `keymap_drawer.config.yaml` | Colors and styling | Your zmk-config repo |

### App Settings

Open Settings (⌘,) to configure:

- **Keymap File** — Path to your `.keymap` file
- **Layout File** — Path to QMK `info.json` or physical layout
- **Config File** — Path to `keymap_drawer.config.yaml` (optional)
- **Combo Display** — Both sides, dendrons only, panels only, or none
- **Position** — Screen corner for the HUD
- **Opacity** — HUD transparency

## Requirements

- **macOS**: 13.0+ (Ventura or later)
- **Keyboard**: ZMK firmware with Raw HID support
- **Connection**: USB (Raw HID doesn't work over Bluetooth)

## How It Works

```
┌──────────────┐    USB HID     ┌──────────────┐
│ ZMK Keyboard │ ────────────▶ │  ZMK HUD App │
│              │   32-byte      │              │
│ Layer/Key    │   reports      │ Floating HUD │
│ Events       │                │ Display      │
└──────────────┘                └──────────────┘
```

1. The firmware module hooks into ZMK's event system
2. Layer changes and key presses are sent as 32-byte HID reports
3. The macOS app receives these reports and updates the display
4. Your keymap files provide the layout and styling information

## Development

### Building the App

```bash
cd app
swift build
swift run
```

### Running Tests

```bash
cd app
swift test
```

### Project Structure

```
zmk-hud/
├── app/                    # macOS SwiftUI application
│   ├── Sources/
│   │   ├── App/           # App lifecycle, state management
│   │   ├── HID/           # USB HID communication
│   │   ├── Layout/        # QMK JSON parsing, layout generation
│   │   ├── Keymap/        # ZMK keymap parsing
│   │   └── Views/         # SwiftUI views
│   └── Tests/             # Unit tests (136 tests)
├── firmware/              # ZMK module
│   ├── src/               # hud_broadcaster.c
│   ├── Kconfig            # Configuration options
│   └── CMakeLists.txt     # Build configuration
└── docs/                  # Documentation assets
```

## License

MIT License — see [LICENSE](LICENSE)

## Credits

- [zmk-raw-hid](https://github.com/zzeneg/zmk-raw-hid) — Raw HID transport for ZMK
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) — Visual style reference
- [urob/zmk-config](https://github.com/urob/zmk-config) — Keymap inspiration
