import SwiftUI

struct LeftComboPanel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ComboPanelContainer(
            title: "LEFT",
            alignment: .leading,
            combos: leftCombos,
            keymap: appState.keymap,
            customLabels: appState.customLabels,
            alignRight: false
        )
    }
    
    private var leftCombos: [Combo] {
        guard let keymap = appState.keymap else { return [] }
        let filtered = filterCombosForCurrentLayer(keymap.combos)
        return filtered.filter { combo in
            guard let firstPos = combo.positions.first else { return false }
            return firstPos < 29
        }
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
        ComboPanelContainer(
            title: "RIGHT",
            alignment: .trailing,
            combos: rightCombos,
            keymap: appState.keymap,
            customLabels: appState.customLabels,
            alignRight: true
        )
    }
    
    private var rightCombos: [Combo] {
        guard let keymap = appState.keymap else { return [] }
        let filtered = filterCombosForCurrentLayer(keymap.combos)
        return filtered.filter { combo in
            guard let firstPos = combo.positions.first else { return false }
            return firstPos >= 29
        }
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

// MARK: - Shared Combo Panel Container

struct ComboPanelContainer: View {
    let title: String
    let alignment: HorizontalAlignment
    let combos: [Combo]
    let keymap: Keymap?
    let customLabels: [String: String]
    let alignRight: Bool
    
    var body: some View {
        VStack(alignment: alignment, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                if !alignRight {
                    Image(systemName: "keyboard.chevron.compact.left")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                if alignRight {
                    Image(systemName: "keyboard.chevron.compact.right")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Combo count badge
            if !combos.isEmpty {
                Text("\(combos.count) combo\(combos.count == 1 ? "" : "s")")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Divider()
                .frame(width: 60)
            
            // Combo list
            if let keymap = keymap, !combos.isEmpty {
                ComboListView(combos: combos, keymap: keymap, customLabels: customLabels, alignRight: alignRight)
            } else if combos.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.title3)
                        .foregroundColor(Color.secondary.opacity(0.6))
                    Text("No combos")
                        .font(.caption2)
                        .foregroundColor(Color.secondary.opacity(0.6))
                }
                .padding(.vertical, 8)
            } else {
                Text("No keymap")
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.6))
            }
        }
        .frame(width: 130)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
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
    
    private func friendlyKeyLabel(for binding: KeyBinding) -> String {
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
            return formatBluetoothLabel(action)
        case .outputSelect(let output):
            return formatOutputLabel(output)
        case .macro(let name):
            return formatMacroLabel(name)
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
    
    private func formatBluetoothLabel(_ action: String) -> String {
        if action.hasPrefix("BT_SEL") {
            let parts = action.split(separator: " ")
            if parts.count > 1, let index = Int(parts[1]) {
                return "BT\(index + 1)"
            }
        }
        let labels: [String: String] = [
            "BT_CLR": "BT✕",
            "BT_NXT": "BT▶",
            "BT_PRV": "BT◀"
        ]
        return labels[action] ?? "BT"
    }
    
    private func formatOutputLabel(_ output: String) -> String {
        let labels: [String: String] = [
            "OUT_USB": "USB",
            "OUT_BLE": "BLE",
            "OUT_TOG": "⇄"
        ]
        return labels[output] ?? output
    }
    
    private func formatMacroLabel(_ name: String) -> String {
        var clean = name
            .replacingOccurrences(of: "macro_", with: "")
            .replacingOccurrences(of: "MACRO_", with: "")
            .replacingOccurrences(of: "m_", with: "")
        if clean.count > 4 {
            clean = String(clean.prefix(4))
        }
        return clean.uppercased()
    }
}

extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
