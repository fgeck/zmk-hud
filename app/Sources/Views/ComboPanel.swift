import SwiftUI

struct LeftComboPanel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LEFT COMBOS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            if let keymap = appState.keymap {
                let filteredCombos = filterCombosForCurrentLayer(keymap.combos)
                let leftCombos = filteredCombos.filter { combo in
                    guard let firstPos = combo.positions.first else { return false }
                    return firstPos < 29
                }
                
                if leftCombos.isEmpty {
                    Text("No combos")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ComboListView(combos: leftCombos, keymap: keymap, customLabels: appState.customLabels)
                }
            } else {
                Text("No keymap")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func filterCombosForCurrentLayer(_ combos: [Combo]) -> [Combo] {
        let currentLayer = appState.currentLayer
        return combos.filter { combo in
            guard let comboLayers = combo.layers, !comboLayers.isEmpty else {
                return true
            }
            return comboLayers.contains(currentLayer)
        }
    }
}

struct RightComboPanel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text("RIGHT COMBOS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            if let keymap = appState.keymap {
                let filteredCombos = filterCombosForCurrentLayer(keymap.combos)
                let rightCombos = filteredCombos.filter { combo in
                    guard let firstPos = combo.positions.first else { return false }
                    return firstPos >= 29
                }
                
                if rightCombos.isEmpty {
                    Text("No combos")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ComboListView(combos: rightCombos, keymap: keymap, customLabels: appState.customLabels, alignRight: true)
                }
            } else {
                Text("No keymap")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func filterCombosForCurrentLayer(_ combos: [Combo]) -> [Combo] {
        let currentLayer = appState.currentLayer
        return combos.filter { combo in
            guard let comboLayers = combo.layers, !comboLayers.isEmpty else {
                return true
            }
            return comboLayers.contains(currentLayer)
        }
    }
}

struct ComboListView: View {
    let combos: [Combo]
    let keymap: Keymap
    var customLabels: [String: String] = [:]
    var alignRight: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: alignRight ? .trailing : .leading, spacing: 4) {
                ForEach(combos, id: \.name) { combo in
                    ComboRow(combo: combo, keymap: keymap, customLabels: customLabels, alignRight: alignRight)
                }
            }
        }
    }
}

struct ComboRow: View {
    let combo: Combo
    let keymap: Keymap
    var customLabels: [String: String] = [:]
    var alignRight: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if alignRight {
                Text(combo.result.displayLabel(with: customLabels))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                
                Text("←")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                
                Text(keyLabelsString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                Text(keyLabelsString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text("→")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                
                Text(combo.result.displayLabel(with: customLabels))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
        }
    }
    
    private var keyLabelsString: String {
        guard let baseLayer = keymap.layers.first else { return "?" }
        let allBindings = baseLayer.bindings
        
        return combo.positions.map { position in
            if position < allBindings.count {
                let binding = allBindings[position]
                return friendlyKeyLabel(for: binding)
            }
            return "?"
        }.joined(separator: "+")
    }
    
    private func friendlyKeyLabel(for binding: Binding) -> String {
        switch binding.type {
        case .keyPress(let key):
            return formatKeyName(key)
        case .layerTap(_, let key):
            return formatKeyName(key)
        case .modTap(_, let tap):
            return formatKeyName(tap)
        case .holdTap(_, let tap):
            return formatKeyName(tap)
        case .tapDance(let name):
            // Check customLabels first
            if let custom = customLabels[name] {
                return custom
            }
            if let behavior = keymap.behaviors[name],
               let firstBinding = behavior.bindings.first {
                return formatKeyName(extractKeyFromBinding(firstBinding))
            }
            // Fall back to stripping td_ prefix
            return formatTapDanceName(name)
        case .layerMomentary(let layer):
            return "L\(layer)"
        case .transparent, .none:
            return "·"
        case .custom(let raw):
            return formatKeyName(raw)
        }
    }
    
    private func extractKeyFromBinding(_ raw: String) -> String {
        let parts = raw.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if parts.count >= 2 {
            if parts[0] == "&kp" {
                return parts[1]
            } else if parts[0] == "&mt" && parts.count >= 3 {
                return parts[2]
            } else if parts.count >= 2 {
                return parts.last ?? raw
            }
        }
        return raw
    }
    
    private func formatKeyName(_ key: String) -> String {
        var result = key
            .removingPrefix("KP_")
            .removingPrefix("K_")
        
        let keyMappings: [String: String] = [
            "SPACE": "SPC",
            "ENTER": "ENT",
            "RETURN": "RET",
            "BACKSPACE": "BSP",
            "BSPC": "BSP",
            "DELETE": "DEL",
            "ESCAPE": "ESC",
            "LSHIFT": "LSH",
            "RSHIFT": "RSH",
            "LCTRL": "LCT",
            "RCTRL": "RCT",
            "LALT": "LAL",
            "RALT": "RAL",
            "LGUI": "LGU",
            "RGUI": "RGU",
            "LSHFT": "LSH",
            "RSHFT": "RSH",
            "SEMICOLON": ";",
            "SEMI": ";",
            "APOSTROPHE": "'",
            "APOS": "'",
            "SQT": "'",
            "COMMA": ",",
            "PERIOD": ".",
            "DOT": ".",
            "SLASH": "/",
            "FSLH": "/",
            "BACKSLASH": "\\",
            "BSLH": "\\",
            "MINUS": "-",
            "EQUAL": "=",
            "LBRACKET": "[",
            "RBRACKET": "]",
            "LBKT": "[",
            "RBKT": "]",
            "GRAVE": "`",
            "TILDE": "~",
            "TAB": "TAB",
            "CAPS": "CAP",
            "CAPSLOCK": "CAP"
        ]
        
        if let mapped = keyMappings[result.uppercased()] {
            return mapped
        }
        
        if result.count == 1 {
            return result.uppercased()
        }
        
        if result.hasPrefix("N") && result.count == 2 {
            return String(result.dropFirst())
        }
        
        if result.count > 4 {
            return String(result.prefix(3)).uppercased()
        }
        
        return result.uppercased()
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
}

extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
