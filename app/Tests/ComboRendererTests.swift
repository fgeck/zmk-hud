import XCTest
@testable import ZMKHud

final class ComboRendererTests: XCTestCase {
    
    // MARK: - Test Setup
    
    func makeTestLayout() -> PhysicalLayout {
        // Create a simple 3x5 split layout
        OrthoLayoutGenerator(split: true, rows: 3, columns: 5, thumbs: .count(3))
            .generate(keyW: 56, keyH: 56, splitGap: 30)
    }
    
    // MARK: - Combo Box Position Tests
    
    func testComboBoxPositionTop() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0, 1], // Q, W keys
            result: KeyLegend(tap: "ESC"),
            align: .top,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        // Combo should be above the keys
        let key0 = layout[0]!
        let key1 = layout[1]!
        let avgX = (key0.pos.x + key1.pos.x) / 2
        let minY = min(key0.pos.y - key0.height / 2, key1.pos.y - key1.height / 2)
        
        XCTAssertEqual(pos.x, avgX, accuracy: 0.1, "Combo X should be centered between keys")
        XCTAssertLessThan(pos.y, minY, "Combo Y should be above the keys")
    }
    
    func testComboBoxPositionBottom() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0, 1],
            result: KeyLegend(tap: "TAB"),
            align: .bottom,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        let key0 = layout[0]!
        let key1 = layout[1]!
        let maxY = max(key0.pos.y + key0.height / 2, key1.pos.y + key1.height / 2)
        
        XCTAssertGreaterThan(pos.y, maxY, "Combo Y should be below the keys")
    }
    
    func testComboBoxPositionLeft() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0, 5], // Vertical combo on left edge
            result: KeyLegend(tap: "ESC"),
            align: .left,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        let key0 = layout[0]!
        let key5 = layout[5]!
        let minX = min(key0.pos.x - key0.width / 2, key5.pos.x - key5.width / 2)
        
        XCTAssertLessThan(pos.x, minX, "Combo X should be left of the keys")
    }
    
    func testComboBoxPositionRight() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [4, 9], // Vertical combo on right edge of left half
            result: KeyLegend(tap: "BSPC"),
            align: .right,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        let key4 = layout[4]!
        let key9 = layout[9]!
        let maxX = max(key4.pos.x + key4.width / 2, key9.pos.x + key9.width / 2)
        
        XCTAssertGreaterThan(pos.x, maxX, "Combo X should be right of the keys")
    }
    
    func testComboBoxPositionMid() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0, 1, 5, 6], // 2x2 block
            result: KeyLegend(tap: "CAPS"),
            align: .mid,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        let keys = [0, 1, 5, 6].compactMap { layout[$0] }
        let avgX = keys.map(\.pos.x).reduce(0, +) / Double(keys.count)
        let avgY = keys.map(\.pos.y).reduce(0, +) / Double(keys.count)
        
        XCTAssertEqual(pos.x, avgX, accuracy: 0.1, "Combo should be at center X of keys")
        XCTAssertEqual(pos.y, avgY, accuracy: 0.1, "Combo should be at center Y of keys")
    }
    
    // MARK: - Dendron Path Tests
    
    func testDendronPathCreation() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0, 1],
            result: KeyLegend(tap: "ESC"),
            align: .top
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let comboPos = renderer.comboBoxPosition(for: spec)
        
        let key = layout[0]!
        let path = renderer.dendronPath(from: comboPos, to: key, spec: spec)
        
        // Path should not be empty
        XCTAssertFalse(path.isEmpty, "Dendron path should not be empty")
    }
    
    // MARK: - ComboSpec from Combo Model
    
    func testComboSpecFromCombo() {
        let combo = Combo(
            name: "test_combo",
            positions: [0, 1],
            result: Binding(type: .keyPress("ESC"), raw: "&kp ESC"),
            layers: [0],
            timeoutMs: 50
        )
        
        let spec = ComboRenderer.ComboSpec(from: combo)
        
        XCTAssertEqual(spec.keyPositions, [0, 1])
        XCTAssertEqual(spec.result.tap, "ESC")
        XCTAssertFalse(spec.hidden)
    }
    
    func testComboSpecWithCustomLabels() {
        let combo = Combo(
            name: "test_combo",
            positions: [0, 1],
            result: Binding(type: .tapDance("td_esc"), raw: "&td_esc"),
            layers: nil,
            timeoutMs: nil
        )
        
        let customLabels = ["td_esc": "⎋"]
        let spec = ComboRenderer.ComboSpec(from: combo, customLabels: customLabels)
        
        XCTAssertEqual(spec.result.tap, "⎋")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyKeyPositions() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [],
            result: KeyLegend(tap: "?"),
            align: .top
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        // Should return origin for empty positions
        XCTAssertEqual(pos.x, 0)
        XCTAssertEqual(pos.y, 0)
    }
    
    func testSingleKeyCombo() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [0],
            result: KeyLegend(tap: "A"),
            align: .top,
            offset: 0.5
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        let key = layout[0]!
        XCTAssertEqual(pos.x, key.pos.x, accuracy: 0.1)
    }
    
    func testInvalidKeyPositions() {
        let layout = makeTestLayout()
        let spec = ComboRenderer.ComboSpec(
            keyPositions: [999, 1000], // Invalid positions
            result: KeyLegend(tap: "?"),
            align: .top
        )
        
        let renderer = ComboRenderer(layout: layout, combos: [spec], config: .default)
        let pos = renderer.comboBoxPosition(for: spec)
        
        // Should handle gracefully
        XCTAssertEqual(pos.x, 0)
        XCTAssertEqual(pos.y, 0)
    }
}
