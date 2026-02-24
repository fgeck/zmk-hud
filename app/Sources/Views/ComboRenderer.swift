import SwiftUI

/// Renders combos on the keyboard with dendrons connecting trigger keys to combo boxes.
/// Ported from keymap-drawer's ComboDrawerMixin.
struct ComboRenderer {
    let layout: PhysicalLayout
    let combos: [ComboSpec]
    let config: ComboDrawConfig
    
    /// Configuration for combo drawing
    struct ComboDrawConfig {
        var comboW: Double = 28
        var comboH: Double = 26
        var innerPadW: Double = 2
        var innerPadH: Double = 2
        var arcRadius: Double = 6
        var keyRx: Double = 6
        var keyRy: Double = 6
        var smallPad: Double = 2
        
        static var `default`: ComboDrawConfig { ComboDrawConfig() }
    }
    
    /// Combo specification with position, alignment, and styling
    struct ComboSpec {
        var keyPositions: [Int]
        var result: KeyLegend
        var align: ComboAlignment = .top
        var offset: Double = 0.5
        var dendron: DendronStyle = .auto
        var arcScale: Double = 1.0
        var slide: Double? = nil
        var rotation: Double = 0
        var width: Double? = nil
        var height: Double? = nil
        var type: String? = nil
        var hidden: Bool = false
        
        /// Create from app's Combo model
        init(from combo: Combo, customLabels: [String: String] = [:]) {
            self.keyPositions = combo.positions
            self.result = KeyLegend(
                tap: combo.result.displayLabel(with: customLabels),
                hold: combo.result.holdLabel
            )
        }
        
        init(keyPositions: [Int], result: KeyLegend, align: ComboAlignment = .top, offset: Double = 0.5) {
            self.keyPositions = keyPositions
            self.result = result
            self.align = align
            self.offset = offset
        }
    }
    
    enum ComboAlignment: String {
        case top, bottom, left, right, mid
    }
    
    enum DendronStyle {
        case auto      // Draw if keys are far enough apart
        case always    // Always draw dendrons
        case never     // Never draw dendrons
    }
    
    /// Calculate the center position for a combo box
    func comboBoxPosition(for spec: ComboSpec) -> Point {
        let keys = spec.keyPositions.compactMap { layout[$0] }
        guard !keys.isEmpty else { return Point(x: 0, y: 0) }
        
        // Calculate midpoint of all trigger keys
        var midX = keys.map(\.pos.x).reduce(0, +) / Double(keys.count)
        var midY = keys.map(\.pos.y).reduce(0, +) / Double(keys.count)
        
        // Apply slide if specified
        if let slide = spec.slide, keys.count >= 2 {
            // Find two keys furthest from midpoint
            let midPoint = Point(x: midX, y: midY)
            let sortedKeys = keys.sorted { k1, k2 in
                let dist1 = abs(k1.pos.x - midPoint.x) + abs(k1.pos.y - midPoint.y)
                let dist2 = abs(k2.pos.x - midPoint.x) + abs(k2.pos.y - midPoint.y)
                return dist1 > dist2
            }
            let start = sortedKeys[0].pos
            let end = sortedKeys[1].pos
            midX = (1 - slide) / 2 * start.x + (1 + slide) / 2 * end.x
            midY = (1 - slide) / 2 * start.y + (1 + slide) / 2 * end.y
        }
        
        let midPoint = Point(x: midX, y: midY)
        let minHeight = layout.minKeyHeight
        let minWidth = layout.minKeyWidth
        
        switch spec.align {
        case .mid:
            return midPoint
            
        case .top:
            let topY = keys.map { $0.pos.y - $0.height / 2 }.min() ?? midY
            return Point(
                x: midX,
                y: topY - config.innerPadH / 2 - spec.offset * minHeight
            )
            
        case .bottom:
            let bottomY = keys.map { $0.pos.y + $0.height / 2 }.max() ?? midY
            return Point(
                x: midX,
                y: bottomY + config.innerPadH / 2 + spec.offset * minHeight
            )
            
        case .left:
            let leftX = keys.map { $0.pos.x - $0.width / 2 }.min() ?? midX
            return Point(
                x: leftX - config.innerPadW / 2 - spec.offset * minWidth,
                y: midY
            )
            
        case .right:
            let rightX = keys.map { $0.pos.x + $0.width / 2 }.max() ?? midX
            return Point(
                x: rightX + config.innerPadW / 2 + spec.offset * minWidth,
                y: midY
            )
        }
    }
    
    /// Generate a dendron path from combo box to a key
    func dendronPath(from comboPos: Point, to key: PhysicalKey, spec: ComboSpec) -> Path {
        var path = Path()
        let keyPos = key.pos
        let diff = Point(x: keyPos.x - comboPos.x, y: keyPos.y - comboPos.y)
        
        let width = spec.width ?? config.comboW
        let height = spec.height ?? config.comboH
        
        switch spec.align {
        case .top, .bottom:
            // Arc dendron: horizontal first, then vertical
            let offset: Double
            if abs(diff.x) < width / 2 && abs(diff.y) <= key.height / 3 + height / 2 {
                offset = key.height / 5
            } else {
                offset = key.height / 3
            }
            path = arcDendronPath(from: comboPos, to: keyPos, xFirst: true, shorten: offset, arcScale: spec.arcScale)
            
        case .left, .right:
            // Arc dendron: vertical first, then horizontal
            let offset: Double
            if abs(diff.y) < height / 2 && abs(diff.x) <= key.width / 3 + width / 2 {
                offset = key.width / 5
            } else {
                offset = key.width / 3
            }
            path = arcDendronPath(from: comboPos, to: keyPos, xFirst: false, shorten: offset, arcScale: spec.arcScale)
            
        case .mid:
            // Line dendron
            let distance = sqrt(diff.x * diff.x + diff.y * diff.y)
            if spec.dendron == .always || distance >= key.width - 1 {
                path = lineDendronPath(from: comboPos, to: keyPos, shorten: key.width / 3)
            }
        }
        
        return path
    }
    
    /// Create an arc-style dendron path
    private func arcDendronPath(from p1: Point, to p2: Point, xFirst: Bool, shorten: Double, arcScale: Double) -> Path {
        var path = Path()
        let diff = Point(x: p2.x - p1.x, y: p2.y - p1.y)
        
        // If points too close, use line instead
        if (xFirst && abs(diff.x) < config.arcRadius) || (!xFirst && abs(diff.y) < config.arcRadius) {
            return lineDendronPath(from: p1, to: p2, shorten: shorten)
        }
        
        path.move(to: CGPoint(x: p1.x, y: p1.y))
        
        let arcX = diff.x > 0 ? config.arcRadius : -config.arcRadius
        let arcY = diff.y > 0 ? config.arcRadius : -config.arcRadius
        let clockwise = (diff.x > 0) != (diff.y > 0)
        
        if xFirst {
            // Horizontal line first
            let hLength = arcScale * diff.x - arcX
            path.addLine(to: CGPoint(x: p1.x + hLength, y: p1.y))
            
            // Arc
            let arcEndX = p1.x + hLength + arcX
            let arcEndY = p1.y + arcY
            path.addQuadCurve(
                to: CGPoint(x: arcEndX, y: arcEndY),
                control: CGPoint(x: p1.x + hLength + (clockwise ? 0 : arcX), y: p1.y + (clockwise ? arcY : 0))
            )
            
            // Vertical line
            let shortenY = diff.y > 0 ? shorten : -shorten
            path.addLine(to: CGPoint(x: arcEndX, y: p2.y - shortenY))
        } else {
            // Vertical line first
            let vLength = arcScale * diff.y - arcY
            path.addLine(to: CGPoint(x: p1.x, y: p1.y + vLength))
            
            // Arc
            let arcEndX = p1.x + arcX
            let arcEndY = p1.y + vLength + arcY
            path.addQuadCurve(
                to: CGPoint(x: arcEndX, y: arcEndY),
                control: CGPoint(x: p1.x + (clockwise ? arcX : 0), y: p1.y + vLength + (clockwise ? 0 : arcY))
            )
            
            // Horizontal line
            let shortenX = diff.x > 0 ? shorten : -shorten
            path.addLine(to: CGPoint(x: p2.x - shortenX, y: arcEndY))
        }
        
        return path
    }
    
    /// Create a straight line dendron path
    private func lineDendronPath(from p1: Point, to p2: Point, shorten: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: p1.x, y: p1.y))
        
        let diff = Point(x: p2.x - p1.x, y: p2.y - p1.y)
        let magnitude = sqrt(diff.x * diff.x + diff.y * diff.y)
        
        if shorten > 0 && shorten < magnitude {
            let scale = 1 - shorten / magnitude
            path.addLine(to: CGPoint(x: p1.x + diff.x * scale, y: p1.y + diff.y * scale))
        } else {
            path.addLine(to: CGPoint(x: p2.x, y: p2.y))
        }
        
        return path
    }
}

// MARK: - ComboOverlayView

/// SwiftUI view that renders combos on top of the keyboard
struct ComboOverlayView: View {
    let layout: PhysicalLayout
    let combos: [Combo]
    let currentLayer: Int
    let customLabels: [String: String]
    let colorScheme: ColorScheme
    
    @Environment(\.colorScheme) private var systemColorScheme
    
    var body: some View {
        Canvas { context, size in
            let renderer = ComboRenderer(
                layout: layout,
                combos: filteredCombos.map { ComboRenderer.ComboSpec(from: $0, customLabels: customLabels) },
                config: .default
            )
            
            let isDark = systemColorScheme == .dark
            let dendronColor = isDark ? Color.gray : Color.gray.opacity(0.6)
            let boxFillColor = colorScheme.combo
            let boxStrokeColor = isDark ? Color(hex: "#60666c") : Color(hex: "#c9cccf")
            
            for combo in filteredCombos {
                let spec = ComboRenderer.ComboSpec(from: combo, customLabels: customLabels)
                guard !spec.hidden else { continue }
                
                let comboPos = renderer.comboBoxPosition(for: spec)
                let keys = spec.keyPositions.compactMap { layout[$0] }
                
                // Draw dendrons
                if spec.dendron != .never {
                    for key in keys {
                        let path = renderer.dendronPath(from: comboPos, to: key, spec: spec)
                        context.stroke(path, with: .color(dendronColor), lineWidth: 1)
                    }
                }
                
                // Draw combo box
                let width = spec.width ?? 28
                let height = spec.height ?? 26
                let boxRect = CGRect(
                    x: comboPos.x - width / 2,
                    y: comboPos.y - height / 2,
                    width: width,
                    height: height
                )
                let boxPath = RoundedRectangle(cornerRadius: 4).path(in: boxRect)
                context.fill(boxPath, with: .color(boxFillColor))
                context.stroke(boxPath, with: .color(boxStrokeColor), lineWidth: 1)
                
                // Draw combo label
                if let tap = spec.result.tap, !tap.isEmpty {
                    let text = Text(tap)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(colorScheme.textDefault)
                    context.draw(text, at: CGPoint(x: comboPos.x, y: comboPos.y), anchor: .center)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    /// Filter combos to show only those for the current layer
    private var filteredCombos: [Combo] {
        combos.filter { combo in
            guard let comboLayers = combo.layers, !comboLayers.isEmpty else {
                return true // Show on all layers if no layer specified
            }
            return comboLayers.contains(currentLayer)
        }
    }
}

// MARK: - Extended Combo Model

extension Combo {
    /// Alignment hint for combo rendering (parsed from zmk_combos config)
    var align: ComboRenderer.ComboAlignment {
        // Default: determine based on key positions
        // Vertical combos → align top
        // Horizontal combos → align left or right based on position
        .top
    }
}
