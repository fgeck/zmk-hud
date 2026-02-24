# ZMK Layer HUD for macOS

> A native macOS app that displays a semi-transparent floating HUD showing your keyboard's active layer with real-time key highlighting and combo reference panel.

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Keyboard** | Anywhy Flake M (46-key split, xiao_ble, Bluetooth/USB) |
| **Layers** | Base, Num, Nav, Fn, Idea |
| **Target Platform** | macOS 13.0+ |
| **Tech Stack** | Swift/SwiftUI + IOKit (app), C/Zephyr (firmware) |
| **Distribution** | Homebrew cask |

## Key Behaviors

1. **HUD appears** when switching to non-Base layer (Num, Nav, Fn, Idea)
2. **HUD hides** when returning to Base layer  
3. **Home row mods** highlight the key + show modifier indicator (⌘⌥⌃⇧), but don't trigger HUD
4. **Combo panel** always visible alongside keyboard when HUD is shown
5. **Pressed keys** highlight on keyboard, corresponding combo row highlights in panel
6. **Position** configurable (any corner), panel side configurable (left/right)
7. **Testing mode** via keyboard shortcuts (Fn+1/2/3/4/5) to simulate layer changes without firmware

## Design Philosophy: Reuse keymap-drawer

Instead of rebuilding keymap visualization from scratch, this project **reuses keymap-drawer's approach**:

1. **Same config format** — Uses your existing `keymap_drawer.config.yaml` from zmk-config
2. **Same layout algorithm** — Ports keymap-drawer's physical layout calculation to Swift
3. **Same visual style** — Colors, key sizes, and styling match keymap-drawer output
4. **Native rendering** — SwiftUI Canvas for smooth real-time updates (not SVG embedding)

### Why This Approach?

- You already have a working `keymap_drawer.config.yaml` with all your custom bindings mapped
- keymap-drawer's layout algorithm handles rotated keys, split gaps, and thumb clusters correctly
- Native SwiftUI rendering enables smooth key highlighting animations
- Single source of truth for keymap visualization (your config file)

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        macOS App (SwiftUI)                           │
├──────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐   │
│  │ Config Loader   │  │ Layout Engine    │  │ SwiftUI Views      │   │
│  │ (YAML parser)   │  │ (ported from     │  │ - HUDWindow        │   │
│  │                 │  │  keymap-drawer)  │  │ - KeyboardCanvas   │   │
│  │ Reads:          │  │                  │  │ - ComboPanel       │   │
│  │ keymap_drawer   │  │ Calculates:      │  │ - KeyView          │   │
│  │ .config.yaml    │→ │ PhysicalKey[]    │→ │ - SettingsView     │   │
│  └─────────────────┘  └──────────────────┘  └────────────────────┘   │
│         ↑                                            ↑               │
│         │                                            │               │
│  ┌──────┴────────────────────────────────────────────┴────────────┐  │
│  │ AppState (ObservableObject)                                     │  │
│  │ - currentLayer: Int                                             │  │
│  │ - pressedKeys: Set<Int>                                         │  │
│  │ - modifiers: ModifierFlags                                      │  │
│  │ - hudVisible: Bool                                              │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│         ↑                           ↑                                 │
│         │                           │                                 │
│  ┌──────┴──────────┐         ┌──────┴──────────┐                     │
│  │ HID Manager     │         │ Keyboard        │                     │
│  │ (IOKit)         │         │ Shortcuts       │                     │
│  │ - Real device   │         │ - Fn+1/2/3/4/5  │                     │
│  │ - Layer/key HID │         │ - Testing mode  │                     │
│  └─────────────────┘         └─────────────────┘                     │
└──────────────────────────────────────────────────────────────────────┘
         ↑
         │ HID Reports (USB/BLE)
┌────────┴─────────────────────────────────────────────────────────────┐
│                     ZMK Firmware Module                               │
├──────────────────────────────────────────────────────────────────────┤
│  Based on: github.com/maatthc/zmk-feature-appcompanion               │
│  Extended with key position reporting                                 │
│                                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐   │
│  │ Layer State │→ │ HUD Module  │→ │ HID Reports                 │   │
│  │ Key Events  │  │ (listener)  │  │ - Layer changes             │   │
│  └─────────────┘  └─────────────┘  │ - Key positions (future)    │   │
│                                     └─────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

## HUD Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────┐  ┌───────────────────────────┐ │
│  │      [Keyboard HUD]             │  │ COMBOS                    │ │
│  │                                 │  │ ─────────────────────────│ │
│  │   ┌───┐ ┌───┐ ┌───┐ ┌───┐      │  │ LEFT HAND                 │ │
│  │   │ Q │ │ W │ │ E │ │ R │ ...  │  │ Q─A  !    A─Z  `          │ │
│  │   └───┘ └───┘ └───┘ └───┘      │  │ W─S  @    S─X  \          │ │
│  │   ┌───┐ ┌───┐ ┌───┐ ┌───┐      │  │ E─D  #    D─C  =          │ │
│  │   │ A │ │ S │ │ D │ │ F │ ...  │  │ R─F  $    F─V  ~          │ │
│  │   └───┘ └───┘ └───┘ └───┘      │  │ T─G  %                    │ │
│  │                                 │  │ ─────────────────────────│ │
│  │      [thumb arc cluster]        │  │ RIGHT HAND                │ │
│  │                                 │  │ Y─H  ^    H─N  _          │ │
│  └─────────────────────────────────┘  │ U─J  +    J─M  -          │ │
│                                       │ I─K  *    K─,  /          │ │
│                                       │ O─L  &    L─.  |          │ │
│                                       │ ─────────────────────────│ │
│                                       │ SPECIAL                   │ │
│                                       │ S─D─F  ⏎   J─K─L  ⏎       │ │
│                                       │ /─]    Esc                │ │
│                                       └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Config Integration

The app reads your existing `keymap_drawer.config.yaml` from zmk-config:

### draw_config (used directly)
```yaml
draw_config:
  key_h: 56                    # Key height in pixels
  key_w: 56                    # Key width in pixels  
  combo_h: 20                  # Combo box height
  combo_w: 26                  # Combo box width
  inner_pad_w: 2               # Padding between keys
  inner_pad_h: 2
  dark_mode: auto              # Follow system appearance
  svg_extra_style: |           # Color definitions extracted
    .keypos-13 rect { fill: #cfe2f3; }  # Home row mods
    # ... etc
```

### parse_config (used for legends)
```yaml
parse_config:
  raw_binding_map:
    "&nav_left LG(LEFT) LEFT": { t: "←", h: "⌘←" }
    "&hml_td_a LGUI 0": { t: a, h: "⌘", s: ä }
    # ... your custom mappings
  zmk_keycode_map:
    BSPC: "⌫"
    # ... standard keycodes
```

## Physical Layout Format

Uses QMK-compatible JSON format (same as keymap-drawer):

```json
[
  {"x": 0, "y": 0.38, "r": 10, "rx": 1, "ry": 4.18},
  {"x": 1, "y": 0.13, "r": 10, "rx": 1, "ry": 4.18},
  // ... 46 keys total for Anywhy Flake M
]
```

Each key defines:
- `x, y` — Top-left corner in key units (1u = 1 key width)
- `w, h` — Width/height in key units (default: 1)
- `r` — Rotation in degrees (clockwise positive)
- `rx, ry` — Rotation origin (defaults to x, y)

## HID Protocol

### Layer Reports (from zmk-feature-appcompanion)

**BLE HID Embedded** (works over USB + Bluetooth):
- Byte 0: Modifiers
- **Byte 1: Layer number** (uses reserved byte)
- Bytes 2+: Key codes

**USB HID Raw** (32 bytes, USB only):
- Bytes 0-23: Reserved (0x00)
- Byte 24: Marker (0x90)
- Byte 25: Layer number
- Bytes 26-31: Reserved (0x00)

### Future: Key Position Reports
```
Byte 0: Message type (0x02 = key press)
Byte 1: Key position (0-45)
Byte 2: Is pressed (0/1)
Byte 3: Modifier flags
Bytes 4-31: Reserved
```

## References

- **keymap-drawer**: https://github.com/caksoylar/keymap-drawer (layout algorithm, config format)
- **zmk-feature-appcompanion**: https://github.com/maatthc/zmk-feature-appcompanion (firmware reference)
- **zmk-raw-hid**: https://github.com/zzeneg/zmk-raw-hid (HID transport)
- **ZMK docs**: https://zmk.dev/docs

## Repository Structure

```
zmk-hud/
├── README.md
├── LICENSE
├── PROJECT.md                    # This file
├── TASKS.md                      # Implementation tasks
│
├── firmware/                     # ZMK module (imported via west)
│   ├── CMakeLists.txt
│   ├── Kconfig
│   ├── zephyr/module.yml
│   └── src/
│       ├── layer_status_usb_hid.c    # USB raw HID reports
│       └── layer_status_ble_hid.c    # BLE embedded reports
│
├── app/                          # macOS application
│   ├── Package.swift
│   └── Sources/
│       └── ZMKHud/
│           ├── App/
│           │   ├── ZMKHudApp.swift
│           │   └── AppState.swift
│           ├── Config/
│           │   ├── ConfigLoader.swift      # YAML parser
│           │   └── DrawConfig.swift        # Config models
│           ├── Layout/
│           │   ├── PhysicalLayout.swift    # Ported from keymap-drawer
│           │   ├── PhysicalKey.swift
│           │   └── Point.swift
│           ├── HID/
│           │   ├── HIDManager.swift
│           │   └── HIDReport.swift
│           ├── Views/
│           │   ├── HUDWindow.swift
│           │   ├── KeyboardCanvas.swift    # SwiftUI Canvas rendering
│           │   ├── KeyView.swift
│           │   ├── ComboPanel.swift
│           │   └── SettingsView.swift
│           └── Testing/
│               └── KeyboardShortcuts.swift # Fn+1/2/3/4/5 testing
│
└── homebrew/
    └── zmk-hud.rb
```

## Integration with zmk-config

Add to your `zmk-config/config/west.yml`:

```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: fgeck
      url-base: https://github.com/fgeck
    - name: maatthc
      url-base: https://github.com/maatthc
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: main
      import: app/west.yml
    - name: zmk-hud
      remote: fgeck
      revision: main
    - name: zmk-feature-appcompanion
      remote: maatthc
      revision: main
  self:
    path: config
```

Enable in `zmk-config/config/anywhy_flake.conf`:

```
# For USB HID raw reports
CONFIG_USB_HID_DEVICE_COUNT=2
CONFIG_ZMK_LAYER_STATUS_USB_HID=y

# OR for BLE embedded reports (works over both USB and BLE)
CONFIG_ZMK_LAYER_STATUS_BLE_HID=y
```

## Development Workflow

### Testing Without Firmware

Use keyboard shortcuts to simulate layer changes:

| Shortcut | Action |
|----------|--------|
| Fn+1 | Switch to Base layer (hides HUD) |
| Fn+2 | Switch to Num layer |
| Fn+3 | Switch to Nav layer |
| Fn+4 | Switch to Fn layer |
| Fn+5 | Switch to Idea layer |

This allows developing and testing the app UI without needing the actual keyboard connected.

### Building the App

```bash
cd app
swift build
swift run
```

### Building Firmware

```bash
# In your zmk-config repo
west update
west build -b seeeduino_xiao_ble -- -DSHIELD=anywhy_flake_left
```
