import SwiftUI

struct KeyColors {
    static let defaultKey = Color(hex: "#f6f8fa")
    static let defaultKeyDark = Color(hex: "#3f4750")
    
    static let homeRowMod = Color(hex: "#cfe2f3")
    static let homeRowModDark = Color(hex: "#1a3a5c")
    
    static let holdText = Color(hex: "#00838f")
    static let holdTextDark = Color(hex: "#4dd0e1")
    
    static let tapDance = Color(hex: "#7b1fa2")
    static let tapDanceDark = Color(hex: "#ce93d8")
    
    static let layerActivator = Color(hex: "#d9ead3")
    static let layerActivatorDark = Color(hex: "#274e13")
    
    static let pressed = Color(hex: "#e6b8af")
    static let pressedDark = Color(hex: "#5b3a3a")
    
    static let transparent = Color(hex: "#f3f3f3")
    static let transparentDark = Color(hex: "#2a2a2a")
    
    static let stroke = Color(hex: "#c9cccf")
    static let strokeDark = Color(hex: "#60666c")
}

struct ScaledKeyPosition {
    let index: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotation: CGFloat
}

struct KeyView: View {
    let binding: KeyBinding
    let position: ScaledKeyPosition
    let isPressed: Bool
    var customLabels: [String: String] = [:]
    var tapDanceShifted: [String: String] = [:]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(strokeColor, lineWidth: 1)
                )
            
            VStack(spacing: 1) {
                // Shifted/double-tap label for tap-dance (purple, smaller, at top)
                if let shiftedLabel = shiftedLabel {
                    Text(shiftedLabel)
                        .font(.system(size: 9))
                        .foregroundColor(tapDanceShiftedColor)
                }
                
                // Hold label (for home-row mods)
                if let holdLabel = binding.holdLabel {
                    Text(holdLabel)
                        .font(.system(size: 9))
                        .foregroundColor(holdColor)
                }
                
                // Main tap label
                Text(binding.displayLabel(with: customLabels))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(4)
        }
        .frame(width: position.width, height: position.height)
    }
    
    /// Returns the shifted/double-tap label for tap-dance keys or hold-tap with embedded tap-dance
    private var shiftedLabel: String? {
        switch binding.type {
        case .tapDance(let name):
            return tapDanceShifted[name]
        case .holdTap(_, let tap):
            // Check if tap label matches a tap-dance shifted entry (e.g., "A" -> td_a -> "ä")
            // Look for td_X where X matches the tap label
            let tdName = "td_" + tap.lowercased()
            return tapDanceShifted[tdName]
        default:
            return nil
        }
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return colorScheme == .dark ? KeyColors.pressedDark : KeyColors.pressed
        }
        
        switch binding.type {
        case .transparent:
            return colorScheme == .dark ? KeyColors.transparentDark : KeyColors.transparent
        case .layerMomentary, .layerTap:
            return colorScheme == .dark ? KeyColors.layerActivatorDark : KeyColors.layerActivator
        case .holdTap(let hold, _), .modTap(let hold, _):
            // Only use blue background for actual home-row mods (single modifier symbols)
            let modifierSymbols = ["⌘", "⌥", "⌃", "⇧"]
            if modifierSymbols.contains(hold) {
                return colorScheme == .dark ? KeyColors.homeRowModDark : KeyColors.homeRowMod
            }
            return colorScheme == .dark ? KeyColors.defaultKeyDark : KeyColors.defaultKey
        case .tapDance:
            // Tap-dance keys use default background (no special color)
            return colorScheme == .dark ? KeyColors.defaultKeyDark : KeyColors.defaultKey
        default:
            return colorScheme == .dark ? KeyColors.defaultKeyDark : KeyColors.defaultKey
        }
    }
    
    private var strokeColor: Color {
        colorScheme == .dark ? KeyColors.strokeDark : KeyColors.stroke
    }
    
    private var textColor: Color {
        if case .transparent = binding.type {
            return .gray
        }
        return colorScheme == .dark ? Color(hex: "#d1d6db") : Color(hex: "#24292e")
    }
    
    private var holdColor: Color {
        colorScheme == .dark ? KeyColors.holdTextDark : KeyColors.holdText
    }
    
    private var tapDanceShiftedColor: Color {
        colorScheme == .dark ? KeyColors.tapDanceDark : KeyColors.tapDance
    }
}

// Color.init(hex:) is defined in Config/ColorScheme.swift
