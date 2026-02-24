import Foundation

/// Parses keymap-drawer glyph syntax ($$mdi:icon$$) and maps to SF Symbols or Unicode.
enum GlyphParser {
    
    /// Parse a string for glyph syntax and return the rendered result.
    /// Supports: $$mdi:icon-name$$ -> SF Symbol or fallback
    static func parse(_ text: String) -> ParsedGlyph {
        // Check for glyph syntax: $$mdi:icon-name$$
        guard text.hasPrefix("$$") && text.hasSuffix("$$") else {
            return ParsedGlyph(text: text, isSFSymbol: false)
        }
        
        let inner = String(text.dropFirst(2).dropLast(2))
        
        // Handle mdi: prefix (Material Design Icons)
        if inner.hasPrefix("mdi:") {
            let iconName = String(inner.dropFirst(4))
            if let sfSymbol = mdiToSFSymbol[iconName] {
                return ParsedGlyph(text: sfSymbol, isSFSymbol: true)
            }
            // Fallback: try to convert kebab-case to readable text
            return ParsedGlyph(text: formatIconName(iconName), isSFSymbol: false)
        }
        
        // Handle tabler: prefix
        if inner.hasPrefix("tabler:") {
            let iconName = String(inner.dropFirst(7))
            if let sfSymbol = tablerToSFSymbol[iconName] {
                return ParsedGlyph(text: sfSymbol, isSFSymbol: true)
            }
            return ParsedGlyph(text: formatIconName(iconName), isSFSymbol: false)
        }
        
        // Unknown glyph format, return as-is
        return ParsedGlyph(text: inner, isSFSymbol: false)
    }
    
    /// Check if a string contains glyph syntax
    static func containsGlyph(_ text: String) -> Bool {
        return text.contains("$$") && text.hasPrefix("$$") && text.hasSuffix("$$")
    }
    
    private static func formatIconName(_ name: String) -> String {
        // Convert kebab-case to title case
        name.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
    
    /// Material Design Icons to SF Symbols mapping
    /// Based on common icons used in keymap-drawer configs
    static let mdiToSFSymbol: [String: String] = [
        // Navigation
        "arrow-left": "arrow.left",
        "arrow-right": "arrow.right",
        "arrow-up": "arrow.up",
        "arrow-down": "arrow.down",
        "chevron-left": "chevron.left",
        "chevron-right": "chevron.right",
        "chevron-up": "chevron.up",
        "chevron-down": "chevron.down",
        "home": "house",
        "home-outline": "house",
        
        // Media
        "play": "play.fill",
        "pause": "pause.fill",
        "play-pause": "playpause.fill",
        "skip-next": "forward.end.fill",
        "skip-previous": "backward.end.fill",
        "volume-high": "speaker.wave.3.fill",
        "volume-medium": "speaker.wave.2.fill",
        "volume-low": "speaker.wave.1.fill",
        "volume-mute": "speaker.slash.fill",
        "volume-off": "speaker.slash.fill",
        "volume-plus": "speaker.plus.fill",
        "volume-minus": "speaker.minus.fill",
        
        // System
        "bluetooth": "antenna.radiowaves.left.and.right",
        "bluetooth-connect": "antenna.radiowaves.left.and.right",
        "wifi": "wifi",
        "power": "power",
        "power-standby": "power",
        "restart": "arrow.clockwise",
        "refresh": "arrow.clockwise",
        "sync": "arrow.triangle.2.circlepath",
        "cog": "gearshape",
        "cog-outline": "gearshape",
        "settings": "gearshape",
        
        // Keyboard
        "keyboard": "keyboard",
        "keyboard-outline": "keyboard",
        "backspace": "delete.left",
        "backspace-outline": "delete.left",
        "keyboard-return": "return",
        "keyboard-tab": "arrow.right.to.line",
        "keyboard-space": "space",
        "keyboard-caps": "capslock",
        "caps-lock": "capslock",
        "apple-keyboard-caps": "capslock.fill",
        
        // Actions
        "content-copy": "doc.on.doc",
        "content-paste": "doc.on.clipboard",
        "content-cut": "scissors",
        "undo": "arrow.uturn.backward",
        "redo": "arrow.uturn.forward",
        "delete": "trash",
        "delete-outline": "trash",
        "magnify": "magnifyingglass",
        "search": "magnifyingglass",
        
        // Brightness
        "brightness-5": "sun.max.fill",
        "brightness-6": "sun.max.fill",
        "brightness-7": "sun.max.fill",
        "brightness-auto": "sun.max",
        "white-balance-sunny": "sun.max.fill",
        "weather-sunny": "sun.max.fill",
        "brightness-high": "sun.max.fill",
        "brightness-low": "sun.min.fill",
        
        // Layers
        "layers": "square.3.layers.3d",
        "layers-outline": "square.3.layers.3d",
        "layer-plus": "square.3.layers.3d.down.right",
        "layer-minus": "square.3.layers.3d.down.left",
        
        // Misc
        "repeat": "repeat",
        "repeat-once": "repeat.1",
        "apple": "apple.logo",
        "apple-keyboard-command": "command",
        "apple-keyboard-option": "option",
        "apple-keyboard-control": "control",
        "apple-keyboard-shift": "shift",
        "microsoft-windows": "rectangle.split.3x3",
        "linux": "terminal",
        "plus": "plus",
        "minus": "minus",
        "close": "xmark",
        "check": "checkmark",
        "alert": "exclamationmark.triangle",
        "information": "info.circle",
        "lock": "lock.fill",
        "lock-open": "lock.open.fill",
        "eye": "eye",
        "eye-off": "eye.slash",
        "flash": "bolt.fill",
        "flash-outline": "bolt",
        
        // Function keys
        "function": "function",
        "function-variant": "function",
        
        // Mouse
        "mouse": "computermouse",
        "cursor-default": "cursorarrow",
        "cursor-default-click": "cursorarrow.click",
        "gesture-tap": "hand.tap",
        
        // Numbers
        "numeric": "number",
        "numeric-0": "0.circle",
        "numeric-1": "1.circle",
        "numeric-2": "2.circle",
        "numeric-3": "3.circle",
        "numeric-4": "4.circle",
        "numeric-5": "5.circle",
        "numeric-6": "6.circle",
        "numeric-7": "7.circle",
        "numeric-8": "8.circle",
        "numeric-9": "9.circle",
    ]
    
    /// Tabler Icons to SF Symbols mapping
    static let tablerToSFSymbol: [String: String] = [
        "arrow-left": "arrow.left",
        "arrow-right": "arrow.right",
        "arrow-up": "arrow.up",
        "arrow-down": "arrow.down",
        "home": "house",
        "settings": "gearshape",
        "bluetooth": "antenna.radiowaves.left.and.right",
        "wifi": "wifi",
        "volume": "speaker.wave.2.fill",
        "volume-off": "speaker.slash.fill",
        "sun": "sun.max.fill",
        "moon": "moon.fill",
        "keyboard": "keyboard",
        "copy": "doc.on.doc",
        "clipboard": "doc.on.clipboard",
        "scissors": "scissors",
        "refresh": "arrow.clockwise",
        "search": "magnifyingglass",
        "trash": "trash",
        "lock": "lock.fill",
        "lock-open": "lock.open.fill",
        "command": "command",
        "backspace": "delete.left",
    ]
}

/// Result of parsing a glyph string
struct ParsedGlyph {
    /// The resulting text (either SF Symbol name or fallback text)
    let text: String
    /// Whether the text is an SF Symbol name (use Image(systemName:)) or plain text
    let isSFSymbol: Bool
}
