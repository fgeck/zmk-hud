import Foundation

struct Keymap {
    var layers: [Layer]
    var combos: [Combo]
    var behaviors: [String: Behavior]
    var rowStructure: [Int]?
}

struct Layer {
    var name: String
    var bindings: [Binding]
}

struct Binding {
    enum BindingType {
        case keyPress(String)
        case layerTap(Int, String)
        case layerMomentary(Int)
        case modTap(String, String)
        case holdTap(String, String)
        case tapDance(String)
        case transparent
        case none
        case custom(String)
    }
    
    var type: BindingType
    var raw: String
    
    var displayLabel: String {
        switch type {
        case .keyPress(let key):
            return key
        case .layerTap(_, let key):
            return key
        case .layerMomentary(let layer):
            return "L\(layer)"
        case .modTap(_, let tap):
            return tap
        case .holdTap(_, let tap):
            return tap
        case .tapDance(let name):
            return name
        case .transparent:
            return ""
        case .none:
            return ""
        case .custom(let raw):
            return raw
        }
    }
    
    var holdLabel: String? {
        switch type {
        case .modTap(let mod, _):
            return mod
        case .holdTap(let hold, _):
            return hold
        case .layerTap(let layer, _):
            return "L\(layer)"
        default:
            return nil
        }
    }
}

struct Combo {
    var name: String
    var positions: [Int]
    var result: Binding
    var layers: [Int]?
    var timeoutMs: Int?
}

struct Behavior {
    var name: String
    var type: String
    var bindings: [String]
}
