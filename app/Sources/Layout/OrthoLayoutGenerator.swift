import Foundation

/// Generates ortholinear keyboard layouts.
/// Ported from keymap-drawer's OrthoLayout class.
///
/// Can generate layouts for split and non-split ortho keyboards with configurable:
/// - Row and column counts
/// - Thumb key configurations
/// - Pinky/inner column drops
struct OrthoLayoutGenerator {
    /// Whether the keyboard is split (two halves)
    var split: Bool = false
    
    /// Number of rows (per half if split)
    var rows: Int
    
    /// Number of columns (per half if split)
    var columns: Int
    
    /// Number of thumb keys (per half if split), or special values "MIT" / "2x2u"
    var thumbs: ThumbConfig = .count(0)
    
    /// Drop the outer pinky column by half a key height
    var dropPinky: Bool = false
    
    /// Drop the inner index column by half a key height
    var dropInner: Bool = false
    
    enum ThumbConfig: Equatable {
        case count(Int)
        case mit      // Single 2u spacebar
        case twoByTwoU // Two 2u keys
    }
    
    /// Generate a PhysicalLayout from the ortho configuration.
    ///
    /// - Parameters:
    ///   - keyW: Key width in pixels
    ///   - keyH: Key height in pixels
    ///   - splitGap: Gap between halves in pixels (for split layouts)
    /// - Returns: A PhysicalLayout with all keys positioned
    func generate(keyW: Double, keyH: Double, splitGap: Double) -> PhysicalLayout {
        var keys: [PhysicalKey] = []
        var keyIndex = 0
        
        // Determine number of rows (exclude thumb row if using special thumb config)
        let mainRows: Int
        switch thumbs {
        case .mit, .twoByTwoU:
            mainRows = rows - 1
        case .count:
            mainRows = rows
        }
        
        // Generate main key grid
        for row in 0..<mainRows {
            var rowKeys: [PhysicalKey] = []
            
            // Left half
            for col in 0..<columns {
                let x = Double(col) * keyW + keyW / 2
                let y = Double(row) * keyH + keyH / 2
                rowKeys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: y),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
            // Right half (if split)
            if split {
                for col in 0..<columns {
                    let x = Double(columns + col) * keyW + splitGap + keyW / 2
                    let y = Double(row) * keyH + keyH / 2
                    rowKeys.append(PhysicalKey(
                        id: keyIndex,
                        pos: Point(x: x, y: y),
                        width: keyW,
                        height: keyH
                    ))
                    keyIndex += 1
                }
            }
            
            // Apply column drops
            if dropPinky || dropInner {
                rowKeys = applyColumnDrops(rowKeys, row: row, mainRows: mainRows, keyH: keyH)
            }
            
            keys.append(contentsOf: rowKeys)
        }
        
        // Generate thumb row
        let thumbY = Double(mainRows) * keyH + keyH / 2
        
        switch thumbs {
        case .count(let count) where count > 0:
            // Split thumbs
            let thumbStartCol = columns - count
            
            // Left thumb cluster
            for i in 0..<count {
                let x = Double(thumbStartCol + i) * keyW + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
            // Right thumb cluster
            for i in 0..<count {
                let x = Double(columns + i) * keyW + splitGap + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
        case .mit:
            // MIT layout: 2u spacebar in the middle
            let halfCols = columns / 2
            
            // Left side keys
            for i in 0..<(halfCols - 1) {
                let x = Double(i) * keyW + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
            // 2u spacebar
            let spaceX = Double(halfCols) * keyW
            keys.append(PhysicalKey(
                id: keyIndex,
                pos: Point(x: spaceX, y: thumbY),
                width: 2 * keyW,
                height: keyH
            ))
            keyIndex += 1
            
            // Right side keys
            for i in 0..<(halfCols - 1) {
                let x = Double(halfCols + 1 + i) * keyW + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
        case .twoByTwoU:
            // 2x2u layout: two 2u keys in the middle
            let halfCols = columns / 2
            
            // Left side keys
            for i in 0..<(halfCols - 2) {
                let x = Double(i) * keyW + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
            // Left 2u key
            let leftSpaceX = Double(halfCols - 1) * keyW
            keys.append(PhysicalKey(
                id: keyIndex,
                pos: Point(x: leftSpaceX, y: thumbY),
                width: 2 * keyW,
                height: keyH
            ))
            keyIndex += 1
            
            // Right 2u key
            let rightSpaceX = Double(halfCols + 1) * keyW
            keys.append(PhysicalKey(
                id: keyIndex,
                pos: Point(x: rightSpaceX, y: thumbY),
                width: 2 * keyW,
                height: keyH
            ))
            keyIndex += 1
            
            // Right side keys
            for i in 0..<(halfCols - 2) {
                let x = Double(halfCols + 2 + i) * keyW + keyW / 2
                keys.append(PhysicalKey(
                    id: keyIndex,
                    pos: Point(x: x, y: thumbY),
                    width: keyW,
                    height: keyH
                ))
                keyIndex += 1
            }
            
        case .count:
            // No thumbs or zero thumbs
            break
        }
        
        return PhysicalLayout(keys: keys)
    }
    
    /// Apply column drops to offset pinky and/or inner columns.
    private func applyColumnDrops(_ rowKeys: [PhysicalKey], row: Int, mainRows: Int, keyH: Double) -> [PhysicalKey] {
        var result = rowKeys
        
        // Indices to drop (left pinky = 0, left inner = columns-1, right inner = columns, right pinky = 2*columns-1)
        var dropIndices: [Int] = []
        
        if dropPinky {
            dropIndices.append(0)  // Left pinky
            if split {
                dropIndices.append(columns * 2 - 1)  // Right pinky
            }
        }
        
        if dropInner {
            dropIndices.append(columns - 1)  // Left inner
            if split {
                dropIndices.append(columns)  // Right inner
            }
        }
        
        for idx in dropIndices {
            guard idx < result.count else { continue }
            
            if row < mainRows - 1 {
                // Offset by half key height
                result[idx] = PhysicalKey(
                    id: result[idx].id,
                    pos: Point(x: result[idx].pos.x, y: result[idx].pos.y + keyH / 2),
                    width: result[idx].width,
                    height: result[idx].height
                )
            }
            // Note: The last row's dropped columns would be removed entirely,
            // but we keep them for simplicity (keymap-drawer removes them)
        }
        
        return result
    }
}

// MARK: - Convenience initializer for common layouts

extension OrthoLayoutGenerator {
    /// Create a standard split 3x5+3 layout (like Corne)
    static var corne: OrthoLayoutGenerator {
        OrthoLayoutGenerator(split: true, rows: 3, columns: 5, thumbs: .count(3))
    }
    
    /// Create a standard split 3x6+3 layout (like Corne with outer columns)
    static var corneExtended: OrthoLayoutGenerator {
        OrthoLayoutGenerator(split: true, rows: 3, columns: 6, thumbs: .count(3))
    }
    
    /// Create a standard split 4x6+5 layout (like Ergodox-style)
    static var ergodox: OrthoLayoutGenerator {
        OrthoLayoutGenerator(split: true, rows: 4, columns: 6, thumbs: .count(5))
    }
    
    /// Create a standard non-split 4x12 layout with MIT spacebar (like Planck)
    static var planck: OrthoLayoutGenerator {
        OrthoLayoutGenerator(split: false, rows: 4, columns: 12, thumbs: .mit)
    }
}
