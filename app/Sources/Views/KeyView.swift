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

struct KeyView: View {
    let binding: Binding
    let position: KeyPosition
    let isPressed: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(strokeColor, lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                if let holdLabel = binding.holdLabel {
                    Text(holdLabel)
                        .font(.system(size: 9))
                        .foregroundColor(holdColor)
                }
                
                Text(binding.displayLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(4)
        }
        .frame(width: position.width, height: position.height)
        .rotationEffect(.degrees(position.rotation))
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
        case .holdTap, .modTap:
            return colorScheme == .dark ? KeyColors.homeRowModDark : KeyColors.homeRowMod
        case .tapDance:
            return colorScheme == .dark ? KeyColors.tapDanceDark : KeyColors.tapDance
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
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
