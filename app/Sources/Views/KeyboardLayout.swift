import SwiftUI
import Foundation

struct KeyPosition: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotation: CGFloat
    let rotationOriginX: CGFloat
    let rotationOriginY: CGFloat
    
    init(
        index: Int,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat = 1.0,
        height: CGFloat = 1.0,
        rotation: CGFloat = 0,
        rotationOriginX: CGFloat? = nil,
        rotationOriginY: CGFloat? = nil
    ) {
        self.id = index
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.rotationOriginX = rotationOriginX ?? x
        self.rotationOriginY = rotationOriginY ?? y
    }
}

struct PhysicalLayout {
    let name: String
    let positions: [KeyPosition]
    let keyUnit: CGFloat
    
    var layoutSize: CGSize {
        guard !positions.isEmpty else { return .zero }
        let maxX = positions.map { ($0.x + $0.width) * keyUnit }.max() ?? 0
        let maxY = positions.map { ($0.y + $0.height) * keyUnit }.max() ?? 0
        return CGSize(width: maxX + 20, height: maxY + 20)
    }
    
    func position(for index: Int) -> KeyPosition? {
        guard index < positions.count else { return nil }
        return positions[index]
    }
    
    func scaledPosition(for index: Int) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, rotation: CGFloat, rotationOriginX: CGFloat, rotationOriginY: CGFloat)? {
        guard let pos = position(for: index) else { return nil }
        return (
            x: pos.x * keyUnit,
            y: pos.y * keyUnit,
            width: pos.width * keyUnit,
            height: pos.height * keyUnit,
            rotation: pos.rotation,
            rotationOriginX: pos.rotationOriginX * keyUnit,
            rotationOriginY: pos.rotationOriginY * keyUnit
        )
    }
}

struct LayoutOption: Identifiable, Hashable {
    let id: String
    let name: String
    let keyCount: Int
}

struct LayoutParseResult {
    let options: [LayoutOption]
    let selectedLayout: PhysicalLayout?
}

class LayoutLoader {
    static let shared = LayoutLoader()
    
    func loadFromJSON(_ jsonString: String, keyUnit: CGFloat = 56, layoutId: String? = nil) -> PhysicalLayout? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return parseLayoutJSON(data, keyUnit: keyUnit, layoutId: layoutId)
    }
    
    func loadFromFile(_ path: String, keyUnit: CGFloat = 56, layoutId: String? = nil) -> PhysicalLayout? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return parseLayoutJSON(data, keyUnit: keyUnit, layoutId: layoutId)
    }
    
    func loadFromURL(_ urlString: String, keyUnit: CGFloat = 56, layoutId: String? = nil, completion: @escaping (PhysicalLayout?) -> Void) {
        let normalizedURL = Self.normalizeGitHubURL(urlString)
        guard let url = URL(string: normalizedURL) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let layout = self.parseLayoutJSON(data, keyUnit: keyUnit, layoutId: layoutId)
            DispatchQueue.main.async { completion(layout) }
        }.resume()
    }
    
    func getAvailableLayoutsFromFile(_ path: String) -> [LayoutOption] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return [] }
        return parseLayoutOptions(data)
    }
    
    func getAvailableLayoutsFromURL(_ urlString: String, completion: @escaping ([LayoutOption]) -> Void) {
        let normalizedURL = Self.normalizeGitHubURL(urlString)
        guard let url = URL(string: normalizedURL) else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let options = self.parseLayoutOptions(data)
            DispatchQueue.main.async { completion(options) }
        }.resume()
    }
    
    private static func normalizeGitHubURL(_ urlString: String) -> String {
        if urlString.contains("github.com") && urlString.contains("/blob/") {
            return urlString
                .replacingOccurrences(of: "github.com", with: "raw.githubusercontent.com")
                .replacingOccurrences(of: "/blob/", with: "/")
        }
        return urlString
    }
    
    private func parseLayoutOptions(_ data: Data) -> [LayoutOption] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let layouts = json["layouts"] as? [String: Any] else {
            return []
        }
        
        var options: [LayoutOption] = []
        for (key, value) in layouts {
            if let layoutDict = value as? [String: Any],
               let layoutArray = layoutDict["layout"] as? [[String: Any]] {
                let name = (layoutDict["name"] as? String) ?? key
                options.append(LayoutOption(id: key, name: name, keyCount: layoutArray.count))
            }
        }
        
        return options.sorted { $0.keyCount > $1.keyCount }
    }
    
    private func parseLayoutJSON(_ data: Data, keyUnit: CGFloat, layoutId: String? = nil) -> PhysicalLayout? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        var layoutArray: [[String: Any]]?
        var layoutName = "Custom"
        
        if let layouts = json["layouts"] as? [String: Any] {
            if let specificId = layoutId, let specificLayout = layouts[specificId] as? [String: Any],
               let layout = specificLayout["layout"] as? [[String: Any]] {
                layoutArray = layout
                layoutName = (specificLayout["name"] as? String) ?? specificId
            } else if let firstLayout = layouts.values.first as? [String: Any],
               let layout = firstLayout["layout"] as? [[String: Any]] {
                layoutArray = layout
                layoutName = (firstLayout["name"] as? String) ?? "Custom"
            } else if let layout = (layouts["LAYOUT"] as? [String: Any])?["layout"] as? [[String: Any]] {
                layoutArray = layout
            }
        } else if let layout = json["layout"] as? [[String: Any]] {
            layoutArray = layout
        }
        
        guard let keys = layoutArray else { return nil }
        
        var positions: [KeyPosition] = []
        
        for (index, key) in keys.enumerated() {
            let x = (key["x"] as? Double) ?? 0
            let y = (key["y"] as? Double) ?? 0
            let w = (key["w"] as? Double) ?? 1.0
            let h = (key["h"] as? Double) ?? 1.0
            let r = (key["r"] as? Double) ?? 0
            let rx = key["rx"] as? Double
            let ry = key["ry"] as? Double
            
            positions.append(KeyPosition(
                index: index,
                x: CGFloat(x),
                y: CGFloat(y),
                width: CGFloat(w),
                height: CGFloat(h),
                rotation: CGFloat(r),
                rotationOriginX: rx.map { CGFloat($0) },
                rotationOriginY: ry.map { CGFloat($0) }
            ))
        }
        
        return PhysicalLayout(name: layoutName, positions: positions, keyUnit: keyUnit)
    }
    
    func createFallbackFromRowStructure(_ rowStructure: [Int], keyUnit: CGFloat = 56) -> PhysicalLayout {
        var positions: [KeyPosition] = []
        var index = 0
        let splitGap: CGFloat = 1.5
        for (row, columnsInRow) in rowStructure.enumerated() {
            let keysPerHalf = columnsInRow / 2
            let hasOddKey = columnsInRow % 2 != 0
            
            for col in 0..<keysPerHalf {
                positions.append(KeyPosition(
                    index: index,
                    x: CGFloat(col),
                    y: CGFloat(row)
                ))
                index += 1
            }
            
            for col in 0..<keysPerHalf {
                positions.append(KeyPosition(
                    index: index,
                    x: CGFloat(keysPerHalf) + splitGap + CGFloat(col),
                    y: CGFloat(row)
                ))
                index += 1
            }
            
            if hasOddKey {
                positions.append(KeyPosition(
                    index: index,
                    x: CGFloat(columnsInRow) + splitGap,
                    y: CGFloat(row)
                ))
                index += 1
            }
        }
        let totalKeys = rowStructure.reduce(0, +)
        return PhysicalLayout(
            name: "Split Fallback (\(totalKeys) keys)",
            positions: positions,
            keyUnit: keyUnit
        )
    }
    
    func createFallbackGrid(keyCount: Int, keyUnit: CGFloat = 56) -> PhysicalLayout {
        var positions: [KeyPosition] = []
        
        let columns = min(12, max(6, Int(ceil(sqrt(Double(keyCount) * 2)))))
        
        for index in 0..<keyCount {
            let col = index % columns
            let row = index / columns
            positions.append(KeyPosition(
                index: index,
                x: CGFloat(col),
                y: CGFloat(row)
            ))
        }
        
        return PhysicalLayout(
            name: "Fallback Grid (\(keyCount) keys)",
            positions: positions,
            keyUnit: keyUnit
        )
    }
}
