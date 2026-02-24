import SwiftUI

/// Canvas-based keyboard renderer using the new PhysicalLayout engine.
/// Matches keymap-drawer's rendering algorithm for visual consistency.
struct KeyboardCanvas: View {
    let layout: PhysicalLayout
    let colorScheme: ColorScheme
    let legends: [Int: KeyLegend]
    let pressedKeys: Set<Int>
    let currentLayer: Int
    
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var animatedPressedKeys: Set<Int> = []
    
    /// Key dimensions from config
    var keyCornerRadius: Double = 6
    var strokeWidth: Double = 1
    
    var body: some View {
        Canvas { context, size in
            // Draw each key
            for key in layout.keys {
                drawKey(context: &context, key: key)
            }
        }
        .frame(width: layout.width + 20, height: layout.height + 20)
        .animation(.easeOut(duration: 0.15), value: pressedKeys)
        .onChange(of: pressedKeys) { newKeys in
            withAnimation(.easeOut(duration: 0.08)) {
                animatedPressedKeys = newKeys
            }
        }
    }
    
    private func drawKey(context: inout GraphicsContext, key: PhysicalKey) {
        let isDark = systemColorScheme == .dark
        let isPressed = pressedKeys.contains(key.id)
        let legend = legends[key.id]
        let keyType = determineKeyType(for: key.id, legend: legend)
        
        // Get colors
        let backgroundColor = isPressed 
            ? colorScheme.pressed 
            : colorScheme.backgroundColor(for: key.id, type: keyType)
        let strokeColor = isDark ? Color(hex: "#60666c") : Color(hex: "#c9cccf")
        
        // Save context state for rotation
        if key.rotation != 0 {
            context.translateBy(x: key.pos.x, y: key.pos.y)
            context.rotate(by: .degrees(key.rotation))
            context.translateBy(x: -key.pos.x, y: -key.pos.y)
        }
        
        // Draw key background
        let keyRect = CGRect(
            x: key.pos.x - key.width / 2,
            y: key.pos.y - key.height / 2,
            width: key.width,
            height: key.height
        )
        let keyPath = RoundedRectangle(cornerRadius: keyCornerRadius)
            .path(in: keyRect)
        
        context.fill(keyPath, with: .color(backgroundColor))
        context.stroke(keyPath, with: .color(strokeColor), lineWidth: strokeWidth)
        
        // Draw labels
        if let legend = legend {
            drawLabels(context: &context, key: key, legend: legend, isDark: isDark)
        }
        
        // Restore context state
        if key.rotation != 0 {
            context.translateBy(x: key.pos.x, y: key.pos.y)
            context.rotate(by: .degrees(-key.rotation))
            context.translateBy(x: -key.pos.x, y: -key.pos.y)
        }
    }
    
    private func drawLabels(context: inout GraphicsContext, key: PhysicalKey, legend: KeyLegend, isDark: Bool) {
        let centerX = key.pos.x
        let centerY = key.pos.y
        
        // Tap label (center)
        if let tap = legend.tap, !tap.isEmpty {
            let tapText = Text(tap)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(legend.type == "trans" ? colorScheme.textTrans : colorScheme.textDefault)
            context.draw(tapText, at: CGPoint(x: centerX, y: centerY), anchor: .center)
        }
        
        // Hold label (bottom)
        if let hold = legend.hold, !hold.isEmpty {
            let holdText = Text(hold)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(colorScheme.textHold)
            context.draw(holdText, at: CGPoint(x: centerX, y: centerY + key.height / 2 - 10), anchor: .center)
        }
        
        // Shifted label (top)
        if let shifted = legend.shifted, !shifted.isEmpty {
            let shiftedText = Text(shifted)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(colorScheme.textShifted)
            context.draw(shiftedText, at: CGPoint(x: centerX, y: centerY - key.height / 2 + 10), anchor: .center)
        }
    }
    
    private func determineKeyType(for keyIndex: Int, legend: KeyLegend?) -> ColorScheme.KeyType {
        // Check if this is a transparent key
        if legend?.type == "trans" {
            return .trans
        }
        
        // Check if position has a specific color override (home row mods, etc.)
        if colorScheme.keyPositionColors[keyIndex] != nil {
            return .homeRowMod
        }
        
        // Check if this is a layer activator (has hold that starts with "L" or contains layer reference)
        if let hold = legend?.hold, hold.hasPrefix("L") || hold.contains("layer") {
            return .layerActivator
        }
        
        // Check if this is a tap-dance key
        if legend?.shifted != nil && legend?.tap != nil {
            return .tapDance
        }
        
        return .normal
    }
}

/// Legend data for a single key
struct KeyLegend {
    var tap: String?
    var hold: String?
    var shifted: String?
    var type: String?
    
    init(tap: String? = nil, hold: String? = nil, shifted: String? = nil, type: String? = nil) {
        self.tap = tap
        self.hold = hold
        self.shifted = shifted
        self.type = type
    }
    
    /// Create from LegendValue (from keymap_drawer config)
    init(from legendValue: LegendValue) {
        self.tap = legendValue.tap
        self.hold = legendValue.hold
        self.shifted = legendValue.shifted
        self.type = legendValue.type
    }
}

// MARK: - Preview

#Preview {
    let layout = OrthoLayoutGenerator(split: true, rows: 3, columns: 5, thumbs: .count(3))
        .generate(keyW: 56, keyH: 56, splitGap: 30)
    
    let legends: [Int: KeyLegend] = [
        0: KeyLegend(tap: "Q"),
        1: KeyLegend(tap: "W"),
        2: KeyLegend(tap: "E"),
        3: KeyLegend(tap: "R"),
        4: KeyLegend(tap: "T"),
        10: KeyLegend(tap: "A", hold: "⌘"),
        11: KeyLegend(tap: "S", hold: "⌥"),
        12: KeyLegend(tap: "D", hold: "⌃"),
        13: KeyLegend(tap: "F", hold: "⇧"),
    ]
    
    return KeyboardCanvas(
        layout: layout,
        colorScheme: .light,
        legends: legends,
        pressedKeys: [10],
        currentLayer: 0
    )
    .padding()
}
