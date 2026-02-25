import Foundation

/// Parses QMK info.json format into PhysicalLayout.
/// Ported from keymap-drawer's QmkLayout class.
///
/// QMK format defines keys with:
/// - `x`, `y`: Top-left corner in key units (1u = one key width)
/// - `w`, `h`: Width/height in key units (default 1.0)
/// - `r`: Rotation in degrees (clockwise positive)
/// - `rx`, `ry`: Rotation origin in key units (defaults to x, y)
struct QMKLayoutParser {
    
    /// Parse a QMK info.json format string into a PhysicalLayout.
    ///
    /// - Parameters:
    ///   - json: JSON string containing layout data
    ///   - keySize: Scale factor (pixels per key unit), typically 56
    ///   - layoutName: Optional specific layout name to select
    /// - Returns: PhysicalLayout or nil if parsing fails
    static func parse(json: String, keySize: Double = 56, layoutName: String? = nil) -> PhysicalLayout? {
        guard let data = json.data(using: .utf8) else { return nil }
        return parse(data: data, keySize: keySize, layoutName: layoutName)
    }
    
    /// Parse QMK info.json data into a PhysicalLayout.
    static func parse(data: Data, keySize: Double = 56, layoutName: String? = nil) -> PhysicalLayout? {
        // Try parsing as dictionary first
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parse(json: json, keySize: keySize, layoutName: layoutName)
        }
        // Format 3: Direct array [...] at root level
        if let directArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return parseKeys(directArray, keySize: keySize)
        }
        return nil
    }
    
    /// Parse QMK info.json dictionary into a PhysicalLayout.
    static func parse(json: [String: Any], keySize: Double = 56, layoutName: String? = nil) -> PhysicalLayout? {
        // Try to find the layout array
        var layoutArray: [[String: Any]]?
        
        // Format 1: {"layouts": {"LAYOUT_name": {"layout": [...]}}}
        if let layouts = json["layouts"] as? [String: Any] {
            if let name = layoutName,
               let specificLayout = layouts[name] as? [String: Any],
               let layout = specificLayout["layout"] as? [[String: Any]] {
                layoutArray = layout
            } else if let firstLayout = layouts.values.first as? [String: Any],
                      let layout = firstLayout["layout"] as? [[String: Any]] {
                layoutArray = layout
            }
        }
        // Format 2: {"layout": [...]}
        else if let layout = json["layout"] as? [[String: Any]] {
            layoutArray = layout
        }
        // Format 3 (direct array) is handled in parse(data:) above
        
        guard let keys = layoutArray else { return nil }
        
        return parseKeys(keys, keySize: keySize)
    }
    
    /// Parse an array of key definitions into a PhysicalLayout.
    private static func parseKeys(_ keys: [[String: Any]], keySize: Double) -> PhysicalLayout {
        var physicalKeys: [PhysicalKey] = []
        
        for (index, key) in keys.enumerated() {
            let x = (key["x"] as? Double) ?? (key["x"] as? Int).map(Double.init) ?? 0
            let y = (key["y"] as? Double) ?? (key["y"] as? Int).map(Double.init) ?? 0
            let w = (key["w"] as? Double) ?? (key["w"] as? Int).map(Double.init) ?? 1.0
            let h = (key["h"] as? Double) ?? (key["h"] as? Int).map(Double.init) ?? 1.0
            let r = (key["r"] as? Double) ?? (key["r"] as? Int).map(Double.init) ?? 0
            let rx = (key["rx"] as? Double) ?? (key["rx"] as? Int).map(Double.init)
            let ry = (key["ry"] as? Double) ?? (key["ry"] as? Int).map(Double.init)
            
            let topLeft = Point(x: x, y: y)
            let rotationOrigin: Point? = (rx != nil || ry != nil) 
                ? Point(x: rx ?? x, y: ry ?? y)
                : nil
            
            let physicalKey = PhysicalKey.fromQMKSpec(
                id: index,
                scale: keySize,
                topLeft: topLeft,
                width: w,
                height: h,
                rotation: r,
                rotationOrigin: rotationOrigin
            )
            
            physicalKeys.append(physicalKey)
        }
        
        return PhysicalLayout(keys: physicalKeys).normalized()
    }
    
    /// Load layout from a file path.
    static func load(from path: String, keySize: Double = 56, layoutName: String? = nil) -> PhysicalLayout? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return parse(data: data, keySize: keySize, layoutName: layoutName)
    }
    
    /// Load layout from a URL (async).
    static func load(from url: URL, keySize: Double = 56, layoutName: String? = nil) async -> PhysicalLayout? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return parse(data: data, keySize: keySize, layoutName: layoutName)
        } catch {
            return nil
        }
    }
    
    /// Get available layout names from a QMK info.json.
    static func availableLayouts(from data: Data) -> [String] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let layouts = json["layouts"] as? [String: Any] else {
            return []
        }
        return Array(layouts.keys).sorted()
    }
}
