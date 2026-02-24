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
    @Published var testModeEnabled: Bool = false
    
    struct ModifierFlags: OptionSet {
        let rawValue: UInt8
        
        static let ctrl  = ModifierFlags(rawValue: 1 << 0)
        static let shift = ModifierFlags(rawValue: 1 << 1)
        static let alt   = ModifierFlags(rawValue: 1 << 2)
        static let gui   = ModifierFlags(rawValue: 1 << 3)
    }
    
    private var layerState: UInt16 = 0
    
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
            }
        }.resume()
    }
    
    func reloadLayout() {
        guard let path = layoutPath else { return }
        
        if path.hasPrefix("http") {
            loadLayoutFromURL(path)
        } else {
            loadLayoutFromFile(path)
        }
    }
    
    func loadLayoutFromFile(_ path: String) {
        if let layout = LayoutLoader.shared.loadFromFile(path) {
            physicalLayout = layout
            layoutPath = path
        } else {
            print("Failed to load layout from: \(path)")
        }
    }
    
    func loadLayoutFromURL(_ urlString: String) {
        LayoutLoader.shared.loadFromURL(urlString) { [weak self] layout in
            if let layout = layout {
                self?.physicalLayout = layout
                self?.layoutPath = urlString
            } else {
                print("Failed to fetch layout from: \(urlString)")
            }
        }
    }
    
    func clearLayout() {
        physicalLayout = nil
        layoutPath = nil
        createFallbackLayoutIfNeeded()
    }
    
    private func createFallbackLayoutIfNeeded() {
        guard physicalLayout == nil,
              let keymap = keymap,
              let firstLayer = keymap.layers.first else { return }
        
        let bindingCount = firstLayer.bindings.count
        physicalLayout = LayoutLoader.shared.createFallbackGrid(keyCount: bindingCount)
    }
}
