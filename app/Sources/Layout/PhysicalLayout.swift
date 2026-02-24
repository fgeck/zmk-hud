import Foundation

/// Represents the physical layout of keys on the keyboard.
/// Ported from keymap-drawer's PhysicalLayout class.
struct PhysicalLayout {
    var keys: [PhysicalKey]
    
    var count: Int { keys.count }
    
    /// Overall width of the layout in pixels
    var width: Double {
        keys.map { $0.pos.x + $0.boundingWidth / 2 }.max() ?? 0
    }
    
    /// Overall height of the layout in pixels
    var height: Double {
        keys.map { $0.pos.y + $0.boundingHeight / 2 }.max() ?? 0
    }
    
    /// Minimum key width in the layout
    var minKeyWidth: Double {
        keys.map(\.width).min() ?? 0
    }
    
    /// Minimum key height in the layout
    var minKeyHeight: Double {
        keys.map(\.height).min() ?? 0
    }
    
    /// Get a key by index
    subscript(index: Int) -> PhysicalKey? {
        guard index >= 0 && index < keys.count else { return nil }
        return keys[index]
    }
    
    /// Normalize the layout so all keys are in positive coordinate space.
    /// Ported from keymap-drawer's `normalize` method.
    func normalized() -> PhysicalLayout {
        guard !keys.isEmpty else { return self }
        
        let minX = keys.map { $0.pos.x - $0.boundingWidth / 2 }.min() ?? 0
        let minY = keys.map { $0.pos.y - $0.boundingHeight / 2 }.min() ?? 0
        let offset = Point(x: -minX, y: -minY)
        
        return PhysicalLayout(keys: keys.map { $0.translated(by: offset) })
    }
    
    /// Translate the entire layout by an offset
    func translated(by offset: Point) -> PhysicalLayout {
        PhysicalLayout(keys: keys.map { $0.translated(by: offset) })
    }
    
    /// Scale the entire layout by a factor
    func scaled(by factor: Double) -> PhysicalLayout {
        PhysicalLayout(keys: keys.map { $0.scaled(by: factor) })
    }
}

// MARK: - CGSize Conversion

import CoreGraphics

extension PhysicalLayout {
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}
