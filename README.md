# ZMK HUD

A macOS app that displays a semi-transparent floating HUD showing your ZMK keyboard's active layer with real-time key highlighting and combo reference panel.

![HUD Preview](docs/preview.png) <!-- TODO: Add screenshot -->

## Features

- 🎯 **Automatic layer detection** - HUD appears when you switch layers
- ⌨️ **Real-time key highlighting** - See which keys are pressed
- 🔗 **Combo reference panel** - Quick lookup for your vertical combos
- 🎨 **Matches your keymap style** - Colors match keymap-drawer output
- 🌙 **Dark mode support** - Follows system appearance
- 📍 **Configurable position** - Place HUD in any corner

## Components

### Firmware Module (`/firmware`)

A ZMK module that broadcasts layer and key state via custom HID reports.

**Installation**: Add to your `west.yml`:

```yaml
manifest:
  remotes:
    - name: fgeck
      url-base: https://github.com/fgeck
    - name: zzeneg
      url-base: https://github.com/zzeneg
  projects:
    - name: zmk-hud
      remote: fgeck
      revision: main
    - name: zmk-raw-hid
      remote: zzeneg
      revision: main
```

Enable in your `.conf`:

```
CONFIG_RAW_HID=y
CONFIG_ZMK_HUD=y
```

### macOS App (`/app`)

Native SwiftUI application that reads HID reports and displays the HUD.

**Installation**:

```bash
brew install --cask zmk-hud
```

Or download from [Releases](../../releases).

## Requirements

- **Firmware**: ZMK with zmk-raw-hid module
- **App**: macOS 13.0+
- **Connection**: USB or Bluetooth

## Development

See [PROJECT.md](PROJECT.md) for architecture and [TASKS.md](TASKS.md) for implementation status.

### Building the Firmware

```bash
# In your zmk-config repo after adding zmk-hud to west.yml
west update
west build -b <your_board> -- -DSHIELD=<your_shield>
```

### Building the App

```bash
cd app
swift build
swift run
```

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [zmk-raw-hid](https://github.com/zzeneg/zmk-raw-hid) - Raw HID communication for ZMK
- [ZMK-keymap-viewer](https://github.com/Intersebbtor/ZMK-keymap-viewer) - Inspiration for keymap parsing
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) - Visual style reference
