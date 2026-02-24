import Foundation

enum KeymapParser {
    static func parse(from content: String) -> Keymap? {
        let cleanedContent = removeComments(from: content)
        
        guard let keymapSection = findKeymapSection(in: cleanedContent) else {
            return nil
        }
        
        var keymapContent = keymapSection
        if let firstBrace = keymapContent.firstIndex(of: "{"),
           let lastBrace = keymapContent.lastIndex(of: "}") {
            let start = keymapContent.index(after: firstBrace)
            if start < lastBrace {
                keymapContent = String(keymapContent[start..<lastBrace])
            }
        }
        
        let (layers, rowStructure) = parseLayers(from: keymapContent)
        let combos = parseCombos(from: cleanedContent)
        let behaviors = parseBehaviors(from: cleanedContent)
        
        guard !layers.isEmpty else { return nil }
        
        return Keymap(layers: layers, combos: combos, behaviors: behaviors, rowStructure: rowStructure)
    }
    
    private static func removeComments(from data: String) -> String {
        var result = ""
        var i = data.startIndex
        
        while i < data.endIndex {
            let nextI = data.index(after: i)
            
            if i < data.index(data.endIndex, offsetBy: -1, limitedBy: data.startIndex) ?? data.endIndex &&
               data[i] == "/" && data[nextI] == "/" {
                while i < data.endIndex && data[i] != "\n" {
                    i = data.index(after: i)
                }
                if i < data.endIndex {
                    result.append("\n")
                    i = data.index(after: i)
                }
                continue
            }
            
            if i < data.index(data.endIndex, offsetBy: -1, limitedBy: data.startIndex) ?? data.endIndex &&
               data[i] == "/" && data[nextI] == "*" {
                i = data.index(after: nextI)
                while i < data.index(data.endIndex, offsetBy: -1, limitedBy: data.startIndex) ?? data.endIndex {
                    if data[i] == "*" && data[data.index(after: i)] == "/" {
                        i = data.index(after: data.index(after: i))
                        break
                    }
                    if data[i] == "\n" {
                        result.append("\n")
                    }
                    i = data.index(after: i)
                }
                continue
            }
            
            result.append(data[i])
            i = data.index(after: i)
        }
        
        return result
    }
    
    private static func findKeymapSection(in data: String) -> String? {
        guard let keymapStart = data.range(of: "keymap\\s*\\{", options: .regularExpression) else {
            return nil
        }
        
        var braceCount = 0
        var foundFirst = false
        var endIndex = keymapStart.upperBound
        
        for i in data.indices[keymapStart.lowerBound...] {
            let char = data[i]
            if char == "{" {
                braceCount += 1
                foundFirst = true
            } else if char == "}" {
                braceCount -= 1
                if foundFirst && braceCount == 0 {
                    endIndex = data.index(after: i)
                    break
                }
            }
        }
        
        return String(data[keymapStart.lowerBound..<endIndex])
    }
    
    private static func parseLayers(from keymapContent: String) -> ([Layer], [Int]?) {
        var layers: [Layer] = []
        var rowStructure: [Int]? = nil
        
        let layerPattern = "(\\w+)\\s*\\{([^}]*?)bindings\\s*=\\s*<(.*?)>\\s*;"
        guard let regex = try? NSRegularExpression(pattern: layerPattern, options: [.dotMatchesLineSeparators]) else {
            return (layers, nil)
        }
        
        let nsContent = keymapContent as NSString
        let matches = regex.matches(in: keymapContent, options: [], range: NSRange(location: 0, length: nsContent.length))
        
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            
            let layerId = nsContent.substring(with: match.range(at: 1))
            let preBindingsContent = nsContent.substring(with: match.range(at: 2))
            let bindingsRaw = nsContent.substring(with: match.range(at: 3))
            
            var layerName = layerId
            let labelPattern = "(?:label|display-name)\\s*=\\s*\"([^\"]*)\""
            if let labelRegex = try? NSRegularExpression(pattern: labelPattern, options: []),
               let labelMatch = labelRegex.firstMatch(in: preBindingsContent, options: [], range: NSRange(location: 0, length: preBindingsContent.count)) {
                layerName = (preBindingsContent as NSString).substring(with: labelMatch.range(at: 1))
            }
            
            let bindings = parseBindings(from: bindingsRaw)
            layers.append(Layer(name: layerName, bindings: bindings))
            
            if rowStructure == nil {
                rowStructure = extractRowStructure(from: bindingsRaw)
            }
        }
        
        return (layers, rowStructure)
    }
    
    private static func extractRowStructure(from bindingsRaw: String) -> [Int]? {
        let lines = bindingsRaw.components(separatedBy: "\n")
        var rowCounts: [Int] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            let bindingCount = countBindingsInLine(trimmed)
            if bindingCount > 0 {
                rowCounts.append(bindingCount)
            }
        }
        
        if rowCounts.isEmpty {
            return nil
        }
        
        return rowCounts
    }
    
    private static func countBindingsInLine(_ line: String) -> Int {
        var count = 0
        var i = line.startIndex
        
        while i < line.endIndex {
            if line[i] == "&" {
                count += 1
            }
            i = line.index(after: i)
        }
        
        return count
    }
    
    private static func parseBindings(from bindingsRaw: String) -> [Binding] {
        var bindings: [Binding] = []
        let tokens = tokenizeBindings(bindingsRaw)
        
        for token in tokens {
            let binding = createBinding(from: token)
            bindings.append(binding)
        }
        
        return bindings
    }
    
    private static func tokenizeBindings(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var parenDepth = 0
        
        for char in input {
            if char == "&" {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(trimmed)
                }
                current = "&"
            } else if char == "(" {
                parenDepth += 1
                current.append(char)
            } else if char == ")" {
                parenDepth -= 1
                current.append(char)
            } else {
                current.append(char)
            }
        }
        
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            tokens.append(trimmed)
        }
        
        return tokens
    }
    
    private static func createBinding(from rawCode: String) -> Binding {
        let code = rawCode.hasPrefix("&") ? String(rawCode.dropFirst()) : rawCode
        let parts = code.split(separator: " ", omittingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        guard !parts.isEmpty else {
            return Binding(type: .custom(rawCode), raw: rawCode)
        }
        
        let behavior = parts[0]
        
        switch behavior {
        case "kp":
            let key = parts.count > 1 ? parts[1] : ""
            return Binding(type: .keyPress(formatKey(key)), raw: rawCode)
            
        case "sk":  // Sticky key - show as "Sticky ⌘" etc.
            let mod = parts.count > 1 ? parts[1] : ""
            let modSymbol = formatModifier(mod)
            return Binding(type: .keyPress("Sticky " + modSymbol), raw: rawCode)
            
        case "lt":
            guard parts.count >= 3, let layer = Int(parts[1]) else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .layerTap(layer, formatKey(parts[2])), raw: rawCode)
            
        case "mo":
            guard parts.count >= 2, let layer = Int(parts[1]) else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .layerMomentary(layer), raw: rawCode)
            
        case "mt":
            guard parts.count >= 3 else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .modTap(formatModifier(parts[1]), formatKey(parts[2])), raw: rawCode)
            
        case "trans":
            return Binding(type: .transparent, raw: rawCode)
            
        case "none":
            return Binding(type: .none, raw: rawCode)
            
        // Caps Word behavior
        case "caps_word":
            return Binding(type: .capsWord, raw: rawCode)
            
        // Key Repeat behavior
        case "key_repeat":
            return Binding(type: .keyRepeat, raw: rawCode)
            
        // Sticky layer
        case "sl":
            guard parts.count >= 2, let layer = Int(parts[1]) else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .stickyLayer(layer), raw: rawCode)
            
        // Toggle layer
        case "tog":
            guard parts.count >= 2, let layer = Int(parts[1]) else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .toggleLayer(layer), raw: rawCode)
            
        // To layer (switch to layer)
        case "to":
            guard parts.count >= 2, let layer = Int(parts[1]) else {
                return Binding(type: .custom(rawCode), raw: rawCode)
            }
            return Binding(type: .toLayer(layer), raw: rawCode)
            
        // Bootloader
        case "bootloader":
            return Binding(type: .bootloader, raw: rawCode)
            
        // Reset / sys_reset
        case "sys_reset", "reset":
            return Binding(type: .reset, raw: rawCode)
            
        // Bluetooth behaviors
        case "bt":
            // Join all parameters after 'bt' (e.g., "BT_SEL 0" -> "BT_SEL 0")
            let action = parts.dropFirst().joined(separator: " ")
            return Binding(type: .bluetooth(action), raw: rawCode)
            
        // Output selection (USB/BLE)
        case "out":
            let output = parts.count > 1 ? parts[1] : ""
            return Binding(type: .outputSelect(output), raw: rawCode)

        default:
            // Tap-dance behaviors
            if behavior.hasPrefix("td_") || behavior.hasPrefix("TD_") {
                return Binding(type: .tapDance(behavior), raw: rawCode)
            }
            
            // Nav behaviors (nav_left, nav_right, nav_up, nav_down, nav_bspc, nav_del)
            if behavior.hasPrefix("nav_") {
                if parts.count >= 3 {
                    let holdKey = parts[1]  // e.g., LG(LEFT)
                    let tapKey = parts[2]   // e.g., LEFT
                    return Binding(type: .holdTap(formatKey(holdKey), formatKey(tapKey)), raw: rawCode)
                }
            }
            
            // Home-row mods (hml, hmr, hml_td_a, hmr_td_semi, etc.)
            if behavior.lowercased().contains("hm") || behavior.lowercased().contains("mt") {
                if parts.count >= 3 {
                    // Check if behavior name contains embedded tap-dance (e.g., hml_td_a, hmr_td_semi)
                    let tapLabel: String
                    if let tdRange = behavior.range(of: "td_", options: .caseInsensitive) {
                        // Extract the tap-dance name from behavior (e.g., "td_a" from "hml_td_a")
                        let tdName = String(behavior[tdRange.lowerBound...])
                        tapLabel = formatTapDanceLabel(tdName)
                    } else {
                        tapLabel = formatKey(parts[2])
                    }
                    return Binding(type: .holdTap(formatModifier(parts[1]), tapLabel), raw: rawCode)
                }
            }
            
            // Layer-tap variants
            if behavior.lowercased().contains("lt") {
                if parts.count >= 3, let layer = Int(parts[1]) {
                    return Binding(type: .layerTap(layer, formatKey(parts[2])), raw: rawCode)
                }
            }
            
            return Binding(type: .custom(rawCode), raw: rawCode)
        }
    }
    
    private static func parseCombos(from content: String) -> [Combo] {
        var combos: [Combo] = []
        guard var combosSection = findCombosSection(in: content) else {
            return combos
        }
        
        if let firstBrace = combosSection.firstIndex(of: "{"),
           let lastBrace = combosSection.lastIndex(of: "}") {
            let start = combosSection.index(after: firstBrace)
            if start < lastBrace {
                combosSection = String(combosSection[start..<lastBrace])
            }
        }
        let comboBlockPattern = "(\\w+)\\s*\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: comboBlockPattern, options: [.dotMatchesLineSeparators]) else {
            return combos
        }
        
        let nsSection = combosSection as NSString
        let matches = regex.matches(in: combosSection, options: [], range: NSRange(location: 0, length: nsSection.length))
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let name = nsSection.substring(with: match.range(at: 1))
            let block = nsSection.substring(with: match.range(at: 2))
            
            if name == "compatible" { continue }
            
            guard let positions = extractKeyPositions(from: block),
                  let binding = extractBinding(from: block) else {
                continue
            }
            
            let layers = extractLayers(from: block)
            let timeout = extractTimeout(from: block)
            
            combos.append(Combo(name: name, positions: positions, result: binding, layers: layers, timeoutMs: timeout))
        }
        
        return combos
    }
    
    private static func findCombosSection(in data: String) -> String? {
        guard let combosStart = data.range(of: "combos\\s*\\{", options: .regularExpression) else {
            return nil
        }
        
        var braceCount = 0
        var foundFirst = false
        var endIndex = combosStart.upperBound
        
        for i in data.indices[combosStart.lowerBound...] {
            let char = data[i]
            if char == "{" {
                braceCount += 1
                foundFirst = true
            } else if char == "}" {
                braceCount -= 1
                if foundFirst && braceCount == 0 {
                    endIndex = data.index(after: i)
                    break
                }
            }
        }
        
        return String(data[combosStart.lowerBound..<endIndex])
    }
    
    private static func extractKeyPositions(from block: String) -> [Int]? {
        let pattern = "key-positions\\s*=\\s*<([^>]+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let range = Range(match.range(at: 1), in: block) else {
            return nil
        }
        
        let positionsString = String(block[range])
        let positions = positionsString.split(separator: " ").compactMap { Int($0) }
        return positions.isEmpty ? nil : positions
    }
    
    private static func extractBinding(from block: String) -> Binding? {
        let pattern = "bindings\\s*=\\s*<([^>]+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let range = Range(match.range(at: 1), in: block) else {
            return nil
        }
        
        let bindingString = String(block[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return createBinding(from: bindingString)
    }
    
    private static func extractLayers(from block: String) -> [Int]? {
        let pattern = "layers\\s*=\\s*<([^>]+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let range = Range(match.range(at: 1), in: block) else {
            return nil
        }
        
        let layersString = String(block[range])
        let layers = layersString.split(separator: " ").compactMap { Int($0) }
        return layers.isEmpty ? nil : layers
    }
    
    private static func extractTimeout(from block: String) -> Int? {
        let pattern = "timeout-ms\\s*=\\s*<(\\d+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
              let range = Range(match.range(at: 1), in: block) else {
            return nil
        }
        
        return Int(String(block[range]))
    }
    
    private static func parseBehaviors(from content: String) -> [String: Behavior] {
        var behaviors: [String: Behavior] = [:]
        
        // Find behaviors section
        guard let behaviorsSection = findBehaviorsSection(in: content) else {
            return behaviors
        }
        
        // Parse individual behavior blocks
        let behaviorBlockPattern = "(\\w+)\\s*:\\s*(\\w+)\\s*\\{([^}]+)\\}"
        guard let regex = try? NSRegularExpression(pattern: behaviorBlockPattern, options: [.dotMatchesLineSeparators]) else {
            return behaviors
        }
        
        let nsContent = behaviorsSection as NSString
        let matches = regex.matches(in: behaviorsSection, options: [], range: NSRange(location: 0, length: nsContent.length))
        
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            
            let name = nsContent.substring(with: match.range(at: 1))
            _ = nsContent.substring(with: match.range(at: 2))  // label (e.g., hml: hml)
            let block = nsContent.substring(with: match.range(at: 3))
            
            // Extract compatible type
            var behaviorType = "unknown"
            if let compatibleRange = block.range(of: "compatible\\s*=\\s*\"([^\"]+)\"", options: .regularExpression) {
                let compatibleStr = String(block[compatibleRange])
                if let typeStart = compatibleStr.firstIndex(of: "\""),
                   let typeEnd = compatibleStr.lastIndex(of: "\"") {
                    let start = compatibleStr.index(after: typeStart)
                    if start < typeEnd {
                        behaviorType = String(compatibleStr[start..<typeEnd])
                    }
                }
            }
            
            // Extract bindings if present
            var bindings: [String] = []
            if let bindingsRange = block.range(of: "bindings\\s*=\\s*<([^>]+)>", options: .regularExpression) {
                let bindingsStr = String(block[bindingsRange])
                if let start = bindingsStr.firstIndex(of: "<"),
                   let end = bindingsStr.lastIndex(of: ">") {
                    let innerStart = bindingsStr.index(after: start)
                    if innerStart < end {
                        let inner = String(bindingsStr[innerStart..<end])
                        bindings = inner.components(separatedBy: " ").filter { !$0.isEmpty }
                    }
                }
            }
            
            behaviors[name] = Behavior(name: name, type: behaviorType, bindings: bindings)
        }
        
        return behaviors
    }
    
    private static func findBehaviorsSection(in data: String) -> String? {
        guard let behaviorsStart = data.range(of: "behaviors\\s*\\{", options: .regularExpression) else {
            return nil
        }
        
        var braceCount = 0
        var foundFirst = false
        var endIndex = behaviorsStart.upperBound
        
        for i in data.indices[behaviorsStart.lowerBound...] {
            let char = data[i]
            if char == "{" {
                braceCount += 1
                foundFirst = true
            } else if char == "}" {
                braceCount -= 1
                if foundFirst && braceCount == 0 {
                    endIndex = data.index(after: i)
                    break
                }
            }
        }
        
        return String(data[behaviorsStart.lowerBound..<endIndex])
    }
    
    private static func formatTapDanceLabel(_ name: String) -> String {
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
    

    private static func formatKey(_ key: String) -> String {
        // Handle modified keys like LG(C) -> Copy, LG(V) -> Paste, etc.
        let clipboardShortcuts: [String: String] = [
            "LG(C)": "Copy", "LG(V)": "Paste", "LG(X)": "Cut",
            "LG(Z)": "Undo", "LG(LS(Z))": "Redo",
            "LC(C)": "Copy", "LC(V)": "Paste", "LC(X)": "Cut",
            "LC(Z)": "Undo", "LC(LS(Z))": "Redo"
        ]
        
        if let shortcut = clipboardShortcuts[key] {
            return shortcut
        }
        
        // Handle modified keys like LG(LEFT) -> ⌘←
        if key.contains("(") && key.contains(")") {
            if let startParen = key.firstIndex(of: "("),
               let endParen = key.lastIndex(of: ")") {
                let modPart = String(key[..<startParen])
                let keyPart = String(key[key.index(after: startParen)..<endParen])
                let formattedMod = formatModifier(modPart)
                let formattedKey = formatKey(keyPart)  // Recursive call for nested keys
                return "\(formattedMod)\(formattedKey)"
            }
        }
        
        let specialKeys: [String: String] = [
            // Navigation
            "BACKSPACE": "⌫", "BSPC": "⌫",
            "SPACE": "␣", "SPC": "␣",
            "TAB": "⇥",
            "RETURN": "⏎", "RET": "⏎", "ENTER": "⏎",
            "ESCAPE": "Esc", "ESC": "Esc",
            "DELETE": "Del", "DEL": "Del",
            "LEFT": "←", "RIGHT": "→", "UP": "↑", "DOWN": "↓",
            "PG_UP": "PgUp", "PAGE_UP": "PgUp",
            "PG_DN": "PgDn", "PAGE_DOWN": "PgDn",
            "HOME": "Home", "END": "End",
            "INS": "Ins", "INSERT": "Ins",
            
            // Punctuation
            "SEMICOLON": ";", "SEMI": ";",
            "COMMA": ",", "DOT": ".", "PERIOD": ".",
            "SLASH": "/", "FSLH": "/",
            "BACKSLASH": "\\", "BSLH": "\\",
            "MINUS": "-", "EQUAL": "=", "PLUS": "+",
            "LBKT": "[", "LEFT_BRACKET": "[",
            "RBKT": "]", "RIGHT_BRACKET": "]",
            "LBRC": "{", "RBRC": "}",
            "LPAR": "(", "RPAR": ")",
            "SQT": "'", "SINGLE_QUOTE": "'", "APOS": "'", "APOSTROPHE": "'",
            "DQT": "\"", "DOUBLE_QUOTES": "\"",
            "GRAVE": "`", "TILDE": "~",
            "EXCLAMATION": "!", "EXCL": "!",
            "AT_SIGN": "@", "AT": "@",
            "HASH": "#", "POUND": "#",
            "DLLR": "$", "DOLLAR": "$",
            "PRCNT": "%", "PERCENT": "%",
            "CARET": "^",
            "AMPS": "&", "AMPERSAND": "&",
            "STAR": "*", "ASTRK": "*",
            "UNDER": "_", "UNDERSCORE": "_",
            "PIPE": "|",
            "QMARK": "?", "QUESTION": "?",
            "LT": "<", "LESS_THAN": "<",
            "GT": ">", "GREATER_THAN": ">",
            
            // Numbers
            "N0": "0", "N1": "1", "N2": "2", "N3": "3", "N4": "4",
            "N5": "5", "N6": "6", "N7": "7", "N8": "8", "N9": "9",
            
            // Media controls - match keymap_drawer style
            "C_VOL_UP": "Vol+", "C_VOLUME_UP": "Vol+",
            "C_VOL_DN": "Vol-", "C_VOLUME_DOWN": "Vol-",
            "C_MUTE": "Mute",
            "C_NEXT": "Next", "C_PREV": "Prev",
            "C_PP": "Play", "C_PLAY_PAUSE": "Play",
            "C_STOP": "Stop",
            
            // Brightness
            "C_BRI_UP": "Bri+", "C_BRIGHTNESS_INC": "Bri+",
            "C_BRI_DN": "Bri-", "C_BRIGHTNESS_DEC": "Bri-",
            
            // Power
            "C_PWR": "Pwr", "C_POWER": "Pwr"
        ]
        
        let upperKey = key.uppercased()
        if let special = specialKeys[upperKey] {
            return special
        }
        
        return upperKey
    }
    
    private static func formatModifier(_ mod: String) -> String {
        let modMap: [String: String] = [
            "LEFT_SHIFT": "⇧", "LSHIFT": "⇧", "LSHFT": "⇧", "LS": "⇧",
            "RIGHT_SHIFT": "⇧", "RSHIFT": "⇧", "RSHFT": "⇧", "RS": "⇧",
            "LEFT_CONTROL": "⌃", "LCTRL": "⌃", "LC": "⌃",
            "RIGHT_CONTROL": "⌃", "RCTRL": "⌃", "RC": "⌃",
            "LEFT_ALT": "⌥", "LALT": "⌥", "LA": "⌥",
            "RIGHT_ALT": "⌥", "RALT": "⌥", "RA": "⌥",
            "LEFT_GUI": "⌘", "LGUI": "⌘", "LG": "⌘",
            "RIGHT_GUI": "⌘", "RGUI": "⌘", "RG": "⌘"
        ]
        
        return modMap[mod.uppercased()] ?? mod
    }
}
