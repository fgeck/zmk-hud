# ZMK HUD - Task Breakdown

> This file tracks all tasks for the ZMK Layer HUD project. Tasks are designed for parallel execution where dependencies allow.

## Status Legend

- `[ ]` Not started
- `[~]` In progress  
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

---

## Phase 1: Firmware Module (Week 1)

> **Goal**: ZMK sends layer/key state to host via custom HID reports

### 1.0 Create zmk-hud Repository
**Dependencies**: None | **Parallel**: No (do first)

- [ ] **1.0.1** Create GitHub repo `fgeck/zmk-hud`
  - Initialize with README, LICENSE (MIT)
  **Validation**: Repo exists at github.com/fgeck/zmk-hud

- [ ] **1.0.2** Create directory structure
  ```
  firmware/
  app/
  homebrew/
  ```
  **Validation**: Directories created and pushed

### 1.1 Setup zmk-raw-hid Dependency
**Dependencies**: 1.0 | **Parallel**: Yes (with 1.2)

- [ ] **1.1.1** Add zmk-raw-hid to `zmk-config/config/west.yml`
  ```yaml
  # Add to remotes:
  - name: zzeneg
    url-base: https://github.com/zzeneg
  # Add to projects:
  - name: zmk-raw-hid
    remote: zzeneg
    revision: main
  ```
  **Validation**: `west update` succeeds
- [ ] **1.1.2** Enable raw HID in Kconfig (`zmk-config/config/anywhy_flake.conf`)
  ```
  CONFIG_RAW_HID=y
  CONFIG_RAW_HID_REPORT_SIZE=32
  ```
  **Validation**: Firmware builds with raw HID enabled

### 1.2 Create HUD Firmware Module (in zmk-hud repo)
**Dependencies**: 1.0 | **Parallel**: Yes (with 1.1)

- [ ] **1.2.1** Create `firmware/zephyr/module.yml`
  ```yaml
  build:
    cmake: .
    kconfig: Kconfig
  ```
  **Validation**: File structure matches Zephyr module requirements

- [ ] **1.2.2** Create `firmware/CMakeLists.txt`
  ```cmake
  if(CONFIG_ZMK_HUD)
    target_sources(app PRIVATE src/hud_broadcaster.c)
  endif()
  ```

- [ ] **1.2.3** Create `firmware/Kconfig`
  ```
  config ZMK_HUD
      bool "ZMK HUD Broadcaster"
      default y
      depends on RAW_HID
      help
        Broadcasts layer and key state via Raw HID for desktop HUD apps
  ```

- [ ] **1.2.4** Create `firmware/src/hud_broadcaster.c` - Layer listener
  ```c
  // Subscribe to zmk_layer_state_changed
  // Send HID report: [MSG_TYPE=0x01, layer_index, is_active]
  ```
  **Validation**: C code compiles without errors
- [ ] **1.2.5** Add key press listener to `hud_broadcaster.c`
  ```c
  // Subscribe to zmk_keycode_state_changed  
  // Send HID report: [MSG_TYPE=0x02, key_position, is_pressed, modifiers]
  ```

### 1.3 Integration & Testing
**Dependencies**: 1.1, 1.2 | **Parallel**: No
- [ ] **1.3.1** Add zmk-hud module to `zmk-config/config/west.yml`
  ```yaml
  - name: zmk-hud
    remote: fgeck
    revision: main
  ```

- [ ] **1.3.2** Enable in `zmk-config/config/anywhy_flake.conf`
  ```
  CONFIG_ZMK_HUD=y
  ```

- [ ] **1.3.3** Build firmware with HUD module
  **Validation**: `west build` succeeds, firmware size reasonable
- [ ] **1.3.4** Flash left half and test USB HID
  **Validation**: Custom HID device appears in `ioreg -p IOUSB`
- [ ] **1.3.5** Create test script to read HID reports
  ```bash
  # Use hidapi or Python hidapi to read reports
  ```
  **Validation**: Layer changes produce HID reports in console
- [ ] **1.3.6** Test BLE connection
  **Validation**: HID reports received over Bluetooth

---

## Phase 2: macOS App Foundation (Week 2)

> **Goal**: App structure, HID communication, basic floating window

### 2.1 Project Setup
**Dependencies**: None | **Parallel**: Yes (with 2.2)

- [ ] **2.1.1** Create `app/Package.swift` (in zmk-hud repo)
  ```swift
  // swift-tools-version: 5.9
  // Target: macOS 13.0+
  // Dependencies: none initially
  ```
  **Validation**: `swift build` succeeds

- [ ] **2.1.2** Create `ZMKHUDApp.swift` - App entry point
  - Menubar icon (NSStatusItem)
  - No dock icon (LSUIElement)
  **Validation**: App runs with menubar icon visible

- [ ] **2.1.3** Create `AppState.swift` - ObservableObject
  - Properties: currentLayer, pressedKeys, modifiers, hudVisible
  **Validation**: State updates trigger UI refresh

### 2.2 HID Communication Layer
**Dependencies**: None | **Parallel**: Yes (with 2.1)

- [ ] **2.2.1** Create `HIDManager.swift` - IOKit integration
  - Find device by VID/PID + usage page (0xFF60)
  - Open device, start read loop
  **Validation**: Device discovery logged to console

- [ ] **2.2.2** Create `HIDReport.swift` - Report parsing
  ```swift
  struct HIDReport {
      enum MessageType: UInt8 {
          case layerChange = 0x01
          case keyPress = 0x02
      }
      // Parse 32-byte reports
  }
  ```
  **Validation**: Reports parsed into structured data

- [ ] **2.2.3** Connect HID events to AppState
  **Validation**: AppState updates when keyboard sends reports

### 2.3 Floating Panel
**Dependencies**: 2.1 | **Parallel**: Yes (with 2.2)

- [ ] **2.3.1** Create `HUDWindow.swift` - NSPanel wrapper
  - Level: .floating
  - Style: .hudWindow, .nonactivatingPanel
  - No title bar, transparent background
  **Validation**: Window floats above all apps

- [ ] **2.3.2** Implement show/hide logic
  - Show when layer != Base
  - Hide when layer == Base
  **Validation**: Window appears/disappears on layer change

- [ ] **2.3.3** Add position persistence (UserDefaults)
  **Validation**: Position saved across app restarts

---

## Phase 3: Keymap Parser (Week 3, Days 1-4)

> **Goal**: Parse .keymap files into structured data

### 3.1 Parser Core
**Dependencies**: 2.1 | **Parallel**: Yes

- [ ] **3.1.1** Create `Models.swift` - Data structures
  ```swift
  struct Keymap { layers: [Layer], combos: [Combo], behaviors: [Behavior] }
  struct Layer { name: String, bindings: [Binding] }
  struct Binding { type: BindingType, params: [String] }
  struct Combo { positions: [Int], result: Binding, layers: [Int]? }
  ```

- [ ] **3.1.2** Create `KeymapParser.swift` - Main parser
  - Remove comments (// and /* */)
  - Find keymap {} section
  - Extract layer blocks
  **Validation**: Finds all 5 layers in anywhy_flake.keymap

- [ ] **3.1.3** Implement binding parser
  - Parse: &kp, &lt, &mo, &mt, &trans, &none
  - Parse custom behaviors: &hml, &hmr, &td_*, &nav_*
  **Validation**: All bindings in Base layer parsed correctly

- [ ] **3.1.4** Implement combo parser
  - Extract combo blocks
  - Parse key-positions, bindings, layers
  **Validation**: All 18+ combos extracted with correct positions

### 3.2 File Loading
**Dependencies**: 3.1 | **Parallel**: No

- [ ] **3.2.1** Implement local file picker
  - NSOpenPanel for .keymap files
  - Store path in UserDefaults
  **Validation**: File picker opens, selection persisted

- [ ] **3.2.2** Implement GitHub URL loading
  - Fetch raw file from GitHub
  - Handle authentication for private repos (optional)
  **Validation**: Can load from https://raw.githubusercontent.com/...

- [ ] **3.2.3** Implement file watcher (local files)
  - DispatchSource file monitoring
  - Auto-reload on changes
  **Validation**: Editing keymap triggers reload

---

## Phase 4: Visual Rendering (Week 3, Days 5-7 + Week 4, Days 1-3)

> **Goal**: SwiftUI keyboard visualization with arc thumb clusters

### 4.1 Layout Engine
**Dependencies**: 3.1 | **Parallel**: Yes

- [ ] **4.1.1** Create `KeyboardLayout.swift` - Position calculator
  - 46 key positions for Anywhy Flake M
  - Split layout (left/right halves with gap)
  **Validation**: Key positions match physical layout

- [ ] **4.1.2** Implement thumb cluster arc
  - Positions 36-40 (left) and 41-45 (right)
  - Rotation: 15°, 30° for arc effect
  **Validation**: Thumbs render with curved arrangement

### 4.2 Key Rendering
**Dependencies**: 4.1 | **Parallel**: Yes (with 4.3)

- [ ] **4.2.1** Create `KeyView.swift` - Single key view
  - Tap label (center)
  - Hold label (bottom)
  - Shifted label (top)
  **Validation**: Key displays all label types

- [ ] **4.2.2** Implement color coding
  - Blue: Home row mods (#cfe2f3)
  - Purple: Tap-dance (#7b1fa2)
  - Teal: Hold behaviors (#00838f)
  - Green: Layer activators (#d9ead3)
  **Validation**: Colors match SVG reference

- [ ] **4.2.3** Implement key highlighting
  - Pressed state: background color change
  - Modifier active: indicator badge
  **Validation**: Keys highlight when pressed

### 4.3 Combo Reference Panel
**Dependencies**: 3.1.4 | **Parallel**: Yes (with 4.2)

- [ ] **4.3.1** Create `ComboPanel.swift` - Panel view
  - Grouped by hand (Left/Right)
  - Sub-grouped by row pair (Top+Home, Home+Bottom)
  - Special section for horizontal combos
  **Validation**: All combos displayed in organized groups

- [ ] **4.3.2** Implement visual connectors
  - Format: "Q─A  !" with em-dash connecting keys
  **Validation**: Connector notation renders correctly

- [ ] **4.3.3** Implement combo highlighting
  - When combo keys pressed, highlight row
  - Show result symbol prominently
  **Validation**: Active combos visually highlighted

### 4.4 Keyboard View Integration
**Dependencies**: 4.1, 4.2, 4.3 | **Parallel**: No

- [ ] **4.4.1** Create `KeyboardView.swift` - Main view
  - Compose KeyViews into full layout
  - Add ComboPanel on configurable side
  **Validation**: Full keyboard + panel renders

- [ ] **4.4.2** Implement layer switching
  - Update displayed bindings when layer changes
  - Animate transition (optional)
  **Validation**: Layer changes update all key labels

---

## Phase 5: Polish & Distribution (Week 4, Days 4-7)

> **Goal**: Settings, dark mode, Homebrew distribution

### 5.1 Settings UI
**Dependencies**: 4.4 | **Parallel**: Yes

- [ ] **5.1.1** Create `SettingsView.swift`
  - Position picker (4 corners + custom)
  - Combo panel side (left/right)
  - Opacity slider
  - Scale slider
  **Validation**: All settings functional

- [ ] **5.1.2** Implement menubar menu
  - Show/Hide HUD
  - Settings...
  - Reload Keymap
  - Quit
  **Validation**: Menu items functional

### 5.2 Visual Polish
**Dependencies**: 4.4 | **Parallel**: Yes (with 5.1)

- [ ] **5.2.1** Implement dark mode support
  - Detect system appearance
  - Switch color palette accordingly
  **Validation**: Correct colors in light/dark mode

- [ ] **5.2.2** Add material blur background
  - NSVisualEffectView with .hudWindow material
  **Validation**: Background has system blur effect

- [ ] **5.2.3** Add fade animation
  - Smooth show/hide transitions
  **Validation**: HUD animates in/out

### 5.3 Distribution
**Dependencies**: 5.1, 5.2 | **Parallel**: No

- [ ] **5.3.1** Create app icon
  - 1024x1024 source
  - All required sizes for macOS
  **Validation**: Icon appears in menubar and About

- [ ] **5.3.2** Configure code signing (optional)
  - Developer ID or ad-hoc
  **Validation**: App runs without Gatekeeper warning

- [ ] **5.3.3** Create Homebrew cask formula
  ```ruby
  cask "zmk-hud" do
    version "1.0.0"
    sha256 "..."
    url "https://github.com/.../releases/download/..."
    name "ZMK HUD"
    homepage "https://github.com/..."
    app "ZMK HUD.app"
  end
  ```
  **Validation**: `brew install --cask zmk-hud` works

- [ ] **5.3.4** Create GitHub release
  - Build universal binary (arm64 + x86_64)
  - Create .dmg or .zip
  - Upload to releases
  **Validation**: Release downloadable and installable

---

## Parallel Execution Map
```
Week 1:
  [1.0 Create Repo] ──> [1.1 Setup raw-hid] ──┬──> [1.3 Integration]
  [1.2 HUD Module]    ──┘
  [2.1 Project Setup] ──┬──> [2.3 Floating Panel]
  [2.2 HID Comms]     ──┴──> (connects to AppState)
  [3.1 Parser Core] ──> [3.2 File Loading]
  [4.1 Layout Engine] ──┬──> [4.4 Integration]
  [4.2 Key Rendering] ──┤
  [4.3 Combo Panel]   ──┘
  [5.1 Settings] ──┬──> [5.3 Distribution]
  [5.2 Polish]   ──┘
```

## Repository Map

```
github.com/fgeck/zmk-hud       # NEW - Firmware module + macOS app
  └── firmware/                # Imported via west into zmk-config
  └── app/                     # Standalone macOS app

github.com/fgeck/zmk-config    # EXISTING - Your keyboard config
  └── config/west.yml          # Add zmk-hud + zmk-raw-hid as modules
  └── config/anywhy_flake.conf # Enable CONFIG_ZMK_HUD=y
```

---

## Quick Reference

### HID Report Format

```
Layer Change (32 bytes):
  [0] = 0x01 (message type)
  [1] = layer_index (0-4)
  [2] = is_active (0/1)
  [3-31] = reserved

Key Press (32 bytes):
  [0] = 0x02 (message type)
  [1] = key_position (0-45)
  [2] = is_pressed (0/1)
  [3] = modifier_flags (bit flags for ctrl/shift/alt/gui)
  [4-31] = reserved
```

### Key Positions (Anywhy Flake M)

```
Left Half:                    Right Half:
12 13 14 15 16 17            18 19 20 21 22 23
24 25 26 27 28 29            30 31 32 33 34 35
   36 37 38 39 40            41 42 43 44 45
   (thumbs arc)              (thumbs arc)
```

### Color Palette

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Home Row Mods | #cfe2f3 | #1a3a5c |
| Tap-Dance | #7b1fa2 | #ce93d8 |
| Hold | #00838f | #4dd0e1 |
| Layer Activator | #d9ead3 | #274e13 |
| Combo | #fff2cc | #7f6000 |
| Pressed/Held | #e6b8af | #5b3a3a |

---

## Notes

- All firmware work requires rebuilding and reflashing
- macOS app can be developed on any Mac without hardware
- Parser can be tested with local keymap copy
- HID communication requires actual keyboard connected
