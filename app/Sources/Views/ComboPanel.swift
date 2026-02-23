import SwiftUI

struct ComboPanel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMBOS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            if let keymap = appState.keymap {
                ComboList(combos: keymap.combos)
            } else {
                Text("No keymap loaded")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .frame(width: 180)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ComboList: View {
    let combos: [Combo]
    
    private var leftHandCombos: [Combo] {
        combos.filter { combo in
            guard let firstPos = combo.positions.first else { return false }
            return firstPos < 30
        }
    }
    
    private var rightHandCombos: [Combo] {
        combos.filter { combo in
            guard let firstPos = combo.positions.first else { return false }
            return firstPos >= 30
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !leftHandCombos.isEmpty {
                    ComboSection(title: "LEFT HAND", combos: leftHandCombos)
                }
                
                if !rightHandCombos.isEmpty {
                    ComboSection(title: "RIGHT HAND", combos: rightHandCombos)
                }
            }
        }
    }
}

struct ComboSection: View {
    let title: String
    let combos: [Combo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ForEach(combos, id: \.name) { combo in
                ComboRow(combo: combo)
            }
        }
    }
}

struct ComboRow: View {
    let combo: Combo
    
    var body: some View {
        HStack {
            Text(positionString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text(combo.result.displayLabel)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
    }
    
    private var positionString: String {
        combo.positions.map(String.init).joined(separator: "─")
    }
}
