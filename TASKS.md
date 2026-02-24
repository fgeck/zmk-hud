# ZMK HUD - Task Breakdown

> This file tracks all tasks for the ZMK Layer HUD project. Refactored to use keymap-drawer's layout algorithm and config format.

## Status Legend

- `[ ]` Not started
- `[~]` In progress  
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

---

## Phase 1: Swift Layout Engine (Week 1)

> **Goal**: Port keymap-drawer's physical layout algorithm to Swift, reuse existing config

### 1.1 Core Data Structures
**Dependencies**: None | **Parallel**: Yes

- [ ] **1.1.1** Create `Sources/ZMKHud/Layout/Point.swift`
  ```swift
  struct Point {
      var x: Double
      var y: Double
      // Operators: +, -, *, abs, rotate
  }
  ```
  **Validation**: Unit tests pass for point arithmetic

- [ ] **1.1.2** Create `Sources/ZMKHud/Layout/PhysicalKey.swift`
  ```swift
  struct PhysicalKey {
      var pos: Point           // Center position in pixels
      var width: Double
      var height: Double
      var rotation: Double     // Degrees, CW positive
      var boundingWidth: Double
      var boundingHeight: Double
  }
  ```
  **Validation**: Keys with rotation calculate correct bounding box

- [ ] **1.1.3** Create `Sources/ZMKHud/Layout/PhysicalLayout.swift`
  ```swift
  struct PhysicalLayout {
      var keys: [PhysicalKey]
      var width: Double { /* max x + bounding/2 */ }
      var height: Double { /* max y + bounding/2 */ }
      func normalize() -> PhysicalLayout
  }
  ```

### 1.2 QMK Layout Parser
**Dependencies**: 1.1 | **Parallel**: Yes (with 1.3)

- [ ] **1.2.1** Create `Sources/ZMKHud/Layout/QMKLayoutParser.swift`
  - Parse QMK info.json format: `[{x, y, w, h, r, rx, ry}, ...]`
  - Scale from key units to pixels using `key_h` from config
  **Validation**: Parse sample Anywhy Flake layout JSON

- [ ] **1.2.2** Implement `fromQmkSpec()` factory method
  ```swift
  static func fromQmkSpec(
      scale: Double,
      pos: Point,        // top-left corner
      width: Double,
      height: Double,
      rotation: Double,
      rotationPos: Point
  ) -> PhysicalKey
  ```
  - Calculate center from top-left
  - Apply rotation around rotation point
  - Scale to pixels
  **Validation**: Rotated thumb keys position correctly

- [ ] **1.2.3** Implement `rotatePoint()` helper
  ```swift
  static func rotatePoint(origin: Point, point: Point, angle: Double) -> Point
  ```
  - Convert degrees to radians
  - Apply rotation matrix
  **Validation**: 90° rotation produces correct coordinates

### 1.3 Ortho Layout Generator
**Dependencies**: 1.1 | **Parallel**: Yes (with 1.2)

- [ ] **1.3.1** Create `Sources/ZMKHud/Layout/OrthoLayoutGenerator.swift`
  ```swift
  struct OrthoLayoutGenerator {
      var split: Bool
      var rows: Int
      var columns: Int
      var thumbs: Int
      var dropPinky: Bool
      var dropInner: Bool
      
      func generate(keyW: Double, keyH: Double, splitGap: Double) -> PhysicalLayout
  }
  ```
  **Validation**: Generates correct layout for 3x5+3 split

- [ ] **1.3.2** Implement split keyboard gap handling
  - Right half offset by `cols * keyW + splitGap`
  **Validation**: Split gap matches keymap-drawer output

### 1.4 Config Loader
**Dependencies**: None | **Parallel**: Yes (with 1.1-1.3)

- [ ] **1.4.1** Add Yams dependency to `Package.swift`
  ```swift
  .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
  ```
  **Validation**: `swift build` succeeds

- [ ] **1.4.2** Create `Sources/ZMKHud/Config/DrawConfig.swift`
  ```swift
  struct DrawConfig: Codable {
      var keyW: Double = 60
      var keyH: Double = 56
      var splitGap: Double = 30
      var innerPadW: Double = 2
      var innerPadH: Double = 2
      var darkMode: DarkMode = .auto
      var svgExtraStyle: String = ""
      // ... other fields from keymap_drawer.config.yaml
  }
  ```

- [ ] **1.4.3** Create `Sources/ZMKHud/Config/ParseConfig.swift`
  ```swift
  struct ParseConfig: Codable {
      var rawBindingMap: [String: LegendSpec] = [:]
      var zmkKeycodeMap: [String: String] = [:]
      var transLegend: LegendSpec = LegendSpec(t: "▽", type: "trans")
  }
  
  struct LegendSpec: Codable {
      var t: String?       // tap
      var h: String?       // hold
      var s: String?       // shifted
      var type: String?
  }
  ```

- [ ] **1.4.4** Create `Sources/ZMKHud/Config/ConfigLoader.swift`
  ```swift
  class ConfigLoader {
      static func load(from url: URL) throws -> Config
      static func loadDefault() -> Config
  }
  ```
  **Validation**: Successfully loads your keymap_drawer.config.yaml

### 1.5 Color Extraction
**Dependencies**: 1.4 | **Parallel**: No

- [ ] **1.5.1** Create `Sources/ZMKHud/Config/ColorScheme.swift`
  - Parse CSS from `svg_extra_style` field
  - Extract colors for key positions (home row mods, etc.)
  - Support light/dark mode variants
  ```swift
  struct ColorScheme {
      var homeRowMod: Color
      var tapDance: Color
      var hold: Color
      var layerActivator: Color
      var combo: Color
      var pressed: Color
      var trans: Color
      
      static func fromCSS(_ css: String, darkMode: Bool) -> ColorScheme
  }
  ```
  **Validation**: Correct colors extracted for keypos-13 through keypos-22

---

## Phase 2: App Foundation (Week 1-2)

> **Goal**: Basic app structure with testing mode (no firmware required)

### 2.1 Project Structure
**Dependencies**: 1.4 | **Parallel**: No

- [ ] **2.1.1** Update `app/Package.swift`
  ```swift
  // swift-tools-version: 5.9
  import PackageDescription
  let package = Package(
      name: "ZMKHud",
      platforms: [.macOS(.v13)],
      dependencies: [
          .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
      ],
      targets: [
          .executableTarget(
              name: "ZMKHud",
              dependencies: ["Yams"],
              path: "Sources/ZMKHud"
          ),
          .testTarget(
              name: "ZMKHudTests",
              dependencies: ["ZMKHud"],
              path: "Tests"
          ),
      ]
  )
  ```
  **Validation**: `swift build` succeeds

- [ ] **2.1.2** Create `Sources/ZMKHud/App/ZMKHudApp.swift`
  - `@main` entry point
  - MenuBarExtra for menubar icon
  - LSUIElement = true (no dock icon)
  **Validation**: App launches with menubar icon

- [ ] **2.1.3** Create `Sources/ZMKHud/App/AppState.swift`
  ```swift
  @Observable
  class AppState {
      var currentLayer: Int = 0
      var pressedKeys: Set<Int> = []
      var modifiers: ModifierFlags = []
      var hudVisible: Bool = false
      var config: Config
      var layout: PhysicalLayout
  }
  ```
  **Validation**: State changes trigger view updates

### 2.2 Testing Mode (Keyboard Shortcuts)
**Dependencies**: 2.1 | **Parallel**: Yes

- [ ] **2.2.1** Create `Sources/ZMKHud/Testing/KeyboardShortcuts.swift`
  ```swift
  class KeyboardShortcutHandler {
      // Fn+1 = Base (layer 0)
      // Fn+2 = Num (layer 1)
      // Fn+3 = Nav (layer 2)
      // Fn+4 = Fn (layer 3)
      // Fn+5 = Idea (layer 4)
      func setupGlobalShortcuts(appState: AppState)
  }
  ```
  - Use `NSEvent.addGlobalMonitorForEvents` for key monitoring
  **Validation**: Fn+2 shows HUD, Fn+1 hides it

- [ ] **2.2.2** Add testing toggle in menu
  - "Testing Mode" checkbox
  - Shows shortcuts hint when enabled
  **Validation**: Can enable/disable testing mode from menu

### 2.3 Floating HUD Window
**Dependencies**: 2.1 | **Parallel**: Yes (with 2.2)

- [ ] **2.3.1** Create `Sources/ZMKHud/Views/HUDWindow.swift`
  ```swift
  class HUDWindow: NSPanel {
      // .floating level
      // .hudWindow + .nonactivatingPanel style
      // Transparent background
      // No title bar
  }
  ```
  **Validation**: Window floats above all apps, doesn't steal focus

- [ ] **2.3.2** Implement show/hide with animation
  ```swift
  func show(animated: Bool = true)
  func hide(animated: Bool = true)
  ```
  - Fade in/out animation
  - Triggered by layer != 0
  **Validation**: Smooth fade transitions

- [ ] **2.3.3** Add position persistence
  - Save window frame to UserDefaults
  - Restore on launch
  - Support corner snapping (optional)
  **Validation**: Position persists across restarts

---

## Phase 3: Keyboard Rendering (Week 2)

> **Goal**: SwiftUI Canvas rendering of keyboard with key labels

### 3.1 Canvas Renderer
**Dependencies**: 1.2, 2.3 | **Parallel**: Yes

- [ ] **3.1.1** Create `Sources/ZMKHud/Views/KeyboardCanvas.swift`
  ```swift
  struct KeyboardCanvas: View {
      let layout: PhysicalLayout
      let colorScheme: ColorScheme
      @Binding var pressedKeys: Set<Int>
      
      var body: some View {
          Canvas { context, size in
              for (index, key) in layout.keys.enumerated() {
                  drawKey(context: &context, key: key, index: index)
              }
          }
      }
  }
  ```
  **Validation**: All 46 keys render in correct positions

- [ ] **3.1.2** Implement key drawing with rotation
  ```swift
  func drawKey(context: inout GraphicsContext, key: PhysicalKey, index: Int) {
      context.rotate(by: .degrees(key.rotation))
      // Draw rounded rect
      // Draw labels
      context.rotate(by: .degrees(-key.rotation))
  }
  ```
  **Validation**: Thumb keys render with correct rotation

- [ ] **3.1.3** Implement key labels (tap/hold/shifted)
  ```swift
  func drawKeyLabels(context: inout GraphicsContext, key: PhysicalKey, legend: LegendSpec) {
      // Center: tap label
      // Bottom: hold label (smaller)
      // Top: shifted label (smaller)
  }
  ```
  **Validation**: Home row mods show "a" center, "⌘" bottom

### 3.2 Key Highlighting
**Dependencies**: 3.1 | **Parallel**: No

- [ ] **3.2.1** Implement pressed state highlighting
  - Change background color when key in `pressedKeys`
  - Use `pressed` color from ColorScheme
  **Validation**: Key changes color when "pressed" via test mode

- [ ] **3.2.2** Implement position-based coloring
  - Home row mods (positions 13-16, 19-22): blue
  - Layer activators: green
  - Apply colors from ColorScheme based on key position
  **Validation**: Colors match your keymap-drawer SVG output

### 3.3 Layer Display
**Dependencies**: 3.1, 1.4 | **Parallel**: Yes (with 3.2)

- [ ] **3.3.1** Create layer data model
  ```swift
  struct LayerData {
      var name: String
      var bindings: [LegendSpec]  // 46 entries for Anywhy Flake
  }
  ```

- [ ] **3.3.2** Load layer bindings from config
  - Use `rawBindingMap` for custom behaviors
  - Use `zmkKeycodeMap` for standard keycodes
  **Validation**: "&hml_td_a LGUI 0" displays as {t:"a", h:"⌘", s:"ä"}

- [ ] **3.3.3** Implement layer switching
  - Update displayed legends when `currentLayer` changes
  - Animate label changes (optional)
  **Validation**: Switching to Nav layer shows arrow keys

---

## Phase 4: Combo Panel (Week 2-3)

> **Goal**: Reference panel showing vertical combos

### 4.1 Combo Panel View
**Dependencies**: 3.1 | **Parallel**: Yes

- [ ] **4.1.1** Create `Sources/ZMKHud/Views/ComboPanel.swift`
  ```swift
  struct ComboPanel: View {
      let combos: [ComboData]
      @Binding var pressedKeys: Set<Int>
      
      var body: some View {
          VStack(alignment: .leading) {
              Text("COMBOS").font(.headline)
              ComboGroup(title: "LEFT HAND", combos: leftHandCombos)
              ComboGroup(title: "RIGHT HAND", combos: rightHandCombos)
              ComboGroup(title: "SPECIAL", combos: specialCombos)
          }
      }
  }
  ```
  **Validation**: Panel shows grouped combos

- [ ] **4.1.2** Create combo row view
  ```swift
  struct ComboRow: View {
      let combo: ComboData  // positions, result
      let isActive: Bool
      
      var body: some View {
          HStack {
              Text("Q─A")  // Key names joined with em-dash
              Text("!")    // Result
          }
          .background(isActive ? Color.yellow.opacity(0.3) : .clear)
      }
  }
  ```
  **Validation**: Active combos highlight

- [ ] **4.1.3** Implement combo grouping logic
  - Group by hand (left cols 0-5, right cols 6-11)
  - Sub-group by row pair (top+home, home+bottom)
  **Validation**: Combos organized matching HUD layout mockup

### 4.2 Combo Highlighting
**Dependencies**: 4.1 | **Parallel**: No

- [ ] **4.2.1** Detect active combos from pressed keys
  ```swift
  func activeCombo(for pressedKeys: Set<Int>, combos: [ComboData]) -> ComboData? {
      combos.first { Set($0.positions).isSubset(of: pressedKeys) }
  }
  ```
  **Validation**: Pressing Q+A highlights "!" combo row

---

## Phase 5: HID Communication (Week 3)

> **Goal**: Read layer state from keyboard via HID

### 5.1 HID Manager
**Dependencies**: 2.1 | **Parallel**: Yes

- [ ] **5.1.1** Create `Sources/ZMKHud/HID/HIDManager.swift`
  ```swift
  class HIDManager {
      func startMonitoring()
      func stopMonitoring()
      var onLayerChange: ((Int) -> Void)?
      var onKeyPress: ((Int, Bool) -> Void)?
  }
  ```
  - Use IOKit for HID device access
  - Monitor for device connect/disconnect
  **Validation**: Detects keyboard connection

- [ ] **5.1.2** Implement device matching
  - Match by Usage Page 0xFF60 (raw HID)
  - Or by reserved byte in keyboard report (BLE mode)
  **Validation**: Finds Anywhy Flake keyboard

- [ ] **5.1.3** Implement report parsing
  ```swift
  func parseReport(_ data: Data) {
      // USB Raw: byte[24]=0x90, byte[25]=layer
      // BLE Embedded: byte[1]=layer
  }
  ```
  **Validation**: Layer changes from keyboard update app

### 5.2 Integration
**Dependencies**: 5.1, 2.1 | **Parallel**: No

- [ ] **5.2.1** Connect HIDManager to AppState
  - Layer changes update `appState.currentLayer`
  - Key presses update `appState.pressedKeys`
  **Validation**: Real keyboard input reflects in UI

- [ ] **5.2.2** Handle connection state
  - Show indicator when keyboard not connected
  - Fall back to testing mode
  **Validation**: App usable without keyboard connected

---

## Phase 6: Polish & Distribution (Week 4)

> **Goal**: Settings, dark mode, Homebrew

### 6.1 Settings
**Dependencies**: 3.1, 4.1 | **Parallel**: Yes

- [ ] **6.1.1** Create `Sources/ZMKHud/Views/SettingsView.swift`
  - Config file path picker
  - Physical layout JSON picker (or use ortho generator)
  - Position: corner picker (TL, TR, BL, BR)
  - Combo panel side (left/right)
  - Opacity slider
  - Scale slider
  **Validation**: All settings persist and apply

- [ ] **6.1.2** Implement menubar menu
  ```swift
  Menu {
      Toggle("Show HUD", isOn: $appState.hudVisible)
      Divider()
      Button("Settings...") { showSettings() }
      Button("Reload Config") { reloadConfig() }
      Divider()
      Toggle("Testing Mode", isOn: $testingMode)
      Divider()
      Button("Quit") { NSApp.terminate(nil) }
  }
  ```
  **Validation**: All menu items work

### 6.2 Dark Mode
**Dependencies**: 1.5 | **Parallel**: Yes (with 6.1)

- [ ] **6.2.1** Implement system appearance detection
  ```swift
  @Environment(\.colorScheme) var colorScheme
  ```
  - Switch ColorScheme based on system setting
  - Support `dark_mode: auto` from config
  **Validation**: Colors change with system dark mode

- [ ] **6.2.2** Add material blur background
  - Use `NSVisualEffectView` with `.hudWindow` material
  - Wrap in NSViewRepresentable for SwiftUI
  **Validation**: HUD has system-appropriate blur

### 6.3 Distribution
**Dependencies**: All above | **Parallel**: No

- [ ] **6.3.1** Create app icon
  - Keyboard/layer glyph design
  - Export all required sizes
  **Validation**: Icon appears in menubar and About

- [ ] **6.3.2** Configure build for release
  - Archive as universal binary (arm64 + x86_64)
  - Code sign (ad-hoc or Developer ID)
  **Validation**: App runs on both Intel and Apple Silicon

- [ ] **6.3.3** Create `homebrew/zmk-hud.rb`
  ```ruby
  cask "zmk-hud" do
    version "1.0.0"
    sha256 "..."
    url "https://github.com/fgeck/zmk-hud/releases/download/v#{version}/ZMKHud.zip"
    name "ZMK HUD"
    homepage "https://github.com/fgeck/zmk-hud"
    app "ZMK HUD.app"
  end
  ```
  **Validation**: `brew install --cask zmk-hud` works

- [ ] **6.3.4** Create GitHub release
  - Build and zip app
  - Create release with changelog
  **Validation**: Release downloadable and installable

---

## Phase 7: Firmware Module (When App is Ready)

> **Goal**: Extend zmk-feature-appcompanion for this project's needs

### 7.1 Evaluate Reference Implementation
**Dependencies**: None | **Parallel**: Yes

- [ ] **7.1.1** Test zmk-feature-appcompanion with your keyboard
  - Add to west.yml
  - Enable CONFIG_ZMK_LAYER_STATUS_USB_HID=y
  - Verify layer reports work
  **Validation**: App receives layer changes from keyboard

- [ ] **7.1.2** Decide on approach
  - Option A: Use zmk-feature-appcompanion as-is (layer only)
  - Option B: Fork and add key position reporting
  - Option C: Create new module in this repo
  **Decision point**: Based on whether key highlighting is needed

### 7.2 Key Position Reporting (if needed)
**Dependencies**: 7.1.2 = Option B or C | **Parallel**: No

- [ ] **7.2.1** Subscribe to key events
  ```c
  ZMK_LISTENER(hud_keys, hud_key_event_listener);
  ZMK_SUBSCRIPTION(hud_keys, zmk_keycode_state_changed);
  ```

- [ ] **7.2.2** Send key position reports
  ```c
  // Report format:
  // Byte 24: 0x91 (key event marker)
  // Byte 25: key_position (0-45)
  // Byte 26: is_pressed (0/1)
  // Byte 27: modifier_flags
  ```
  **Validation**: Key presses appear in app

---

## Quick Reference

### Testing Shortcuts

| Shortcut | Layer | HUD |
|----------|-------|-----|
| Fn+1 | Base (0) | Hidden |
| Fn+2 | Num (1) | Shown |
| Fn+3 | Nav (2) | Shown |
| Fn+4 | Fn (3) | Shown |
| Fn+5 | Idea (4) | Shown |

### Config File Locations

```
# Your existing config (source of truth)
~/path/to/zmk-config/keymap_drawer.config.yaml

# App will prompt to select this on first launch
# Or specify via Settings
```

### Physical Layout JSON

Your keyboard layout can be:
1. Exported from keymap-drawer's parse output
2. Fetched from QMK keyboard database
3. Generated from ortho parameters

### Color Extraction from CSS

The app parses `svg_extra_style` to extract colors:
```css
.keypos-13 rect { fill: #cfe2f3; }  /* Home row mods */
text.key.hold { fill: #00838f; }    /* Hold legends */
```

---

## Dependency Graph

```
Phase 1 (Layout Engine)
├── 1.1 Data Structures ────┬── 1.2 QMK Parser ──────┐
├── 1.4 Config Loader ──────┤                        │
└── 1.3 Ortho Generator ────┴── 1.5 Color Extract ───┤
                                                      │
Phase 2 (App Foundation)                              │
├── 2.1 Project Structure ◄─────────────────────────┘
├── 2.2 Testing Mode (Fn+1-5)
└── 2.3 HUD Window

Phase 3 (Rendering)
├── 3.1 Canvas Renderer
├── 3.2 Key Highlighting  
└── 3.3 Layer Display

Phase 4 (Combos)
├── 4.1 Combo Panel
└── 4.2 Combo Highlighting

Phase 5 (HID) — Can develop in parallel with Phase 3-4
├── 5.1 HID Manager
└── 5.2 Integration

Phase 6 (Polish)
├── 6.1 Settings
├── 6.2 Dark Mode
└── 6.3 Distribution

Phase 7 (Firmware) — After app works with testing mode
├── 7.1 Evaluate Reference
└── 7.2 Key Position Reporting
```
