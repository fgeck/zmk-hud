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

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        macOS App                                  │
├──────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐   │
│  │ HID Reader  │  │ Keymap      │  │ SwiftUI Views           │   │
│  │ (IOKit)     │→ │ Parser      │→ │ - FloatingPanel         │   │
│  │             │  │ (.keymap)   │  │ - KeyboardView          │   │
│  └─────────────┘  └─────────────┘  │ - ComboReferencePanel   │   │
│        ↑                           │ - KeyView               │   │
│        │                           │ - SettingsView          │   │
│   HID Reports                      └─────────────────────────┘   │
│   (layer, keys, modifiers)                                       │
└──────────────────────────────────────────────────────────────────┘
        ↑
        │ Custom HID (USB/BLE)
┌───────┴──────────────────────────────────────────────────────────┐
│                     ZMK Firmware                                  │
├──────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐   │
│  │ Layer State │→ │ HUD Module  │→ │ Raw HID                 │   │
│  │ Events      │  │ (listener)  │  │ (zmk-raw-hid)           │   │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
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

## References

- **zmk-raw-hid**: https://github.com/zzeneg/zmk-raw-hid
- **ZMK-keymap-viewer**: https://github.com/Intersebbtor/ZMK-keymap-viewer
- **keymap-drawer**: https://github.com/caksoylar/keymap-drawer
- **ZMK docs**: https://zmk.dev/docs

## Repository Structure

The project lives in a **dedicated repository**: `github.com/fgeck/zmk-hud`

```
zmk-hud/                          # NEW DEDICATED REPO
├── README.md
├── LICENSE
│
├── firmware/                     # ZMK module (imported via west)
│   ├── CMakeLists.txt
│   ├── Kconfig
│   ├── zephyr/module.yml         # Makes it a Zephyr module
│   └── src/
│       └── hud_broadcaster.c     # Layer/key state broadcaster
│
├── app/                          # macOS application
│   ├── Package.swift
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── ZMKHUDApp.swift
│   │   │   └── AppState.swift
│   │   ├── HID/
│   │   │   ├── HIDManager.swift
│   │   │   └── HIDReport.swift
│   │   ├── Parser/
│   │   │   ├── KeymapParser.swift
│   │   │   └── Models.swift
│   │   └── Views/
│   │       ├── HUDWindow.swift
│   │       ├── KeyboardView.swift
│   │       ├── ComboPanel.swift
│   │       └── SettingsView.swift
│   └── Tests/
│
└── homebrew/
    └── zmk-hud.rb                # Cask formula
```

## Integration with zmk-config

Once zmk-hud is built, add it to your `zmk-config/config/west.yml`:

```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: fgeck
      url-base: https://github.com/fgeck
    - name: zzeneg
      url-base: https://github.com/zzeneg
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: main
      import: app/west.yml
    - name: zmk-hud
      remote: fgeck
      revision: main
    - name: zmk-raw-hid
      remote: zzeneg
      revision: main
  self:
    path: config
```

Then enable in `zmk-config/config/anywhy_flake.conf`:

```
CONFIG_RAW_HID=y
CONFIG_ZMK_HUD=y
```
