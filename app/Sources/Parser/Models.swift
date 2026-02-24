import Foundation

struct Keymap {
    var layers: [Layer]
    var combos: [Combo]
    var behaviors: [String: Behavior]
    var rowStructure: [Int]?
}

struct Layer {
    var name: String
    var bindings: [Binding]
}

struct Binding {
    enum BindingType {
        case keyPress(String)
        case layerTap(Int, String)
        case layerMomentary(Int)
        case modTap(String, String)
        case holdTap(String, String)
        case tapDance(String)
        case transparent
        case none
        case custom(String)
        // New behavior types
        case capsWord
        case keyRepeat
        case stickyLayer(Int)
        case toggleLayer(Int)
        case toLayer(Int)
        case bootloader
        case reset
        case bluetooth(String)
        case outputSelect(String)
        case macro(String)
    }
    
    var type: BindingType
    var raw: String
    
    var displayLabel: String {
        displayLabel(with: [:])
    }
    
    /// Get parsed glyph for rendering (returns SF Symbol info if applicable)
    func parsedDisplayLabel(with customLabels: [String: String] = [:]) -> ParsedGlyph {
        switch type {
        case .tapDance(let name):
            if let custom = customLabels[name] {
                return GlyphParser.parse(custom)
            }
            return ParsedGlyph(text: formatTapDanceName(name), isSFSymbol: false)
        case .custom(let raw):
            if let custom = customLabels[raw] {
                return GlyphParser.parse(custom)
            }
            return ParsedGlyph(text: raw, isSFSymbol: false)
        default:
            // For most types, use the regular displayLabel
            return ParsedGlyph(text: displayLabel(with: customLabels), isSFSymbol: false)
        }
    }
    
    func displayLabel(with customLabels: [String: String]) -> String {
        switch type {
        case .keyPress(let key):
            return ZMKKeycodeMap.convert(key)
        case .layerTap(_, let key):
            return ZMKKeycodeMap.convert(key)
        case .layerMomentary(let layer):
            return "L\(layer)"
        case .modTap(_, let tap):
            // For home row mods, show the tap key with converted symbol
            return ZMKKeycodeMap.convert(tap)
        case .holdTap(_, let tap):
            return ZMKKeycodeMap.convert(tap)
        case .tapDance(let name):
            if let custom = customLabels[name] {
                return parseGlyphLabel(custom)
            }
            return formatTapDanceName(name)
        case .transparent:
            return "▽"
        case .none:
            return ""
        case .custom(let raw):
            if let custom = customLabels[raw] {
                return parseGlyphLabel(custom)
            }
            return raw
        // New behavior types
        case .capsWord:
            return "CAPS"
        case .keyRepeat:
            return "⟳"
        case .stickyLayer(let layer):
            return "S\(layer)"
        case .toggleLayer(let layer):
            return "T\(layer)"
        case .toLayer(let layer):
            return "→L\(layer)"
        case .bootloader:
            return "Boot"
        case .reset:
            return "Reset"
        case .bluetooth(let action):
            return formatBluetoothAction(action)
        case .outputSelect(let output):
            return formatOutputSelect(output)
        case .macro(let name):
            if let custom = customLabels[name] {
                return custom
            }
            return formatMacroName(name)
        }
    }
    
    var holdLabel: String? {
        switch type {
        case .modTap(let mod, _):
            return ZMKKeycodeMap.convert(mod)
        case .holdTap(let hold, _):
            return ZMKKeycodeMap.convert(hold)
        case .layerTap(let layer, _):
            return "L\(layer)"
        default:
            return nil
        }
    }
    
    private func formatTapDanceName(_ name: String) -> String {
        let key = name
            .replacingOccurrences(of: "td_", with: "")
            .replacingOccurrences(of: "TD_", with: "")
        
        let specialMappings: [String: String] = [
            "semi": ";",
            "comma": ",",
            "dot": ".",
            "slash": "/",
            "fslh": "/",
            "sqt": "'",
            "apos": "'",
            "dqt": "\"",
            "lbkt": "[",
            "rbkt": "]",
            "lbrc": "{",
            "rbrc": "}"
        ]
        
        if let mapped = specialMappings[key.lowercased()] {
            return mapped
        }
        
        return key.uppercased()
    }
    
    private func formatBluetoothAction(_ action: String) -> String {
        let btActions: [String: String] = [
            "BT_CLR": "BT✕",
            "BT_CLR_ALL": "BT✕All",
            "BT_SEL": "BT",
            "BT_NXT": "BT▶",
            "BT_PRV": "BT◀",
            "BT_DISC": "BT⚡"
        ]
        
        // Handle BT_SEL with index (e.g., BT_SEL 0)
        if action.hasPrefix("BT_SEL") {
            let parts = action.split(separator: " ")
            if parts.count > 1, let index = Int(parts[1]) {
                return "BT\(index + 1)"
            }
            return "BT"
        }
        
        return btActions[action] ?? "BT"
    }
    
    private func formatOutputSelect(_ output: String) -> String {
        let outputs: [String: String] = [
            "OUT_USB": "USB",
            "OUT_BLE": "BLE",
            "OUT_TOG": "⇄"
        ]
        return outputs[output] ?? output
    }
    
    private func formatMacroName(_ name: String) -> String {
        // Remove common prefixes
        var clean = name
            .replacingOccurrences(of: "macro_", with: "")
            .replacingOccurrences(of: "MACRO_", with: "")
            .replacingOccurrences(of: "m_", with: "")
            .replacingOccurrences(of: "M_", with: "")
        
        // Capitalize first letter if it's a word
        if clean.count > 0 {
            clean = clean.prefix(1).uppercased() + clean.dropFirst()
        }
        
        return clean
    }
    
    /// Parse glyph syntax in custom labels
    private func parseGlyphLabel(_ label: String) -> String {
        let parsed = GlyphParser.parse(label)
        // For display purposes, we return the text
        // The view layer can check isSFSymbol to render appropriately
        return parsed.text
    }
}

struct Combo {
    var name: String
    var positions: [Int]
    var result: Binding
    var layers: [Int]?
    var timeoutMs: Int?
}

struct Behavior {
    var name: String
    var type: String
    var bindings: [String]
}
