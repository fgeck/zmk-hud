import SwiftUI
import Foundation

/// Color scheme extracted from keymap_drawer.config.yaml's svg_extra_style.
/// Provides colors for different key types and states.
struct ColorScheme {
    // Key background colors
    var keyDefault: Color
    var homeRowMod: Color
    var tapDance: Color
    var layerActivator: Color
    var combo: Color
    var pressed: Color
    var trans: Color
    var ghost: Color
    
    // Text colors
    var textDefault: Color
    var textHold: Color
    var textShifted: Color
    var textTrans: Color
    
    // Position-based overrides (key index -> color)
    var keyPositionColors: [Int: Color]
    
    /// Default light mode colors (matching keymap-drawer defaults)
    static var light: ColorScheme {
        ColorScheme(
            keyDefault: Color(hex: "#f6f8fa"),
            homeRowMod: Color(hex: "#cfe2f3"),
            tapDance: Color(hex: "#e1bee7"),  // Light purple background
            layerActivator: Color(hex: "#d9ead3"),
            combo: Color(hex: "#cdf"),
            pressed: Color(hex: "#fdd"),
            trans: Color(hex: "#f3f3f3"),
            ghost: Color(hex: "#fafafa"),
            textDefault: Color(hex: "#24292e"),
            textHold: Color(hex: "#00838f"),
            textShifted: Color(hex: "#7b1fa2"),
            textTrans: Color(hex: "#7b7e81"),
            keyPositionColors: [:]
        )
    }
    
    /// Default dark mode colors
    static var dark: ColorScheme {
        ColorScheme(
            keyDefault: Color(hex: "#3f4750"),
            homeRowMod: Color(hex: "#1a3a5c"),
            tapDance: Color(hex: "#4a148c"),  // Dark purple background
            layerActivator: Color(hex: "#274e13"),
            combo: Color(hex: "#1f3d7a"),
            pressed: Color(hex: "#854747"),
            trans: Color(hex: "#2a2a2a"),
            ghost: Color(hex: "#1a1a1a"),
            textDefault: Color(hex: "#d1d6db"),
            textHold: Color(hex: "#4dd0e1"),
            textShifted: Color(hex: "#ce93d8"),
            textTrans: Color(hex: "#7e8184"),
            keyPositionColors: [:]
        )
    }
    
    /// Create a ColorScheme from CSS style string.
    /// Parses the svg_extra_style field from keymap_drawer.config.yaml.
    static func fromCSS(_ css: String, darkMode: Bool) -> ColorScheme {
        var scheme: ColorScheme = darkMode ? ColorScheme.dark : ColorScheme.light
        var positionColors: [Int: Color] = [:]
        
        // Parse position-specific colors like ".keypos-13 rect { fill: #cfe2f3; }"
        let keyposPattern = #/\.keypos-(\d+)\s+rect\s*\{\s*fill:\s*(#[0-9a-fA-F]+)\s*;?\s*\}/#
        for match in css.matches(of: keyposPattern) {
            if let position = Int(match.1) {
                let colorHex = String(match.2)
                positionColors[position] = Color(hex: colorHex)
            }
        }
        scheme.keyPositionColors = positionColors
        
        // Parse hold text color "text.key.hold { fill: #00838f; }"
        let holdPattern = #/text\.key\.hold\s*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: holdPattern) {
            scheme.textHold = Color(hex: String(match.1))
        }
        
        // Parse shifted text color patterns
        let shiftedPattern = #/text\.key\.shifted\s*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: shiftedPattern) {
            scheme.textShifted = Color(hex: String(match.1))
        }
        
        // Parse trans key styling "rect.trans { fill: #f3f3f3; }"
        let transPattern = #/rect\.trans\s*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: transPattern) {
            scheme.trans = Color(hex: String(match.1))
        }
        
        // Parse layer activator ".layer-activator rect { fill: #d9ead3; }"
        let layerPattern = #/\.layer-activator\s+rect\s*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: layerPattern) {
            scheme.layerActivator = Color(hex: String(match.1))
        }
        
        // Parse combo styling "rect.combo { fill: #fff2cc; }"
        let comboPattern = #/rect\.combo[^{]*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: comboPattern) {
            scheme.combo = Color(hex: String(match.1))
        }
        
        // Parse held/pressed styling "rect.held { fill: #e6b8af; }"
        let heldPattern = #/rect\.held[^{]*\{\s*fill:\s*(#[0-9a-fA-F]+)/#
        if let match = css.firstMatch(of: heldPattern) {
            scheme.pressed = Color(hex: String(match.1))
        }
        
        return scheme
    }
    
    /// Get the background color for a key at a given position.
    func backgroundColor(for keyIndex: Int, type: KeyType = .normal) -> Color {
        // Check for position-specific override
        if let posColor = keyPositionColors[keyIndex] {
            return posColor
        }
        
        // Fall back to type-based color
        switch type {
        case .normal:
            return keyDefault
        case .homeRowMod:
            return homeRowMod
        case .tapDance:
            return keyDefault  // Tap-dance keys use normal background
        case .layerActivator:
            return layerActivator
        case .pressed:
            return pressed
        case .trans:
            return trans
        case .ghost:
            return ghost
        }
    }
    
    enum KeyType {
        case normal
        case homeRowMod
        case tapDance
        case layerActivator
        case pressed
        case trans
        case ghost
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: Double
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = (
                Double((int >> 8) & 0xF) / 15,
                Double((int >> 4) & 0xF) / 15,
                Double(int & 0xF) / 15,
                1
            )
        case 6: // RGB (24-bit)
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                1
            )
        case 8: // RGBA (32-bit)
            (r, g, b, a) = (
                Double((int >> 24) & 0xFF) / 255,
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
