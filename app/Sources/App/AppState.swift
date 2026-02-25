import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var currentLayer: Int = 0
    @Published var pressedKeys: Set<Int> = []
    @Published var modifiers: ModifierFlags = []
    @Published var hudVisible: Bool = false
    @Published var keymap: Keymap?
    @Published var keymapPath: String?
    @Published var physicalLayout: PhysicalLayout?
    @Published var layoutPath: String?
    @Published var selectedLayoutId: String?
    @Published var availableLayouts: [LayoutOption] = []
    @Published var testModeEnabled: Bool = false
    @Published var isLoadingLayout: Bool = false
    @Published var layoutLoadError: String?
    @Published var hudPosition: String = "topRight"
    @Published var hudOpacity: Double = 0.95
    @Published var hudScale: Double = 1.0
    @Published var bindingOffset: Int = 0
    @Published var customLabels: [String: String] = [:]
    @Published var tapDanceShifted: [String: String] = [:]
    @Published var colorScheme: ColorScheme = .light
    @Published var legends: [Int: KeyLegend] = [:] // Key index -> legend data
    @Published var keymapDrawerConfig: KeymapDrawerConfig?
    @Published var keymapDrawerConfigPath: String?
    @Published var isConnected: Bool = false
    
    // Combo display settings
    @Published var comboDisplayMode: ComboDisplayMode = .both
    
    enum ComboDisplayMode: String, CaseIterable, Codable {
        case both = "both"           // Show dendrons on keyboard + side panels
        case dendrons = "dendrons"   // Only show dendrons on keyboard
        case panels = "panels"       // Only show side panels
        case none = "none"           // Hide all combo displays
        
        var label: String {
            switch self {
            case .both: return "Both (Dendrons + Panels)"
            case .dendrons: return "Dendrons Only"
            case .panels: return "Side Panels Only"
            case .none: return "Hidden"
            }
        }
        
        var icon: String {
            switch self {
            case .both: return "rectangle.split.3x1"
            case .dendrons: return "point.topleft.down.to.point.bottomright.curvepath"
            case .panels: return "sidebar.squares.left"
            case .none: return "eye.slash"
            }
        }
        
        var showDendrons: Bool {
            self == .both || self == .dendrons
        }
        
        var showPanels: Bool {
            self == .both || self == .panels
        }
    }
    
    private let configManager: ConfigManager
    
    struct ModifierFlags: OptionSet {
        let rawValue: UInt8
        
        static let ctrl  = ModifierFlags(rawValue: 1 << 0)
        static let shift = ModifierFlags(rawValue: 1 << 1)
        static let alt   = ModifierFlags(rawValue: 1 << 2)
        static let gui   = ModifierFlags(rawValue: 1 << 3)
    }
    
    private var layerState: UInt16 = 0
    
    init(configManager: ConfigManager = .shared) {
        self.configManager = configManager
        loadConfig()
    }
    
    var activeLayer: Int {
        if layerState == 0 { return 0 }
        for i in (0..<16).reversed() {
            if layerState & (1 << i) != 0 {
                return i
            }
        }
        return 0
    }
    
    var shouldShowHUD: Bool {
        activeLayer != 0
    }
    
    var hasExplicitLayout: Bool {
        layoutPath != nil
    }
    
    func loadConfig() {
        let config = configManager.load()
        hudPosition = config.hudPosition
        hudOpacity = config.hudOpacity
        hudScale = config.hudScale
        customLabels = config.customLabels
        tapDanceShifted = config.tapDanceShifted
        comboDisplayMode = ComboDisplayMode(rawValue: config.comboDisplayMode) ?? .both
        
        // Load keymap_drawer config first (it may override custom labels)
        if let path = config.keymapDrawerConfigPath, !path.isEmpty {
            if path.hasPrefix("http") {
                loadKeymapDrawerConfig(fromURL: path)
            } else {
                loadKeymapDrawerConfig(fromPath: path)
            }
        }
        
        if let path = config.keymapPath, !path.isEmpty {
            if path.hasPrefix("http") {
                loadKeymapFromURL(path)
            } else {
                loadKeymapFromFile(path)
            }
        }
        
        if let path = config.layoutPath, !path.isEmpty {
            if path.hasPrefix("http") {
                loadLayoutFromURL(path, layoutId: config.selectedLayoutId)
            } else {
                loadLayoutFromFile(path, layoutId: config.selectedLayoutId)
            }
        }
    }
    
    func saveConfig() {
        let config = HUDConfig(
            keymapPath: keymapPath,
            layoutPath: layoutPath,
            selectedLayoutId: selectedLayoutId,
            keymapDrawerConfigPath: keymapDrawerConfigPath,
            customLabels: customLabels,
            tapDanceShifted: tapDanceShifted,
            hudPosition: hudPosition,
            hudOpacity: hudOpacity,
            hudScale: hudScale,
            comboDisplayMode: comboDisplayMode.rawValue
        )
        do {
            try configManager.save(config)
            print("Config saved: keymap=\(keymapPath ?? "nil"), layout=\(layoutPath ?? "nil")")
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    func handleLayerChange(layer: Int, active: Bool, state: UInt16) {
        layerState = state
        currentLayer = activeLayer
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func handleKeyPress(keycode: UInt8, pressed: Bool, mods: UInt8) {
        DispatchQueue.main.async {
            if pressed {
                self.pressedKeys.insert(Int(keycode))
            } else {
                self.pressedKeys.remove(Int(keycode))
            }
            self.modifiers = ModifierFlags(rawValue: mods)
        }
    }
    
    func reloadKeymap() {
        guard let path = keymapPath else { return }
        
        if path.hasPrefix("http") {
            loadKeymapFromURL(path)
        } else {
            loadKeymapFromFile(path)
        }
    }
    
    func loadKeymapFromFile(_ path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            keymap = KeymapParser.parse(from: content)
            keymapPath = path
            createFallbackLayoutIfNeeded()
            autoDetectBindingOffset()
            saveConfig()
        } catch {
            print("Failed to load keymap: \(error)")
        }
    }
    
    func loadKeymapFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                print("Failed to fetch keymap: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.keymap = KeymapParser.parse(from: content)
                self?.keymapPath = urlString
                self?.createFallbackLayoutIfNeeded()
                self?.autoDetectBindingOffset()
                self?.saveConfig()
            }
        }.resume()
    }
    
    func reloadLayout() {
        guard let path = layoutPath else { return }
        
        if path.hasPrefix("http") {
            loadLayoutFromURL(path, layoutId: selectedLayoutId)
        } else {
            loadLayoutFromFile(path, layoutId: selectedLayoutId)
        }
    }
    
    func loadLayoutFromFile(_ path: String, layoutId: String? = nil) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            layoutLoadError = "Failed to read layout file"
            return
        }
        
        // Get available layout options
        let layoutNames = QMKLayoutParser.availableLayouts(from: data)
        availableLayouts = layoutNames.map { name in
            LayoutOption(id: name, name: name, keyCount: 0)
        }
        
        let effectiveLayoutId = layoutId ?? layoutNames.first
        selectedLayoutId = effectiveLayoutId
        
        if let layout = QMKLayoutParser.parse(data: data, layoutName: effectiveLayoutId) {
            physicalLayout = layout
            layoutPath = path
            layoutLoadError = nil
            saveConfig()
            autoDetectBindingOffset()
            updateLegends()
        } else {
            layoutLoadError = "Failed to parse layout file"
        }
    }
    
    func loadLayoutFromURL(_ urlString: String, layoutId: String? = nil) {
        isLoadingLayout = true
        layoutLoadError = nil
        
        // Normalize GitHub URLs
        let normalizedURL = normalizeGitHubURL(urlString)
        guard let url = URL(string: normalizedURL) else {
            isLoadingLayout = false
            layoutLoadError = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoadingLayout = false
                
                guard let data = data else {
                    self?.layoutLoadError = "Failed to fetch layout: \(error?.localizedDescription ?? "unknown error")"
                    return
                }
                
                // Get available layout options
                let layoutNames = QMKLayoutParser.availableLayouts(from: data)
                self?.availableLayouts = layoutNames.map { name in
                    LayoutOption(id: name, name: name, keyCount: 0)
                }
                
                // If multiple layouts and no selection, store path and wait for user to pick
                if layoutNames.count > 1 && layoutId == nil {
                    self?.layoutPath = urlString
                    self?.saveConfig()
                    return
                }
                
                let effectiveLayoutId = layoutId ?? layoutNames.first
                self?.selectedLayoutId = effectiveLayoutId
                
                if let layout = QMKLayoutParser.parse(data: data, layoutName: effectiveLayoutId) {
                    self?.physicalLayout = layout
                    self?.layoutPath = urlString
                    self?.layoutLoadError = nil
                    self?.saveConfig()
                    self?.autoDetectBindingOffset()
                    self?.updateLegends()
                } else {
                    self?.layoutLoadError = "Failed to parse layout"
                }
            }
        }.resume()
    }
    
    func selectLayout(_ layoutId: String) {
        guard let path = layoutPath else { return }
        selectedLayoutId = layoutId
        
        if path.hasPrefix("http") {
            loadLayoutFromURL(path, layoutId: layoutId)
        } else {
            loadLayoutFromFile(path, layoutId: layoutId)
        }
    }
    
    func clearLayout() {
        physicalLayout = nil
        layoutPath = nil
        selectedLayoutId = nil
        availableLayouts = []
        layoutLoadError = nil
        createFallbackLayoutIfNeeded()
        saveConfig()
    }
    
    private func createFallbackLayoutIfNeeded() {
        guard !hasExplicitLayout, let keymap = keymap else { return }
        
        if let rowStructure = keymap.rowStructure, !rowStructure.isEmpty {
            // Create a split layout based on row structure
            let generator = OrthoLayoutGenerator(
                split: true,
                rows: rowStructure.count,
                columns: (rowStructure.first ?? 10) / 2,
                thumbs: .count(rowStructure.last ?? 3)
            )
            physicalLayout = generator.generate(keyW: 56, keyH: 56, splitGap: 30)
        } else if let firstLayer = keymap.layers.first {
            // Create a simple grid fallback
            let keyCount = firstLayer.bindings.count
            let cols = min(12, max(6, Int(ceil(sqrt(Double(keyCount) * 2)))))
            let rows = Int(ceil(Double(keyCount) / Double(cols)))
            let generator = OrthoLayoutGenerator(
                split: false,
                rows: rows,
                columns: cols,
                thumbs: .count(0)
            )
            physicalLayout = generator.generate(keyW: 56, keyH: 56, splitGap: 0)
        }
        updateLegends()
    }
    
    func currentBindings(for layer: Int) -> [KeyBinding] {
        guard let keymap = keymap, layer < keymap.layers.count else {
            return []
        }
        let bindings = keymap.layers[layer].bindings
        if bindingOffset > 0 && bindingOffset < bindings.count {
            return Array(bindings.dropFirst(bindingOffset))
        }
        return bindings
    }
    
    func autoDetectBindingOffset() {
        guard let keymap = keymap,
              let layout = physicalLayout,
              !keymap.layers.isEmpty else { return }
        
        let bindingCount = keymap.layers[0].bindings.count
        let positionCount = layout.count
        
        if bindingCount <= positionCount {
            bindingOffset = 0
            return
        }
        
        let potentialOffset = bindingCount - positionCount
        var allNone = true
        
        for layer in keymap.layers {
            for i in 0..<min(potentialOffset, layer.bindings.count) {
                let binding = layer.bindings[i]
                switch binding.type {
                case .none, .transparent:
                    continue
                default:
                    allNone = false
                    break
                }
                if !allNone { break }
            }
            if !allNone { break }
        }
        
        if allNone {
            bindingOffset = potentialOffset
        } else {
            bindingOffset = 0
        }
    }
    
    /// Update legends from current layer bindings
    func updateLegends() {
        guard keymap != nil else {
            legends = [:]
            return
        }
        
        var newLegends: [Int: KeyLegend] = [:]
        let bindings = currentBindings(for: currentLayer)
        
        for (index, binding) in bindings.enumerated() {
            let tap = binding.displayLabel(with: customLabels)
            let hold = binding.holdLabel
            
            // Get shifted value for tap-dance keys
            var shifted: String? = nil
            if case .tapDance(let name) = binding.type {
                shifted = tapDanceShifted[name]
            } else if case .holdTap(_, let tapKey) = binding.type {
                let tdName = "td_" + tapKey.lowercased()
                shifted = tapDanceShifted[tdName]
            }
            
            // Determine type
            var type: String? = nil
            if case .transparent = binding.type {
                type = "trans"
            }
            
            newLegends[index] = KeyLegend(tap: tap, hold: hold, shifted: shifted, type: type)
        }
        
        legends = newLegends
    }
    
    /// Normalize GitHub URLs to raw format
    private func normalizeGitHubURL(_ urlString: String) -> String {
        if urlString.contains("github.com") && urlString.contains("/blob/") {
            return urlString
                .replacingOccurrences(of: "github.com", with: "raw.githubusercontent.com")
                .replacingOccurrences(of: "/blob/", with: "/")
        }
        return urlString
    }
    
    // MARK: - Keymap Drawer Config Loading
    
    /// Load keymap_drawer config from a file path
    func loadKeymapDrawerConfig(fromPath path: String) {
        do {
            let config = try KeymapDrawerConfigLoader.load(fromPath: path)
            keymapDrawerConfig = config
            keymapDrawerConfigPath = path
            applyKeymapDrawerConfig(config)
            saveConfig()
        } catch {
            print("Failed to load keymap_drawer config: \(error)")
        }
    }
    
    /// Load keymap_drawer config from a URL
    func loadKeymapDrawerConfig(fromURL urlString: String) {
        let normalizedURL = normalizeGitHubURL(urlString)
        guard let url = URL(string: normalizedURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data else {
                print("Failed to fetch keymap_drawer config: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            do {
                let config = try KeymapDrawerConfigLoader.load(from: data)
                DispatchQueue.main.async {
                    self?.keymapDrawerConfig = config
                    self?.keymapDrawerConfigPath = urlString
                    self?.applyKeymapDrawerConfig(config)
                    self?.saveConfig()
                }
            } catch {
                print("Failed to parse keymap_drawer config: \(error)")
            }
        }.resume()
    }
    
    /// Apply settings from keymap_drawer config
    private func applyKeymapDrawerConfig(_ config: KeymapDrawerConfig) {
        // Extract custom labels from raw_binding_map
        if let rawBindingMap = config.parseConfig?.rawBindingMap {
            for (binding, legend) in rawBindingMap {
                if let tap = legend.tap {
                    customLabels[binding] = tap
                }
                // Store shifted values for tap-dance keys
                if let shifted = legend.shifted {
                    tapDanceShifted[binding] = shifted
                }
            }
        }
        
        // Extract colors from svg_extra_style
        if let svgStyle = config.drawConfig?.svgExtraStyle {
            // The ColorScheme.fromCSS handles parsing the CSS
            // We need to check system appearance for dark mode
            let isDark: Bool
            switch config.drawConfig?.darkMode {
            case .enabled:
                isDark = true
            case .disabled:
                isDark = false
            case .auto, .none:
                // Use system appearance
                isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            }
            colorScheme = ColorScheme.fromCSS(svgStyle, darkMode: isDark)
        }
        
        updateLegends()
    }

}

// MARK: - Layout Option

struct LayoutOption: Identifiable, Hashable {
    let id: String
    let name: String
    let keyCount: Int
}