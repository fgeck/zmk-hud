import Foundation

/// Represents a physical key on the keyboard.
/// Ported from keymap-drawer's PhysicalKey class.
///
/// The key is defined by its center position (in pixels), dimensions, and optional rotation.
/// Rotation is clockwise-positive in degrees.
struct PhysicalKey: Identifiable, Equatable {
    let id: Int
    
    /// Center position in pixels
    var pos: Point
    
    /// Width in pixels
    var width: Double
    
    /// Height in pixels
    var height: Double
    
    /// Rotation angle in degrees (clockwise positive)
    var rotation: Double
    
    /// Bounding box width (accounts for rotation)
    var boundingWidth: Double
    
    /// Bounding box height (accounts for rotation)
    var boundingHeight: Double
    
    /// Whether this is an ISO enter key (special rendering)
    var isISOEnter: Bool
    
    init(
        id: Int,
        pos: Point,
        width: Double,
        height: Double,
        rotation: Double = 0,
        isISOEnter: Bool = false
    ) {
        self.id = id
        self.pos = pos
        self.width = width
        self.height = height
        self.rotation = rotation
        self.isISOEnter = isISOEnter
        
        // Calculate bounding box for rotated keys
        if rotation != 0 {
            let corners = [
                Point(x: 0, y: 0),
                Point(x: 0, y: height),
                Point(x: width, y: 0),
                Point(x: width, y: height)
            ]
            let rotatedCorners = corners.map { $0.rotated(around: Point(), byDegrees: rotation) }
            let minX = rotatedCorners.map(\.x).min() ?? 0
            let maxX = rotatedCorners.map(\.x).max() ?? width
            let minY = rotatedCorners.map(\.y).min() ?? 0
            let maxY = rotatedCorners.map(\.y).max() ?? height
            self.boundingWidth = maxX - minX
            self.boundingHeight = maxY - minY
        } else {
            self.boundingWidth = width
            self.boundingHeight = height
        }
    }
    
    /// Create a PhysicalKey from QMK-format key definition.
    /// Ported from keymap-drawer's `PhysicalKey.from_qmk_spec`.
    ///
    /// - Parameters:
    ///   - id: Key index
    ///   - scale: Pixels per key unit (typically key_h from config, e.g., 56)
    ///   - topLeft: Top-left corner coordinates in key units
    ///   - width: Width in key units (default 1.0)
    ///   - height: Height in key units (default 1.0)
    ///   - rotation: Rotation angle in degrees (clockwise positive)
    ///   - rotationOrigin: Origin point for rotation in key units (defaults to topLeft)
    static func fromQMKSpec(
        id: Int,
        scale: Double,
        topLeft: Point,
        width: Double = 1.0,
        height: Double = 1.0,
        rotation: Double = 0,
        rotationOrigin: Point? = nil
    ) -> PhysicalKey {
        // Calculate center from top-left corner
        var center = topLeft + Point(x: width / 2, y: height / 2)
        
        // If rotated, adjust center position around rotation origin
        if rotation != 0 {
            let origin = rotationOrigin ?? topLeft
            center = center.rotated(around: origin, byDegrees: rotation)
        }
        
        // Detect ISO enter (special case: 1.25u wide, 2u tall)
        let isISOEnter = width == 1.25 && height == 2.0
        
        return PhysicalKey(
            id: id,
            pos: scale * center,
            width: scale * width,
            height: scale * height,
            rotation: rotation,
            isISOEnter: isISOEnter
        )
    }
    
    // MARK: - Transformations
    
    /// Translate the key by an offset
    func translated(by offset: Point) -> PhysicalKey {
        var copy = self
        copy.pos = pos + offset
        return copy
    }
    
    /// Scale the key by a factor
    func scaled(by factor: Double) -> PhysicalKey {
        PhysicalKey(
            id: id,
            pos: pos * factor,
            width: width * factor,
            height: height * factor,
            rotation: rotation,
            isISOEnter: isISOEnter
        )
    }
}

// MARK: - CGRect Conversion

import CoreGraphics

extension PhysicalKey {
    /// Returns a CGRect for the key bounds (centered at pos)
    var bounds: CGRect {
        CGRect(
            x: pos.x - width / 2,
            y: pos.y - height / 2,
            width: width,
            height: height
        )
    }
    
    /// Returns a CGRect for the bounding box (accounts for rotation)
    var boundingRect: CGRect {
        CGRect(
            x: pos.x - boundingWidth / 2,
            y: pos.y - boundingHeight / 2,
            width: boundingWidth,
            height: boundingHeight
        )
    }
}
