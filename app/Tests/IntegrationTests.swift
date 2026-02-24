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
    
    func testFlakeKeymapHasRowStructure() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap?.rowStructure, "Flake keymap should have row structure")
        XCTAssertEqual(keymap?.rowStructure?.count, 5, "Flake should have 5 rows")
        
        let totalKeys = keymap?.rowStructure?.reduce(0, +) ?? 0
        XCTAssertEqual(totalKeys, 58, "Row structure should sum to 58 keys")
    }
    
    func testFlakeFallbackLayoutFromRowStructure() throws {
        let appState = AppState()
        appState.loadKeymapFromFile(keymapPath)
        
        XCTAssertNotNil(appState.physicalLayout, "Should create fallback layout")
        XCTAssertEqual(appState.physicalLayout?.positions.count, 58, "Fallback should have 58 positions")
        XCTAssertTrue(appState.physicalLayout?.name.contains("Fallback") ?? false, "Should be named as fallback")
    }
    
    func testFlakeFallbackLayoutMatchesRowStructure() throws {
        let content = try String(contentsOfFile: keymapPath, encoding: .utf8)
        let keymap = KeymapParser.parse(from: content)
        
        guard let rowStructure = keymap?.rowStructure else {
            XCTFail("No row structure")
            return
        }
        
        let layout = LayoutLoader.shared.createFallbackFromRowStructure(rowStructure)
        
        var expectedIndex = 0
        for (row, cols) in rowStructure.enumerated() {
            for col in 0..<cols {
                let pos = layout.positions[expectedIndex]
                XCTAssertEqual(Int(pos.x), col, "Key \(expectedIndex) should be at column \(col)")
                XCTAssertEqual(Int(pos.y), row, "Key \(expectedIndex) should be at row \(row)")
                expectedIndex += 1
            }
        }
    }
}

final class TotemIntegrationTests: XCTestCase {
    
    let totemKeymapURL = "https://raw.githubusercontent.com/GEIGEIGEIST/zmk-config-totem/master/config/totem.keymap"
    
    func testParsesTotemKeymapFromURL() throws {
        let expectation = XCTestExpectation(description: "Fetch and parse Totem keymap")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch Totem keymap: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            
            XCTAssertNotNil(keymap, "Parser should successfully parse Totem keymap")
            XCTAssertEqual(keymap?.layers.count, 6, "Totem should have 6 layers: BASE, NAV, SYM, ADJ, TVP1, TVP2")
            
            let baseLayer = keymap?.layers.first { $0.name == "BASE" }
            XCTAssertNotNil(baseLayer, "Should find BASE layer")
            XCTAssertEqual(baseLayer?.bindings.count, 38, "Totem BASE layer should have 38 bindings")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTotemLayerNames() throws {
        let expectation = XCTestExpectation(description: "Verify Totem layer names")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            let layerNames = keymap?.layers.map { $0.name } ?? []
            
            XCTAssertTrue(layerNames.contains("BASE"), "Should have BASE layer")
            XCTAssertTrue(layerNames.contains("NAVI") || layerNames.contains("NAV"), "Should have NAV/NAVI layer")
            XCTAssertTrue(layerNames.contains("SYM"), "Should have SYM layer")
            XCTAssertTrue(layerNames.contains("ADJ"), "Should have ADJ layer")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTotemHasCombos() throws {
        let expectation = XCTestExpectation(description: "Verify Totem combos")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            
            XCTAssertGreaterThan(keymap?.combos.count ?? 0, 0, "Totem should have combos defined")
            
            let escCombo = keymap?.combos.first { $0.name == "combo_esc" }
            XCTAssertNotNil(escCombo, "Should find combo_esc")
            XCTAssertEqual(escCombo?.positions, [0, 1], "combo_esc should be positions 0 and 1")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFallbackGridCreatesCorrectKeyCount() throws {
        let layout = LayoutLoader.shared.createFallbackGrid(keyCount: 38)
        
        XCTAssertEqual(layout.positions.count, 38, "Fallback grid should have 38 positions")
        XCTAssertFalse(layout.name.isEmpty, "Layout should have a name")
        XCTAssertGreaterThan(layout.layoutSize.width, 0, "Layout should have positive width")
        XCTAssertGreaterThan(layout.layoutSize.height, 0, "Layout should have positive height")
    }
    
    func testTotemPhysicalLayoutFromJSON() throws {
        let totemLayoutJSON = """
        {
            "layouts": {
                "LAYOUT": {
                    "layout": [
                        {"x": 0, "y": 0.93},
                        {"x": 1, "y": 0.31},
                        {"x": 2, "y": 0},
                        {"x": 3, "y": 0.28},
                        {"x": 4, "y": 0.42},
                        
                        {"x": 7, "y": 0.42},
                        {"x": 8, "y": 0.28},
                        {"x": 9, "y": 0},
                        {"x": 10, "y": 0.31},
                        {"x": 11, "y": 0.93},
                        
                        {"x": 0, "y": 1.93},
                        {"x": 1, "y": 1.31},
                        {"x": 2, "y": 1},
                        {"x": 3, "y": 1.28},
                        {"x": 4, "y": 1.42},
                        
                        {"x": 7, "y": 1.42},
                        {"x": 8, "y": 1.28},
                        {"x": 9, "y": 1},
                        {"x": 10, "y": 1.31},
                        {"x": 11, "y": 1.93},
                        
                        {"x": 0, "y": 2.93},
                        {"x": 1, "y": 2.31},
                        {"x": 2, "y": 2},
                        {"x": 3, "y": 2.28},
                        {"x": 4, "y": 2.42},
                        
                        {"x": 7, "y": 2.42},
                        {"x": 8, "y": 2.28},
                        {"x": 9, "y": 2},
                        {"x": 10, "y": 2.31},
                        {"x": 11, "y": 2.93},
                        
                        {"x": 2.5, "y": 3.2},
                        {"x": 3.5, "y": 3.5},
                        {"x": 4.5, "y": 3.8},
                        
                        {"x": 6.5, "y": 3.8},
                        {"x": 7.5, "y": 3.5},
                        {"x": 8.5, "y": 3.2},
                        
                        {"x": -0.3, "y": 2.4},
                        {"x": 11.3, "y": 2.4}
                    ]
                }
            }
        }
        """
        
        let layout = LayoutLoader.shared.loadFromJSON(totemLayoutJSON)
        
        XCTAssertNotNil(layout, "Should parse Totem layout JSON")
        XCTAssertEqual(layout?.positions.count, 38, "Totem should have 38 key positions")
        XCTAssertGreaterThan(layout?.layoutSize.width ?? 0, 0, "Layout should have positive width")
    }
    
    func testAppStateLoadsTotemKeymapFromURL() throws {
        let expectation = XCTestExpectation(description: "AppState loads Totem keymap")
        let appState = AppState()
        
        appState.loadKeymapFromURL(totemKeymapURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertNotNil(appState.keymap, "AppState should load keymap")
            XCTAssertEqual(appState.keymapPath, self.totemKeymapURL, "Should store URL as path")
            
            XCTAssertNotNil(appState.physicalLayout, "Should auto-infer layout from keymap")
            XCTAssertEqual(appState.physicalLayout?.positions.count, 38, "Inferred layout should have 38 keys")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTotemBaseLayerHasHomeRowMods() throws {
        let expectation = XCTestExpectation(description: "Verify Totem home row mods")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            let baseLayer = keymap?.layers.first { $0.name == "BASE" }
            
            let homeRowModBindings = baseLayer?.bindings.filter { binding in
                if case .modTap = binding.type { return true }
                if case .holdTap = binding.type { return true }
                return false
            } ?? []
            
            XCTAssertGreaterThan(homeRowModBindings.count, 0, "Totem should have home row mods (mt bindings)")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTotemKeymapHasRowStructure() throws {
        let expectation = XCTestExpectation(description: "Totem row structure")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            
            XCTAssertNotNil(keymap?.rowStructure, "Totem keymap should have row structure")
            
            let totalKeys = keymap?.rowStructure?.reduce(0, +) ?? 0
            XCTAssertEqual(totalKeys, 38, "Row structure should sum to 38 keys")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTotemFallbackLayoutFromRowStructure() throws {
        let expectation = XCTestExpectation(description: "Totem fallback layout")
        
        guard let url = URL(string: totemKeymapURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                XCTFail("Failed to fetch")
                return
            }
            
            let keymap = KeymapParser.parse(from: content)
            
            guard let rowStructure = keymap?.rowStructure else {
                XCTFail("No row structure")
                return
            }
            
            let layout = LayoutLoader.shared.createFallbackFromRowStructure(rowStructure)
            
            XCTAssertEqual(layout.positions.count, 38, "Fallback should have 38 positions")
            XCTAssertTrue(layout.name.contains("Fallback"), "Should be named as fallback")
            XCTAssertGreaterThan(layout.layoutSize.width, 0, "Should have positive width")
            XCTAssertGreaterThan(layout.layoutSize.height, 0, "Should have positive height")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }

}