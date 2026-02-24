import Foundation
import Yams

/// Configuration loaded from keymap_drawer.config.yaml.
/// Matches the full schema from Python keymap-drawer tool.
struct KeymapDrawerConfig: Codable {
    var parseConfig: ParseConfig?
    var drawConfig: DrawConfig?
    
    enum CodingKeys: String, CodingKey {
        case parseConfig = "parse_config"
        case drawConfig = "draw_config"
    }
    
    /// Default configuration
    static var `default`: KeymapDrawerConfig {
        KeymapDrawerConfig(
            parseConfig: ParseConfig(),
            drawConfig: DrawConfig()
        )
    }
}

// MARK: - Draw Config

struct DrawConfig: Codable {
    /// Key width in pixels (default: 60)
    var keyW: Double?
    
    /// Key height in pixels (default: 56)
    var keyH: Double?
    
    /// Gap between split halves (default: key_w / 2)
    var splitGap: Double?
    
    /// Combo box width (default: key_w / 2 - 2)
    var comboW: Double?
    
    /// Combo box height (default: key_h / 2 - 2)
    var comboH: Double?
    
    /// Curvature of rounded key rectangles X (default: 6)
    var keyRx: Double?
    
    /// Curvature of rounded key rectangles Y (default: 6)
    var keyRy: Double?
    
    /// Dark mode setting: true, false, or "auto"
    var darkMode: DarkModeSetting?
    
    /// Number of columns in output drawing (default: 1)
    var nColumns: Int?
    
    /// Draw separate combo diagrams instead of on layers
    var separateComboDiagrams: Bool?
    
    /// Scale factor for combo diagrams (default: 2)
    var comboDiagramsScale: Int?
    
    /// Horizontal padding between keys (default: 2)
    var innerPadW: Double?
    
    /// Vertical padding between keys (default: 2)
    var innerPadH: Double?
    
    /// Horizontal padding between layers
    var outerPadW: Double?
    
    /// Vertical padding between layers
    var outerPadH: Double?
    
    /// Spacing between multi-line text in key labels in units of em (default: 1.2)
    var lineSpacing: Double?
    
    /// Curve radius for combo dendrons (default: 6)
    var arcRadius: Double?
    
    /// Add colon after layer name in header (default: true)
    var appendColonToLayerHeader: Bool?
    
    /// Padding from edge of cap to top/bottom legends (default: 2)
    var smallPad: Double?
    
    /// Position of center legend relative to key center X
    var legendRelX: Double?
    
    /// Position of center legend relative to key center Y
    var legendRelY: Double?
    
    /// Draw key sides (3D effect)
    var drawKeySides: Bool?
    
    /// Key side parameters
    var keySidePars: KeySidePars?
    
    /// Extra CSS styles (used to extract colors)
    var svgExtraStyle: String?
    
    /// Footer text
    var footerText: String?
    
    /// Shrink font size for legends wider than this many chars (default: 7, 0 to disable)
    var shrinkWideLegends: Int?
    
    /// Add special styling for layer activator keys (default: true)
    var styleLayerActivators: Bool?
    
    /// Height in pixels for glyphs in tap field (default: 14)
    var glyphTapSize: Int?
    
    /// Height in pixels for glyphs in hold field (default: 12)
    var glyphHoldSize: Int?
    
    /// Height in pixels for glyphs in shifted field (default: 10)
    var glyphShiftedSize: Int?
    
    /// Mapping of glyph names to SVG definitions
    var glyphs: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case keyW = "key_w"
        case keyH = "key_h"
        case splitGap = "split_gap"
        case comboW = "combo_w"
        case comboH = "combo_h"
        case keyRx = "key_rx"
        case keyRy = "key_ry"
        case darkMode = "dark_mode"
        case nColumns = "n_columns"
        case separateComboDiagrams = "separate_combo_diagrams"
        case comboDiagramsScale = "combo_diagrams_scale"
        case innerPadW = "inner_pad_w"
        case innerPadH = "inner_pad_h"
        case outerPadW = "outer_pad_w"
        case outerPadH = "outer_pad_h"
        case lineSpacing = "line_spacing"
        case arcRadius = "arc_radius"
        case appendColonToLayerHeader = "append_colon_to_layer_header"
        case smallPad = "small_pad"
        case legendRelX = "legend_rel_x"
        case legendRelY = "legend_rel_y"
        case drawKeySides = "draw_key_sides"
        case keySidePars = "key_side_pars"
        case svgExtraStyle = "svg_extra_style"
        case footerText = "footer_text"
        case shrinkWideLegends = "shrink_wide_legends"
        case styleLayerActivators = "style_layer_activators"
        case glyphTapSize = "glyph_tap_size"
        case glyphHoldSize = "glyph_hold_size"
        case glyphShiftedSize = "glyph_shifted_size"
        case glyphs
    }
    
    // Default values matching keymap-drawer
    static var defaultKeyW: Double { 60 }
    static var defaultKeyH: Double { 56 }
    static var defaultSplitGap: Double { 30 }
    static var defaultComboW: Double { 28 }
    static var defaultComboH: Double { 26 }
    static var defaultInnerPadW: Double { 2 }
    static var defaultInnerPadH: Double { 2 }
    static var defaultKeyRx: Double { 6 }
    static var defaultKeyRy: Double { 6 }
}

/// Parameters for key side drawing (3D effect)
struct KeySidePars: Codable {
    var relX: Double?
    var relY: Double?
    var relW: Double?
    var relH: Double?
    var rx: Double?
    var ry: Double?
    
    enum CodingKeys: String, CodingKey {
        case relX = "rel_x"
        case relY = "rel_y"
        case relW = "rel_w"
        case relH = "rel_h"
        case rx, ry
    }
}

// MARK: - Parse Config

struct ParseConfig: Codable {
    /// Run C preprocessor on ZMK keymaps (default: true)
    var preprocess: Bool?
    
    /// Skip all binding parsing except raw_binding_map
    var skipBindingParsing: Bool?
    
    /// Map raw keycode/binding strings to display legends
    /// e.g. {"QK_BOOT": "BOOT", "&bootloader": "BOOT"}
    var rawBindingMap: [String: LegendValue]?
    
    /// Display text for sticky/one-shot keys (default: "sticky")
    var stickyLabel: String?
    
    /// Display text for toggled keys (default: "toggle")
    var toggleLabel: String?
    
    /// Display text for tap-toggle keys (default: "tap-toggle")
    var tapToggleLabel: String?
    
    /// Legend for transparent keys (default: {"t": "▽", "type": "trans"})
    var transLegend: LegendValue?
    
    /// Override layer names to specified legends
    var layerLegendMap: [String: String]?
    
    /// Mark all sequences to reach a layer as "held"
    var markAlternateLayerActivators: Bool?
    
    /// Modifier function mapping settings
    var modifierFnMap: ModifierFnMap?
    
    /// Prefixes to remove from QMK keycodes (default: ["KC_"])
    var qmkRemoveKeycodePrefix: [String]?
    
    /// Convert QMK keycodes to display forms
    var qmkKeycodeMap: [String: LegendValue]?
    
    /// Prefixes to remove from ZMK keycodes
    var zmkRemoveKeycodePrefix: [String]?
    
    /// Convert ZMK keycodes to display forms
    var zmkKeycodeMap: [String: LegendValue]?
    
    /// Additional combo fields for combo nodes
    var zmkCombos: [String: [String: AnyCodable]]?
    
    /// Preamble to prepend to ZMK keymaps
    var zmkPreamble: String?
    
    /// Additional ZMK include paths
    var zmkAdditionalIncludes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case preprocess
        case skipBindingParsing = "skip_binding_parsing"
        case rawBindingMap = "raw_binding_map"
        case stickyLabel = "sticky_label"
        case toggleLabel = "toggle_label"
        case tapToggleLabel = "tap_toggle_label"
        case transLegend = "trans_legend"
        case layerLegendMap = "layer_legend_map"
        case markAlternateLayerActivators = "mark_alternate_layer_activators"
        case modifierFnMap = "modifier_fn_map"
        case qmkRemoveKeycodePrefix = "qmk_remove_keycode_prefix"
        case qmkKeycodeMap = "qmk_keycode_map"
        case zmkRemoveKeycodePrefix = "zmk_remove_keycode_prefix"
        case zmkKeycodeMap = "zmk_keycode_map"
        case zmkCombos = "zmk_combos"
        case zmkPreamble = "zmk_preamble"
        case zmkAdditionalIncludes = "zmk_additional_includes"
    }
}

/// Modifier function mapping configuration
struct ModifierFnMap: Codable {
    var leftCtrl: String?
    var rightCtrl: String?
    var leftShift: String?
    var rightShift: String?
    var leftAlt: String?
    var rightAlt: String?
    var leftGui: String?
    var rightGui: String?
    var keycodeCombiner: String?
    var modCombiner: String?
    var specialCombinations: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case leftCtrl = "left_ctrl"
        case rightCtrl = "right_ctrl"
        case leftShift = "left_shift"
        case rightShift = "right_shift"
        case leftAlt = "left_alt"
        case rightAlt = "right_alt"
        case leftGui = "left_gui"
        case rightGui = "right_gui"
        case keycodeCombiner = "keycode_combiner"
        case modCombiner = "mod_combiner"
        case specialCombinations = "special_combinations"
    }
}

// MARK: - Legend Value

/// A legend can be a simple string or a complex object with tap/hold/shifted values.
enum LegendValue: Codable, Equatable {
    case string(String)
    case complex(LegendSpec)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            let spec = try container.decode(LegendSpec.self)
            self = .complex(spec)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .complex(let spec):
            try container.encode(spec)
        }
    }
    
    /// Get the tap label
    var tap: String? {
        switch self {
        case .string(let value):
            return value
        case .complex(let spec):
            return spec.t
        }
    }
    
    /// Get the hold label
    var hold: String? {
        switch self {
        case .string:
            return nil
        case .complex(let spec):
            return spec.h
        }
    }
    
    /// Get the shifted/double-tap label
    var shifted: String? {
        switch self {
        case .string:
            return nil
        case .complex(let spec):
            return spec.s
        }
    }
    
    /// Get the type (e.g., "trans", "ghost", "held")
    var type: String? {
        switch self {
        case .string:
            return nil
        case .complex(let spec):
            return spec.type
        }
    }
}

/// Complex legend specification with multiple fields
struct LegendSpec: Codable, Equatable {
    /// Tap label (center)
    var t: String?
    
    /// Hold label (bottom)
    var h: String?
    
    /// Shifted/double-tap label (top)
    var s: String?
    
    /// Key type (e.g., "trans", "ghost", "held")
    var type: String?
    
    /// Top-left label
    var tl: String?
    
    /// Top-right label
    var tr: String?
    
    /// Bottom-left label
    var bl: String?
    
    /// Bottom-right label
    var br: String?
    
    /// Left label
    var left: String?
    
    /// Right label
    var right: String?
}

// MARK: - Dark Mode Setting

enum DarkModeSetting: Codable, Equatable {
    case enabled
    case disabled
    case auto
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .enabled : .disabled
        } else if let stringValue = try? container.decode(String.self) {
            self = stringValue.lowercased() == "auto" ? .auto : .disabled
        } else {
            self = .auto
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enabled:
            try container.encode(true)
        case .disabled:
            try container.encode(false)
        case .auto:
            try container.encode("auto")
        }
    }
}

// MARK: - AnyCodable (for flexible dictionary values)

/// Type-erased Codable wrapper for flexible YAML parsing
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode value"))
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Config Loader

struct KeymapDrawerConfigLoader {
    
    /// Load configuration from a YAML file path.
    static func load(fromPath path: String) throws -> KeymapDrawerConfig {
        let url = URL(fileURLWithPath: path)
        return try load(from: url)
    }
    
    /// Load configuration from a URL.
    static func load(from url: URL) throws -> KeymapDrawerConfig {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }
    
    /// Load configuration from YAML data.
    static func load(from data: Data) throws -> KeymapDrawerConfig {
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw ConfigError.invalidEncoding
        }
        let decoder = YAMLDecoder()
        return try decoder.decode(KeymapDrawerConfig.self, from: yamlString)
    }
    
    /// Load configuration from a YAML string.
    static func load(fromYAML yamlString: String) throws -> KeymapDrawerConfig {
        let decoder = YAMLDecoder()
        return try decoder.decode(KeymapDrawerConfig.self, from: yamlString)
    }
    
    /// Load from a GitHub raw URL (async).
    static func load(fromGitHubURL urlString: String) async throws -> KeymapDrawerConfig {
        let normalizedURL = normalizeGitHubURL(urlString)
        guard let url = URL(string: normalizedURL) else {
            throw ConfigError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try load(from: data)
    }
    
    /// Normalize GitHub blob URLs to raw URLs.
    private static func normalizeGitHubURL(_ urlString: String) -> String {
        if urlString.contains("github.com") && urlString.contains("/blob/") {
            return urlString
                .replacingOccurrences(of: "github.com", with: "raw.githubusercontent.com")
                .replacingOccurrences(of: "/blob/", with: "/")
        }
        return urlString
    }
    
    enum ConfigError: Error, LocalizedError {
        case invalidEncoding
        case invalidURL
        case parsingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidEncoding:
                return "Invalid file encoding (expected UTF-8)"
            case .invalidURL:
                return "Invalid URL format"
            case .parsingFailed(let message):
                return "Failed to parse config: \(message)"
            }
        }
    }
}
