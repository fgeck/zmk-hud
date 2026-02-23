import Foundation

enum KeymapParser {
    static func parse(from content: String) -> Keymap? {
        let cleanedContent = removeComments(from: content)
        
        guard let keymapSection = extractSection(named: "keymap", from: cleanedContent) else {
            return nil
        }
        
        let layers = parseLayers(from: keymapSection)
        let combos = parseCombos(from: cleanedContent)
        let behaviors = parseBehaviors(from: cleanedContent)
        
        return Keymap(layers: layers, combos: combos, behaviors: behaviors)
    }
    
    private static func removeComments(from content: String) -> String {
        var result = content
        
        let blockCommentPattern = #"/\*[\s\S]*?\*/"#
        if let regex = try? NSRegularExpression(pattern: blockCommentPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        
        let lineCommentPattern = #"//.*$"#
        if let regex = try? NSRegularExpression(pattern: lineCommentPattern, options: .anchorsMatchLines) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        
        return result
    }
    
    private static func extractSection(named name: String, from content: String) -> String? {
        let pattern = #"\b\#(name)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        guard let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        return String(content[range])
    }
    
    private static func parseLayers(from keymapSection: String) -> [Layer] {
        var layers: [Layer] = []
        
        let layerPattern = #"(\w+)\s*\{[^{}]*display-name\s*=\s*"([^"]+)"[^{}]*bindings\s*=\s*<([^>]+)>"#
        guard let regex = try? NSRegularExpression(pattern: layerPattern, options: .dotMatchesLineSeparators) else {
            return layers
        }
        
        let matches = regex.matches(in: keymapSection, range: NSRange(keymapSection.startIndex..., in: keymapSection))
        
        for match in matches {
            guard let nameRange = Range(match.range(at: 2), in: keymapSection),
                  let bindingsRange = Range(match.range(at: 3), in: keymapSection) else {
                continue
            }
            
            let name = String(keymapSection[nameRange])
            let bindingsString = String(keymapSection[bindingsRange])
            let bindings = parseBindings(from: bindingsString)
            
            layers.append(Layer(name: name, bindings: bindings))
        }
        
        return layers
    }
    
    private static func parseBindings(from bindingsString: String) -> [Binding] {
        var bindings: [Binding] = []
        
        let bindingPattern = #"&(\w+)(?:\s+([^&]+))?"#
        guard let regex = try? NSRegularExpression(pattern: bindingPattern) else {
            return bindings
        }
        
        let matches = regex.matches(in: bindingsString, range: NSRange(bindingsString.startIndex..., in: bindingsString))
        
        for match in matches {
            guard let behaviorRange = Range(match.range(at: 1), in: bindingsString) else {
                continue
            }
            
            let behavior = String(bindingsString[behaviorRange])
            var params: [String] = []
            
            if match.range(at: 2).location != NSNotFound,
               let paramsRange = Range(match.range(at: 2), in: bindingsString) {
                let paramsString = String(bindingsString[paramsRange]).trimmingCharacters(in: .whitespaces)
                params = paramsString.split(separator: " ").map(String.init)
            }
            
            let raw = "&\(behavior)" + (params.isEmpty ? "" : " " + params.joined(separator: " "))
            let binding = createBinding(behavior: behavior, params: params, raw: raw)
            bindings.append(binding)
        }
        
        return bindings
    }
    
    private static func createBinding(behavior: String, params: [String], raw: String) -> Binding {
        switch behavior {
        case "kp":
            let key = params.first ?? ""
            return Binding(type: .keyPress(key), raw: raw)
            
        case "lt":
            guard params.count >= 2, let layer = Int(params[0]) else {
                return Binding(type: .custom(raw), raw: raw)
            }
            return Binding(type: .layerTap(layer, params[1]), raw: raw)
            
        case "mo":
            guard let layer = Int(params.first ?? "") else {
                return Binding(type: .custom(raw), raw: raw)
            }
            return Binding(type: .layerMomentary(layer), raw: raw)
            
        case "mt":
            guard params.count >= 2 else {
                return Binding(type: .custom(raw), raw: raw)
            }
            return Binding(type: .modTap(params[0], params[1]), raw: raw)
            
        case "trans":
            return Binding(type: .transparent, raw: raw)
            
        case "none":
            return Binding(type: .none, raw: raw)
            
        default:
            if behavior.hasPrefix("td_") {
                return Binding(type: .tapDance(behavior), raw: raw)
            }
            if behavior.hasPrefix("hml") || behavior.hasPrefix("hmr") {
                guard params.count >= 2 else {
                    return Binding(type: .custom(raw), raw: raw)
                }
                return Binding(type: .holdTap(params[0], params[1]), raw: raw)
            }
            return Binding(type: .custom(raw), raw: raw)
        }
    }
    
    private static func parseCombos(from content: String) -> [Combo] {
        var combos: [Combo] = []
        
        guard let combosSection = extractSection(named: "combos", from: content) else {
            return combos
        }
        
        let comboPattern = #"(\w+)\s*\{[^{}]*key-positions\s*=\s*<([^>]+)>[^{}]*bindings\s*=\s*<([^>]+)>"#
        guard let regex = try? NSRegularExpression(pattern: comboPattern, options: .dotMatchesLineSeparators) else {
            return combos
        }
        
        let matches = regex.matches(in: combosSection, range: NSRange(combosSection.startIndex..., in: combosSection))
        
        for match in matches {
            guard let nameRange = Range(match.range(at: 1), in: combosSection),
                  let positionsRange = Range(match.range(at: 2), in: combosSection),
                  let bindingsRange = Range(match.range(at: 3), in: combosSection) else {
                continue
            }
            
            let name = String(combosSection[nameRange])
            let positionsString = String(combosSection[positionsRange])
            let positions = positionsString.split(separator: " ").compactMap { Int($0) }
            
            let bindingsString = String(combosSection[bindingsRange])
            let bindings = parseBindings(from: bindingsString)
            
            guard let result = bindings.first else { continue }
            
            combos.append(Combo(name: name, positions: positions, result: result, layers: nil, timeoutMs: nil))
        }
        
        return combos
    }
    
    private static func parseBehaviors(from content: String) -> [String: Behavior] {
        return [:]
    }
}
