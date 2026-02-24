import Foundation

/// A 2D point, ported from keymap-drawer's Point class.
/// Used for position calculations in physical keyboard layouts.
struct Point: Equatable, Hashable {
    var x: Double
    var y: Double
    
    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
    
    // MARK: - Arithmetic Operations
    
    static func + (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func * (lhs: Double, rhs: Point) -> Point {
        Point(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    static func * (lhs: Point, rhs: Double) -> Point {
        Point(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    /// Euclidean distance from origin (magnitude)
    var magnitude: Double {
        sqrt(x * x + y * y)
    }
    
    // MARK: - Rotation
    
    /// Rotate this point around an origin by a given angle in degrees (clockwise positive).
    /// Ported from keymap-drawer's `_rotate_point` method.
    func rotated(around origin: Point, byDegrees angle: Double) -> Point {
        let radians = angle * .pi / 180
        let delta = self - origin
        let rotated = Point(
            x: delta.x * cos(radians) - delta.y * sin(radians),
            y: delta.x * sin(radians) + delta.y * cos(radians)
        )
        return origin + rotated
    }
}

// MARK: - CGPoint Conversion

import CoreGraphics

extension Point {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    init(_ cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
    }
}
