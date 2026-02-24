import Foundation
import Combine

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
            customLabels: customLabels,
            tapDanceShifted: tapDanceShifted,
            hudPosition: hudPosition,
            hudOpacity: hudOpacity,
            hudScale: hudScale
        )
        try? configManager.save(config)
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
        let options = LayoutLoader.shared.getAvailableLayoutsFromFile(path)
        availableLayouts = options
        
        let effectiveLayoutId = layoutId ?? options.first?.id
        selectedLayoutId = effectiveLayoutId
        
        if let layout = LayoutLoader.shared.loadFromFile(path, layoutId: effectiveLayoutId) {
            physicalLayout = layout
            layoutPath = path
            layoutLoadError = nil
            saveConfig()
            autoDetectBindingOffset()
        } else {
            layoutLoadError = "Failed to parse layout file"
        }
    }
    
    func loadLayoutFromURL(_ urlString: String, layoutId: String? = nil) {
        isLoadingLayout = true
        layoutLoadError = nil
        
        LayoutLoader.shared.getAvailableLayoutsFromURL(urlString) { [weak self] options in
            self?.availableLayouts = options
            
            if options.count > 1 && layoutId == nil {
                self?.isLoadingLayout = false
                self?.layoutPath = urlString
                self?.saveConfig()
                return
            }
            
            let effectiveLayoutId = layoutId ?? options.first?.id
            self?.selectedLayoutId = effectiveLayoutId
            
            LayoutLoader.shared.loadFromURL(urlString, layoutId: effectiveLayoutId) { [weak self] layout in
                self?.isLoadingLayout = false
                if let layout = layout {
                    self?.physicalLayout = layout
                    self?.layoutPath = urlString
                    self?.layoutLoadError = nil
                    self?.saveConfig()
                    self?.autoDetectBindingOffset()
                } else {
                    self?.layoutLoadError = "Failed to load layout from URL"
                }
            }
        }
    }
    
    func selectLayout(_ layoutId: String) {
        guard let path = layoutPath else { return }
        selectedLayoutId = layoutId
        
        if path.hasPrefix("http") {
            isLoadingLayout = true
            LayoutLoader.shared.loadFromURL(path, layoutId: layoutId) { [weak self] layout in
                self?.isLoadingLayout = false
                if let layout = layout {
                    self?.physicalLayout = layout
                    self?.saveConfig()
                    self?.autoDetectBindingOffset()
                }
            }
        } else {
            if let layout = LayoutLoader.shared.loadFromFile(path, layoutId: layoutId) {
                physicalLayout = layout
                saveConfig()
                autoDetectBindingOffset()
            }
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
            physicalLayout = LayoutLoader.shared.createFallbackFromRowStructure(rowStructure)
        } else if let firstLayer = keymap.layers.first {
            physicalLayout = LayoutLoader.shared.createFallbackGrid(keyCount: firstLayer.bindings.count)
        }
    }
    
    func currentBindings(for layer: Int) -> [Binding] {
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
        let positionCount = layout.positions.count
        
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

}