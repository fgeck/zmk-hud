import Foundation

/// Comprehensive ZMK keycode to display symbol mapping.
/// Ported from keymap-drawer's zmk_keycode_map.
struct ZMKKeycodeMap {
    
    /// Default ZMK keycode mappings matching keymap-drawer
    static let defaultMap: [String: String] = [
        // Special symbols
        "EXCLAMATION": "!",
        "EXCL": "!",
        "AT_SIGN": "@",
        "AT": "@",
        "HASH": "#",
        "POUND": "#",
        "DOLLAR": "$",
        "DLLR": "$",
        "PERCENT": "%",
        "PRCNT": "%",
        "CARET": "^",
        "AMPERSAND": "&",
        "AMPS": "&",
        "ASTERISK": "*",
        "ASTRK": "*",
        "STAR": "*",
        "LEFT_PARENTHESIS": "(",
        "LPAR": "(",
        "RIGHT_PARENTHESIS": ")",
        "RPAR": ")",
        "EQUAL": "=",
        "PLUS": "+",
        "MINUS": "-",
        "UNDERSCORE": "_",
        "UNDER": "_",
        "SLASH": "/",
        "FSLH": "/",
        "QUESTION": "?",
        "QMARK": "?",
        "BACKSLASH": "\\",
        "BSLH": "\\",
        "PIPE": "|",
        "NON_US_BACKSLASH": "\\",
        "PIPE2": "|",
        "NON_US_BSLH": "|",
        "SEMICOLON": ";",
        "SEMI": ";",
        "COLON": ":",
        "SINGLE_QUOTE": "'",
        "SQT": "'",
        "APOSTROPHE": "'",
        "APOS": "'",
        "DOUBLE_QUOTES": "\"",
        "DQT": "\"",
        "COMMA": ",",
        "LESS_THAN": "<",
        "LT": "<",
        "PERIOD": ".",
        "DOT": ".",
        "GREATER_THAN": ">",
        "GT": ">",
        "LEFT_BRACKET": "[",
        "LBKT": "[",
        "LEFT_BRACE": "{",
        "LBRC": "{",
        "RIGHT_BRACKET": "]",
        "RBKT": "]",
        "RIGHT_BRACE": "}",
        "RBRC": "}",
        "GRAVE": "`",
        "TILDE": "~",
        "NON_US_HASH": "#",
        "NUHS": "#",
        "TILDE2": "~",
        
        // Modifiers
        "LEFT_SHIFT": "⇧",
        "LSHIFT": "⇧",
        "LSHFT": "⇧",
        "RIGHT_SHIFT": "⇧",
        "RSHIFT": "⇧",
        "RSHFT": "⇧",
        "LEFT_CONTROL": "⌃",
        "LCTRL": "⌃",
        "LCTL": "⌃",
        "RIGHT_CONTROL": "⌃",
        "RCTRL": "⌃",
        "RCTL": "⌃",
        "LEFT_ALT": "⌥",
        "LALT": "⌥",
        "RIGHT_ALT": "⌥",
        "RALT": "⌥",
        "LEFT_GUI": "⌘",
        "LGUI": "⌘",
        "LEFT_WIN": "⌘",
        "LWIN": "⌘",
        "LEFT_COMMAND": "⌘",
        "LCMD": "⌘",
        "LEFT_META": "⌘",
        "LMETA": "⌘",
        "RIGHT_GUI": "⌘",
        "RGUI": "⌘",
        "RIGHT_WIN": "⌘",
        "RWIN": "⌘",
        "RIGHT_COMMAND": "⌘",
        "RCMD": "⌘",
        "RIGHT_META": "⌘",
        "RMETA": "⌘",
        
        // Navigation
        "UP_ARROW": "↑",
        "UP": "↑",
        "DOWN_ARROW": "↓",
        "DOWN": "↓",
        "LEFT_ARROW": "←",
        "LEFT": "←",
        "RIGHT_ARROW": "→",
        "RIGHT": "→",
        "HOME": "⇱",
        "END": "⇲",
        "PAGE_UP": "⇞",
        "PG_UP": "⇞",
        "PAGE_DOWN": "⇟",
        "PG_DN": "⇟",
        
        // Editing
        "BACKSPACE": "⌫",
        "BSPC": "⌫",
        "DELETE": "⌦",
        "DEL": "⌦",
        "INSERT": "Ins",
        "INS": "Ins",
        
        // Whitespace
        "SPACE": "␣",
        "SPC": "␣",
        "ENTER": "⏎",
        "RETURN": "⏎",
        "RET": "⏎",
        "TAB": "⇥",
        "ESCAPE": "⎋",
        "ESC": "⎋",
        
        // Locks
        "CAPS": "⇪",
        "CAPSLOCK": "⇪",
        "CAPS_LOCK": "⇪",
        "CLCK": "⇪",
        "SCROLLLOCK": "ScrLk",
        "SCROLL_LOCK": "ScrLk",
        "SLCK": "ScrLk",
        "NUMLOCK": "NumLk",
        "NUM_LOCK": "NumLk",
        "NLCK": "NumLk",
        
        // Function keys (short form)
        "F1": "F1",
        "F2": "F2",
        "F3": "F3",
        "F4": "F4",
        "F5": "F5",
        "F6": "F6",
        "F7": "F7",
        "F8": "F8",
        "F9": "F9",
        "F10": "F10",
        "F11": "F11",
        "F12": "F12",
        "F13": "F13",
        "F14": "F14",
        "F15": "F15",
        "F16": "F16",
        "F17": "F17",
        "F18": "F18",
        "F19": "F19",
        "F20": "F20",
        "F21": "F21",
        "F22": "F22",
        "F23": "F23",
        "F24": "F24",
        
        // Numbers (keep as-is for numpad)
        "N0": "0",
        "N1": "1",
        "N2": "2",
        "N3": "3",
        "N4": "4",
        "N5": "5",
        "N6": "6",
        "N7": "7",
        "N8": "8",
        "N9": "9",
        "NUMBER_0": "0",
        "NUMBER_1": "1",
        "NUMBER_2": "2",
        "NUMBER_3": "3",
        "NUMBER_4": "4",
        "NUMBER_5": "5",
        "NUMBER_6": "6",
        "NUMBER_7": "7",
        "NUMBER_8": "8",
        "NUMBER_9": "9",
        
        // Numpad
        "KP_N0": "0",
        "KP_N1": "1",
        "KP_N2": "2",
        "KP_N3": "3",
        "KP_N4": "4",
        "KP_N5": "5",
        "KP_N6": "6",
        "KP_N7": "7",
        "KP_N8": "8",
        "KP_N9": "9",
        "KP_PLUS": "+",
        "KP_MINUS": "-",
        "KP_MULTIPLY": "*",
        "KP_DIVIDE": "/",
        "KP_DOT": ".",
        "KP_ENTER": "⏎",
        "KP_EQUAL": "=",
        
        // Media keys
        "C_PLAY_PAUSE": "⏯",
        "C_PP": "⏯",
        "C_PLAY": "▶",
        "C_PAUSE": "⏸",
        "C_STOP": "⏹",
        "C_NEXT": "⏭",
        "C_PREVIOUS": "⏮",
        "C_PREV": "⏮",
        "C_VOLUME_UP": "🔊",
        "C_VOL_UP": "🔊",
        "C_VOLUME_DOWN": "🔉",
        "C_VOL_DN": "🔉",
        "C_MUTE": "🔇",
        "C_BRIGHTNESS_INC": "🔆",
        "C_BRI_INC": "🔆",
        "C_BRI_UP": "🔆",
        "C_BRIGHTNESS_DEC": "🔅",
        "C_BRI_DEC": "🔅",
        "C_BRI_DN": "🔅",
        "C_EJECT": "⏏",
        
        // Power
        "C_POWER": "⏻",
        "C_PWR": "⏻",
        "C_SLEEP": "💤",
        
        // Screen
        "PRINTSCREEN": "PrtSc",
        "PRINT_SCREEN": "PrtSc",
        "PSCRN": "PrtSc",
        "SYSREQ": "SysRq",
        "PAUSE_BREAK": "Pause",
        "PAUSE": "Pause",
        
        // Application
        "K_APPLICATION": "☰",
        "K_APP": "☰",
        "K_CONTEXT_MENU": "☰",
        "K_CMENU": "☰",
        
        // Bluetooth (ZMK specific)
        "BT_CLR": "BT⌀",
        "BT_SEL": "BT",
        "BT_PRV": "BT←",
        "BT_NXT": "BT→",
        
        // Output (ZMK specific)
        "OUT_USB": "USB",
        "OUT_BLE": "BLE",
        "OUT_TOG": "Out⇄",
        
        // RGB (ZMK specific)
        "RGB_TOG": "RGB⏼",
        "RGB_HUI": "RGB H+",
        "RGB_HUD": "RGB H-",
        "RGB_SAI": "RGB S+",
        "RGB_SAD": "RGB S-",
        "RGB_BRI": "RGB B+",
        "RGB_BRD": "RGB B-",
        "RGB_EFF": "RGB →",
        "RGB_EFR": "RGB ←",
        
        // System
        "BOOTLOADER": "Boot",
        "RESET": "Reset",
        "SYS_RESET": "Reset",
        
        // Transparent / None
        "TRANS": "▽",
        "NONE": "",
        
        // Globe key (macOS)
        "GLOBE": "🌐",
    ]
    
    /// Convert a ZMK keycode to its display representation
    static func convert(_ keycode: String) -> String {
        // Try direct lookup first
        if let mapped = defaultMap[keycode] {
            return mapped
        }
        
        // Try uppercase
        if let mapped = defaultMap[keycode.uppercased()] {
            return mapped
        }
        
        // Handle single letters
        if keycode.count == 1 && keycode.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) }) {
            return keycode.uppercased()
        }
        
        // Handle known prefixes
        let prefixesToRemove = ["KP_", "K_", "C_", "NUMBER_", "KEYPAD_"]
        var cleanedCode = keycode
        for prefix in prefixesToRemove {
            if cleanedCode.hasPrefix(prefix) {
                cleanedCode = String(cleanedCode.dropFirst(prefix.count))
                break
            }
        }
        
        // Try again with cleaned code
        if let mapped = defaultMap[cleanedCode] {
            return mapped
        }
        
        // For unknown codes, clean up and return
        return cleanedCode.count <= 4 ? cleanedCode : String(cleanedCode.prefix(4))
    }
    
    /// Modifier symbols for displaying modifier combinations
    static let modifierSymbols: [String: String] = [
        "LC": "⌃",
        "RC": "⌃",
        "LCTRL": "⌃",
        "RCTRL": "⌃",
        "LS": "⇧",
        "RS": "⇧",
        "LSHIFT": "⇧",
        "RSHIFT": "⇧",
        "LA": "⌥",
        "RA": "⌥",
        "LALT": "⌥",
        "RALT": "⌥",
        "LG": "⌘",
        "RG": "⌘",
        "LGUI": "⌘",
        "RGUI": "⌘",
    ]
    
    /// Convert a modifier function like LC(V) to display form
    static func convertModifiedKey(_ modFn: String, _ key: String) -> String {
        if let modSymbol = modifierSymbols[modFn.uppercased()] {
            let keyDisplay = convert(key)
            return "\(modSymbol)\(keyDisplay)"
        }
        return "\(modFn)(\(key))"
    }
}
