import XCTest
@testable import ZMKHud

final class ModelsTests: XCTestCase {
    
    func testBindingDisplayLabelForKeyPress() {
        let binding = KeyBinding(type: .keyPress("SPACE"), raw: "&kp SPACE")
        
        XCTAssertEqual(binding.displayLabel, "␣")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testBindingDisplayLabelForLayerMomentary() {
        let binding = KeyBinding(type: .layerMomentary(2), raw: "&mo 2")
        
        XCTAssertEqual(binding.displayLabel, "L2")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testBindingDisplayLabelForLayerTap() {
        let binding = KeyBinding(type: .layerTap(1, "SPACE"), raw: "&lt 1 SPACE")
        
        XCTAssertEqual(binding.displayLabel, "␣")
        XCTAssertEqual(binding.holdLabel, "L1")
    }
    
    func testBindingDisplayLabelForModTap() {
        let binding = KeyBinding(type: .modTap("LSHIFT", "A"), raw: "&mt LSHIFT A")
        
        XCTAssertEqual(binding.displayLabel, "A")
        XCTAssertEqual(binding.holdLabel, "⇧")
    }
    
    func testBindingDisplayLabelForHoldTap() {
        let binding = KeyBinding(type: .holdTap("LGUI", "S"), raw: "&hml LGUI S")
        
        XCTAssertEqual(binding.displayLabel, "S")
        XCTAssertEqual(binding.holdLabel, "⌘")
    }
    
    func testBindingDisplayLabelForTapDance() {
        let binding = KeyBinding(type: .tapDance("td_a"), raw: "&td_a")
        
        XCTAssertEqual(binding.displayLabel, "A")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testBindingDisplayLabelForTransparent() {
        let binding = KeyBinding(type: .transparent, raw: "&trans")
        
        XCTAssertEqual(binding.displayLabel, "▽")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testBindingDisplayLabelForNone() {
        let binding = KeyBinding(type: .none, raw: "&none")
        
        XCTAssertEqual(binding.displayLabel, "")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testBindingDisplayLabelForCustom() {
        let binding = KeyBinding(type: .custom("&custom_behavior"), raw: "&custom_behavior")
        
        XCTAssertEqual(binding.displayLabel, "&custom_behavior")
        XCTAssertNil(binding.holdLabel)
    }
    
    func testComboWithTwoPositions() {
        let combo = Combo(
            name: "combo_excl",
            positions: [13, 25],
            result: KeyBinding(type: .keyPress("EXCL"), raw: "&kp EXCL"),
            layers: nil,
            timeoutMs: nil
        )
        
        XCTAssertEqual(combo.positions.count, 2)
        XCTAssertEqual(combo.result.displayLabel, "!")
    }
    
    func testComboWithThreePositions() {
        let combo = Combo(
            name: "combo_enter",
            positions: [31, 32, 33],
            result: KeyBinding(type: .keyPress("ENTER"), raw: "&kp ENTER"),
            layers: [0, 1, 2],
            timeoutMs: 30
        )
        
        XCTAssertEqual(combo.positions.count, 3)
        XCTAssertEqual(combo.layers, [0, 1, 2])
        XCTAssertEqual(combo.timeoutMs, 30)
    }
    
    func testKeymapStructure() {
        let keymap = Keymap(
            layers: [
                Layer(name: "Base", bindings: []),
                Layer(name: "Nav", bindings: [])
            ],
            combos: [],
            behaviors: [:]
        )
        
        XCTAssertEqual(keymap.layers.count, 2)
        XCTAssertTrue(keymap.combos.isEmpty)
        XCTAssertTrue(keymap.behaviors.isEmpty)
    }
}
