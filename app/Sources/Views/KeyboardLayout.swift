import SwiftUI

struct KeyPosition {
    let index: Int
    let x: CGFloat
    let y: CGFloat
    let rotation: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    init(_ index: Int, x: CGFloat, y: CGFloat, rotation: CGFloat = 0, width: CGFloat = 52, height: CGFloat = 52) {
        self.index = index
        self.x = x
        self.y = y
        self.rotation = rotation
        self.width = width
        self.height = height
    }
}

struct KeyboardLayout {
    static let keySize: CGFloat = 52
    static let keySpacing: CGFloat = 4
    static let splitGap: CGFloat = 40
    
    static let flakeMPositions: [KeyPosition] = {
        var positions: [KeyPosition] = []
        let unit = keySize + keySpacing
        
        let leftX: CGFloat = 0
        let rightX = leftX + 6 * unit + splitGap
        
        for col in 0..<6 {
            positions.append(KeyPosition(12 + col, x: leftX + CGFloat(col) * unit, y: 0))
        }
        for col in 0..<6 {
            positions.append(KeyPosition(18 + col, x: rightX + CGFloat(col) * unit, y: 0))
        }
        
        for col in 0..<6 {
            positions.append(KeyPosition(24 + col, x: leftX + CGFloat(col) * unit, y: unit))
        }
        for col in 0..<6 {
            positions.append(KeyPosition(30 + col, x: rightX + CGFloat(col) * unit, y: unit))
        }
        
        let thumbY = unit * 2 + 10
        let thumbOffsetX = unit * 1.5
        
        positions.append(KeyPosition(36, x: leftX + thumbOffsetX + 0 * unit, y: thumbY, rotation: 15))
        positions.append(KeyPosition(37, x: leftX + thumbOffsetX + 1 * unit, y: thumbY + 8, rotation: 10))
        positions.append(KeyPosition(38, x: leftX + thumbOffsetX + 2 * unit, y: thumbY + 12, rotation: 5))
        positions.append(KeyPosition(39, x: leftX + thumbOffsetX + 3 * unit, y: thumbY + 14, rotation: 0))
        positions.append(KeyPosition(40, x: leftX + thumbOffsetX + 4 * unit, y: thumbY + 12, rotation: -5))
        
        positions.append(KeyPosition(41, x: rightX + 0 * unit, y: thumbY + 12, rotation: 5))
        positions.append(KeyPosition(42, x: rightX + 1 * unit, y: thumbY + 14, rotation: 0))
        positions.append(KeyPosition(43, x: rightX + 2 * unit, y: thumbY + 12, rotation: -5))
        positions.append(KeyPosition(44, x: rightX + 3 * unit, y: thumbY + 8, rotation: -10))
        positions.append(KeyPosition(45, x: rightX + 4 * unit, y: thumbY, rotation: -15))
        
        return positions
    }()
    
    static func position(for index: Int) -> KeyPosition? {
        return flakeMPositions.first { $0.index == index }
    }
    
    static var layoutSize: CGSize {
        let maxX = flakeMPositions.map { $0.x + $0.width }.max() ?? 0
        let maxY = flakeMPositions.map { $0.y + $0.height }.max() ?? 0
        return CGSize(width: maxX + 20, height: maxY + 30)
    }
}
