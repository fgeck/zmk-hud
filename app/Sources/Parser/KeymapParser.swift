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
            
        default:
            if behavior.hasPrefix("td_") || behavior.hasPrefix("TD_") {
                return Binding(type: .tapDance(behavior), raw: rawCode)
            }
            if behavior.lowercased().contains("hm") || behavior.lowercased().contains("mt") {
                if parts.count >= 3 {
                    return Binding(type: .holdTap(formatModifier(parts[1]), formatKey(parts[2])), raw: rawCode)
                }
            }
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
        return [:]
    }
    
    private static func formatKey(_ key: String) -> String {
        let specialKeys: [String: String] = [
            "BACKSPACE": "⌫", "BSPC": "⌫",
            "SPACE": "␣", "SPC": "␣",
            "TAB": "⇥",
            "RETURN": "⏎", "RET": "⏎", "ENTER": "⏎",
            "ESCAPE": "ESC", "ESC": "ESC",
            "DELETE": "DEL", "DEL": "DEL",
            "LEFT": "←", "RIGHT": "→", "UP": "↑", "DOWN": "↓",
            "SEMICOLON": ";", "SEMI": ";",
            "COMMA": ",", "DOT": ".", "PERIOD": ".",
            "SLASH": "/", "FSLH": "/",
            "BACKSLASH": "\\", "BSLH": "\\",
            "MINUS": "-", "EQUAL": "=", "PLUS": "+",
            "LBKT": "[", "LEFT_BRACKET": "[",
            "RBKT": "]", "RIGHT_BRACKET": "]",
            "LBRC": "{", "RBRC": "}",
            "LPAR": "(", "RPAR": ")",
            "SQT": "'", "SINGLE_QUOTE": "'",
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
            "N0": "0", "N1": "1", "N2": "2", "N3": "3", "N4": "4",
            "N5": "5", "N6": "6", "N7": "7", "N8": "8", "N9": "9"
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
