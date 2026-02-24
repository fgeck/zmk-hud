# ZMK HUD Firmware Module

A ZMK module that broadcasts layer state and key press events via Raw HID reports for consumption by the ZMK HUD macOS app.

## Quick Start

Add these modules to your ZMK config and enable them. The HUD app will then receive live layer and key events from your keyboard.

## Installation

### Step 1: Update `config/west.yml`

Add the `fgeck` and `zzeneg` remotes, then add `zmk-hud` and `zmk-raw-hid` to projects.

**Before:**
```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    # ... your other remotes
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: main
      import: app/west.yml
    # ... your other projects
  self:
    path: config
```

**After:**
```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: fgeck                              # <-- ADD
      url-base: https://github.com/fgeck
    - name: zzeneg                             # <-- ADD
      url-base: https://github.com/zzeneg
    # ... your other remotes
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: main
      import: app/west.yml
    - name: zmk-hud                            # <-- ADD
      remote: fgeck
      revision: main
    - name: zmk-raw-hid                        # <-- ADD
      remote: zzeneg
      revision: main
    # ... your other projects
  self:
    path: config
```

### Step 2: Update `build.yaml`

Add `raw_hid_adapter` as an additional shield to your build configuration.

**Before:**
```yaml
include:
  - board: nice_nano_v2
    shield: corne_left
  - board: nice_nano_v2
    shield: corne_right
```

**After:**
```yaml
include:
  - board: nice_nano_v2
    shield: corne_left raw_hid_adapter         # <-- ADD raw_hid_adapter
  - board: nice_nano_v2
    shield: corne_right
```

> **Note:** Only add `raw_hid_adapter` to the **central side** (the side that connects to USB). For most split keyboards, this is the left side.

### Step 3: Enable in your `.conf` file

Add to your **central side's** `.conf` file (e.g., `corne_left.conf`):

```ini
# Enable Raw HID communication
CONFIG_RAW_HID=y

# Enable HUD broadcaster
CONFIG_ZMK_HUD=y
```

### Step 4: Build and Flash

```bash
# Update dependencies
west update

# Build (using GitHub Actions or locally)
west build -b nice_nano_v2 -- -DSHIELD="corne_left raw_hid_adapter"

# Flash
west flash
```

## Example: Anywhy Flake M Configuration

Here's a complete example for the Anywhy Flake M keyboard:

**`config/west.yml`:**
```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: fgeck
      url-base: https://github.com/fgeck
    - name: zzeneg
      url-base: https://github.com/zzeneg
    - name: anywhy-io
      url-base: https://github.com/anywhy-io
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
    - name: flake-zmk-module
      remote: anywhy-io
      revision: main
      path: modules/flake-zmk-module
  self:
    path: config
```

**`build.yaml`:**
```yaml
include:
  - board: nice_nano_v2
    shield: flake_left raw_hid_adapter
  - board: nice_nano_v2
    shield: flake_right
```

**`config/flake_left.conf`:**
```ini
# Raw HID for ZMK HUD
CONFIG_RAW_HID=y
CONFIG_ZMK_HUD=y

# ... your other config options
```

## Split Keyboard Notes

| Side | Shield Suffix | Config Required |
|------|---------------|-----------------|
| Central (USB) | `raw_hid_adapter` | `CONFIG_RAW_HID=y` and `CONFIG_ZMK_HUD=y` |
| Peripheral | (none) | (none) |

- The **central side** is typically the side that connects to your computer via USB
- Key presses from the peripheral side are automatically forwarded by ZMK
- Only the central side needs the HUD configuration

## HID Protocol Specification

The module sends 32-byte Raw HID reports:

### Layer Change (0x01)

| Byte | Field | Description |
|------|-------|-------------|
| 0 | Type | `0x01` |
| 1 | Layer | Layer index (0-31) |
| 2 | Active | `1` = on, `0` = off |
| 3-4 | State | 16-bit layer state bitmask (little-endian) |
| 5-31 | Reserved | `0x00` |

### Key Event (0x02)

| Byte | Field | Description |
|------|-------|-------------|
| 0 | Type | `0x02` |
| 1 | Keycode | HID keycode (0-255) |
| 2 | Pressed | `1` = pressed, `0` = released |
| 3 | Mods | Modifier flags: Ctrl=0x01, Shift=0x02, Alt=0x04, Gui=0x08 |
| 4-31 | Reserved | `0x00` |

## Troubleshooting

### Build errors: "raw_hid" not found

Ensure you've added `zmk-raw-hid` to your `west.yml` projects and run `west update`.

### No HID events received in app

1. **USB only**: Raw HID requires USB connection, not Bluetooth
2. **Check shield**: Verify `raw_hid_adapter` is in your build.yaml
3. **Check config**: Verify both `CONFIG_RAW_HID=y` and `CONFIG_ZMK_HUD=y` are set
4. **Central side only**: Only the USB-connected side should have these settings

### Enable debug logging

Add to your `.conf`:
```ini
CONFIG_ZMK_LOG_LEVEL_DBG=y
CONFIG_LOG=y
```

Monitor serial output for:
```
HUD: Layer 1 activated (state: 0x0003)
HUD: Key 0x04 pressed (mods: 0x00)
```

## Dependencies

- [zmk-raw-hid](https://github.com/zzeneg/zmk-raw-hid) - Raw HID transport layer for ZMK

## License

MIT License
