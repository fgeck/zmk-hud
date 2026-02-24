import XCTest
@testable import ZMKHud

final class IntegrationTests: XCTestCase {
    
    let keymapPath = "/Users/D068994/SAPDevelop/github.com/fgeck/zmk-config/config/anywhy_flake.keymap"
    
    func testParsesRealAnwhyFlakeKeymap() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap, "Parser should successfully parse the real keymap")
    }
    
    func testFindsAllFiveLayers() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertEqual(keymap?.layers.count, 5, "Should find all 5 layers: Base, Num, Nav, Fn, Idea")
        
        let layerNames = keymap?.layers.map { $0.name } ?? []
        XCTAssertTrue(layerNames.contains("Base"), "Should have Base layer")
        XCTAssertTrue(layerNames.contains("Num"), "Should have Num layer")
        XCTAssertTrue(layerNames.contains("Nav"), "Should have Nav layer")
        XCTAssertTrue(layerNames.contains("Fn"), "Should have Fn layer")
        XCTAssertTrue(layerNames.contains("Idea"), "Should have Idea layer")
    }
    
    func testBaseLayerHas58Bindings() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let baseLayer = keymap?.layers.first { $0.name == "Base" }
        
        XCTAssertEqual(baseLayer?.bindings.count, 58, "Base layer should have 58 bindings (Flake L format)")
    }
    
    func testFindsVerticalCombos() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertGreaterThanOrEqual(keymap?.combos.count ?? 0, 18, "Should find at least 18 combos")
        
        let comboNames = keymap?.combos.map { $0.name } ?? []
        XCTAssertTrue(comboNames.contains("combo_excl"), "Should find combo_excl (Q+A=!)")
        XCTAssertTrue(comboNames.contains("combo_at"), "Should find combo_at (W+S=@)")
        XCTAssertTrue(comboNames.contains("combo_hash"), "Should find combo_hash (E+D=#)")
    }
    
    func testComboExclHasCorrectPositions() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let comboExcl = keymap?.combos.first { $0.name == "combo_excl" }
        
        XCTAssertEqual(comboExcl?.positions, [13, 25], "combo_excl should be Q+A (positions 13 and 25)")
    }
    
    func testFindsEnterCombos() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        
        let enterRight = keymap?.combos.first { $0.name == "combo_enter_right" }
        XCTAssertEqual(enterRight?.positions, [31, 32, 33], "combo_enter_right should be J+K+L")
        
        let enterLeft = keymap?.combos.first { $0.name == "combo_enter_left" }
        XCTAssertEqual(enterLeft?.positions, [26, 27, 28], "combo_enter_left should be S+D+F")
    }
    
    func testLeftHandSymbolCombos() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let combos = keymap?.combos ?? []
        
        let expectedLeftHandCombos: [(name: String, positions: [Int])] = [
            ("combo_excl", [13, 25]),
            ("combo_at", [14, 26]),
            ("combo_hash", [15, 27]),
            ("combo_dllr", [16, 28]),
            ("combo_prcnt", [17, 29]),
            ("combo_grave", [25, 37]),
            ("combo_bslh", [26, 38]),
            ("combo_equal", [27, 39]),
            ("combo_tilde", [28, 40]),
        ]
        
        for expected in expectedLeftHandCombos {
            let combo = combos.first { $0.name == expected.name }
            XCTAssertNotNil(combo, "Should find \(expected.name)")
            XCTAssertEqual(combo?.positions, expected.positions, "\(expected.name) should have positions \(expected.positions)")
        }
    }
    
    func testRightHandSymbolCombos() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let combos = keymap?.combos ?? []
        
        let expectedRightHandCombos: [(name: String, positions: [Int])] = [
            ("combo_caret", [18, 30]),
            ("combo_plus", [19, 31]),
            ("combo_star", [20, 32]),
            ("combo_amps", [21, 33]),
            ("combo_under", [30, 42]),
            ("combo_minus", [31, 43]),
            ("combo_fslh", [32, 44]),
            ("combo_pipe", [33, 45]),
        ]
        
        for expected in expectedRightHandCombos {
            let combo = combos.first { $0.name == expected.name }
            XCTAssertNotNil(combo, "Should find \(expected.name)")
            XCTAssertEqual(combo?.positions, expected.positions, "\(expected.name) should have positions \(expected.positions)")
        }
    }
    
    func testNavLayerHasArrowBindings() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let navLayer = keymap?.layers.first { $0.name == "Nav" }
        
        XCTAssertNotNil(navLayer, "Should find Nav layer")
        XCTAssertEqual(navLayer?.bindings.count, 58, "Nav layer should have 58 bindings")
    }
    
    func testNumLayerHasNumberBindings() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        
        let keymap = KeymapParser.parse(from: content)
        let numLayer = keymap?.layers.first { $0.name == "Num" }
        
        XCTAssertNotNil(numLayer, "Should find Num layer")
        XCTAssertEqual(numLayer?.bindings.count, 58, "Num layer should have 58 bindings")
    }
    
    func testAppStateCanLoadRealKeymap() throws {
        let appState = AppState()
        
        appState.loadKeymapFromFile(keymapPath)
        
        XCTAssertNotNil(appState.keymap, "AppState should successfully load the keymap")
        XCTAssertEqual(appState.keymapPath, keymapPath, "AppState should store the keymap path")
        XCTAssertEqual(appState.keymap?.layers.count, 5, "Loaded keymap should have 5 layers")
    }
}
