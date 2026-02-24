import XCTest
@testable import ZMKHud

final class IntegrationTests: XCTestCase {
    
    var sampleKeymapContent: String!
    
    override func setUp() {
        super.setUp()
        sampleKeymapContent = """
/ {
    keymap {
        compatible = "zmk,keymap";

        Base {
            display-name = "Base";
            bindings = <
&none       &none     &none     &none      &none      &none          &none    &none     &none      &none      &none      &none
&kp ENTER   &kp Q     &kp W     &kp E      &kp R      &kp T          &kp Y    &kp U     &kp I      &kp O      &kp P      &kp BSPC
&kp TAB     &kp A     &kp S     &kp D      &kp F      &kp G          &kp H    &kp J     &kp K      &kp L      &kp SEMI   &kp SQT
&kp LBKT    &kp Z     &kp X     &kp C      &kp V      &kp B          &kp N    &kp M     &kp COMMA  &kp DOT    &kp FSLH   &kp RBKT
                      &mo 4     &kp LALT   &kp LGUI   &kp SPACE &mo 1     &mo 2  &kp RSHFT &kp RGUI   &kp RALT   &mo 3
            >;
        };

        Num {
            display-name = "Num";
            bindings = <
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &kp N1    &kp N2    &kp N3     &kp N4     &kp N5         &kp N6   &kp N7    &kp N8     &kp N9     &kp N0     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &kp N4    &kp N5     &kp N6     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &kp N1    &kp N2     &kp N3     &trans     &trans
                      &trans    &trans     &trans     &trans    &trans    &trans &kp N0    &trans     &trans     &trans
            >;
        };

        Nav {
            display-name = "Nav";
            bindings = <
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &kp UP     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &kp LEFT  &kp DOWN   &kp RIGHT  &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
                      &trans    &trans     &trans     &trans    &trans    &trans &trans    &trans     &trans     &trans
            >;
        };

        Fn {
            display-name = "Fn";
            bindings = <
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &kp F1    &kp F2    &kp F3     &kp F4     &kp F5         &kp F6   &kp F7    &kp F8     &kp F9     &kp F10    &trans
&trans      &kp F11   &kp F12   &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
                      &trans    &trans     &trans     &trans    &trans    &trans &trans    &trans     &trans     &trans
            >;
        };

        Idea {
            display-name = "Idea";
            bindings = <
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
&trans      &trans    &trans    &trans     &trans     &trans         &trans   &trans    &trans     &trans     &trans     &trans
                      &trans    &trans     &trans     &trans    &trans    &trans &trans    &trans     &trans     &trans
            >;
        };
    };

    combos {
        compatible = "zmk,combos";

        combo_excl {
            key-positions = <13 25>;
            bindings = <&kp EXCL>;
        };

        combo_at {
            key-positions = <14 26>;
            bindings = <&kp AT>;
        };

        combo_hash {
            key-positions = <15 27>;
            bindings = <&kp HASH>;
        };

        combo_enter_left {
            key-positions = <26 27 28>;
            bindings = <&kp ENTER>;
        };

        combo_enter_right {
            key-positions = <31 32 33>;
            bindings = <&kp ENTER>;
        };
    };
};
"""
    }
    
    func testParsesKeymap() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        XCTAssertNotNil(keymap, "Parser should successfully parse the keymap")
    }
    
    func testFindsAllFiveLayers() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        
        XCTAssertEqual(keymap?.layers.count, 5, "Should find all 5 layers")
        
        let layerNames = keymap?.layers.map { $0.name } ?? []
        XCTAssertTrue(layerNames.contains("Base"), "Should have Base layer")
        XCTAssertTrue(layerNames.contains("Num"), "Should have Num layer")
        XCTAssertTrue(layerNames.contains("Nav"), "Should have Nav layer")
        XCTAssertTrue(layerNames.contains("Fn"), "Should have Fn layer")
        XCTAssertTrue(layerNames.contains("Idea"), "Should have Idea layer")
    }
    
    func testBaseLayerHas58Bindings() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        let baseLayer = keymap?.layers.first { $0.name == "Base" }
        
        XCTAssertEqual(baseLayer?.bindings.count, 58, "Base layer should have 58 bindings")
    }
    
    func testFindsVerticalCombos() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        
        XCTAssertGreaterThanOrEqual(keymap?.combos.count ?? 0, 5, "Should find at least 5 combos")
        
        let comboNames = keymap?.combos.map { $0.name } ?? []
        XCTAssertTrue(comboNames.contains("combo_excl"), "Should find combo_excl")
        XCTAssertTrue(comboNames.contains("combo_at"), "Should find combo_at")
        XCTAssertTrue(comboNames.contains("combo_hash"), "Should find combo_hash")
    }
    
    func testComboExclHasCorrectPositions() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        let comboExcl = keymap?.combos.first { $0.name == "combo_excl" }
        
        XCTAssertEqual(comboExcl?.positions, [13, 25], "combo_excl should be positions 13 and 25")
    }
    
    func testFindsEnterCombos() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        
        let enterRight = keymap?.combos.first { $0.name == "combo_enter_right" }
        XCTAssertEqual(enterRight?.positions, [31, 32, 33], "combo_enter_right should be J+K+L")
        
        let enterLeft = keymap?.combos.first { $0.name == "combo_enter_left" }
        XCTAssertEqual(enterLeft?.positions, [26, 27, 28], "combo_enter_left should be S+D+F")
    }
    
    func testKeymapHasRowStructure() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        
        XCTAssertNotNil(keymap?.rowStructure, "Keymap should have row structure")
        XCTAssertEqual(keymap?.rowStructure?.count, 5, "Should have 5 rows")
        
        let totalKeys = keymap?.rowStructure?.reduce(0, +) ?? 0
        XCTAssertEqual(totalKeys, 58, "Row structure should sum to 58 keys")
    }
    
    func testFallbackLayoutFromRowStructure() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        
        guard let rowStructure = keymap?.rowStructure else {
            XCTFail("No row structure")
            return
        }
        
        let layout = LayoutLoader.shared.createFallbackFromRowStructure(rowStructure)
        
        XCTAssertEqual(layout.positions.count, 58, "Fallback should have 58 positions")
        XCTAssertTrue(layout.name.contains("Fallback"), "Should be named as fallback")
    }
    
    func testFallbackLayoutIsSplit() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        guard let rowStructure = keymap?.rowStructure else {
            XCTFail("No row structure")
            return
        }
        let layout = LayoutLoader.shared.createFallbackFromRowStructure(rowStructure)
        XCTAssertEqual(layout.positions.count, 58, "Should have 58 positions")
        XCTAssertTrue(layout.name.contains("Split"), "Should be named as split fallback")
        // Verify there's a gap between left and right halves
        let firstRowPositions = layout.positions.prefix(12)
        let leftHalf = firstRowPositions.prefix(6)
        let rightHalf = firstRowPositions.suffix(6)
        let leftMaxX = leftHalf.map { $0.x }.max() ?? 0
        let rightMinX = rightHalf.map { $0.x }.min() ?? 0
        XCTAssertGreaterThan(rightMinX - leftMaxX, 1.0, "Should have gap between halves")
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
            XCTAssertEqual(keymap?.layers.count, 6, "Totem should have 6 layers")
            
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
            
            XCTAssertNotNil(appState.physicalLayout, "Should auto-create fallback layout from keymap")
            XCTAssertTrue(appState.physicalLayout?.positions.count ?? 0 > 0, "Fallback layout should have keys")
            
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

final class FlakeLayoutTests: XCTestCase {
    let flakeLayoutURL = "https://raw.githubusercontent.com/anywhy-io/flake-zmk-module/main/anywhy_flake.json"
    func testDetectsMultipleLayouts() throws {
        let expectation = XCTestExpectation(description: "Detect multiple layouts")
        LayoutLoader.shared.getAvailableLayoutsFromURL(flakeLayoutURL) { options in
            XCTAssertEqual(options.count, 3, "Should detect 3 layout options")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    func testLayoutOptionsHaveCorrectNames() throws {
        let expectation = XCTestExpectation(description: "Check layout names")
        LayoutLoader.shared.getAvailableLayoutsFromURL(flakeLayoutURL) { options in
            let names = options.map { $0.name }
            XCTAssertTrue(names.contains("Anywhy Flake L layout"), "Should have Large layout")
            XCTAssertTrue(names.contains("Anywhy Flake M layout"), "Should have Medium layout")
            XCTAssertTrue(names.contains("Anywhy Flake S layout"), "Should have Small layout")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    func testLayoutOptionsHaveCorrectKeyCounts() throws {
        let expectation = XCTestExpectation(description: "Check key counts")
        LayoutLoader.shared.getAvailableLayoutsFromURL(flakeLayoutURL) { options in
            let keyCounts = options.map { $0.keyCount }.sorted()
            XCTAssertEqual(keyCounts, [40, 46, 58], "Should have 40, 46, and 58 key layouts")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsLargeLayout() throws {
        let expectation = XCTestExpectation(description: "Load large layout")
        LayoutLoader.shared.loadFromURL(flakeLayoutURL, layoutId: "large_layout") { layout in
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.positions.count, 58, "Large layout should have 58 keys")
            XCTAssertEqual(layout?.name, "Anywhy Flake L layout")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsMediumLayout() throws {
        let expectation = XCTestExpectation(description: "Load medium layout")
        LayoutLoader.shared.loadFromURL(flakeLayoutURL, layoutId: "medium_layout") { layout in
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.positions.count, 46, "Medium layout should have 46 keys")
            XCTAssertEqual(layout?.name, "Anywhy Flake M layout")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsSmallLayout() throws {
        let expectation = XCTestExpectation(description: "Load small layout")
        LayoutLoader.shared.loadFromURL(flakeLayoutURL, layoutId: "small_layout") { layout in
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.positions.count, 40, "Small layout should have 40 keys")
            XCTAssertEqual(layout?.name, "Anywhy Flake S layout")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    func testLargeLayoutHasRotatedThumbKeys() throws {
        let expectation = XCTestExpectation(description: "Check rotated thumb keys")
        LayoutLoader.shared.loadFromURL(flakeLayoutURL, layoutId: "large_layout") { layout in
            guard let layout = layout else {
                XCTFail("Layout should not be nil")
                expectation.fulfill()
                return
            }
            let rotatedKeys = layout.positions.filter { $0.rotation != 0 }
            XCTAssertEqual(rotatedKeys.count, 4, "Should have 4 rotated thumb keys")
            let positiveRotation = rotatedKeys.filter { $0.rotation > 0 }
            let negativeRotation = rotatedKeys.filter { $0.rotation < 0 }
            XCTAssertEqual(positiveRotation.count, 2, "Left thumb keys")
            XCTAssertEqual(negativeRotation.count, 2, "Right thumb keys")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}

final class RotationTests: XCTestCase {
    
    func testNoRotationReturnsOriginalPosition() {
        let position = KeyPosition(index: 0, x: 5.0, y: 3.0, width: 1.0, height: 1.0, rotation: 0)
        
        XCTAssertEqual(position.rotation, 0)
        XCTAssertEqual(position.x, 5.0)
        XCTAssertEqual(position.y, 3.0)
        XCTAssertEqual(position.rotationOriginX, 5.0, "Default rotation origin should be key position")
        XCTAssertEqual(position.rotationOriginY, 3.0, "Default rotation origin should be key position")
    }
    
    func testRotationOriginIsStoredCorrectly() {
        let position = KeyPosition(
            index: 0,
            x: 5.0,
            y: 4.25,
            rotation: 15,
            rotationOriginX: 5.0,
            rotationOriginY: 5.25
        )
        
        XCTAssertEqual(position.rotation, 15)
        XCTAssertEqual(position.rotationOriginX, 5.0)
        XCTAssertEqual(position.rotationOriginY, 5.25)
    }
    
    func testFlakeThumbKeyRotationValues() throws {
        let expectation = XCTestExpectation(description: "Check Flake rotation values")
        let url = "https://raw.githubusercontent.com/anywhy-io/flake-zmk-module/main/anywhy_flake.json"
        
        LayoutLoader.shared.loadFromURL(url, layoutId: "large_layout") { layout in
            guard let layout = layout else {
                XCTFail("Layout should load")
                expectation.fulfill()
                return
            }
            
            let rotatedKeys = layout.positions.filter { $0.rotation != 0 }
            XCTAssertEqual(rotatedKeys.count, 4)
            guard let leftInnerThumb = rotatedKeys.first(where: { $0.rotation == 30 }) else {
                XCTFail("Should have left inner thumb with 30 degree rotation")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(Double(leftInnerThumb.x), 6.0, accuracy: 0.01)
            XCTAssertEqual(Double(leftInnerThumb.rotationOriginX), 6.3, accuracy: 0.01)
            XCTAssertEqual(Double(leftInnerThumb.rotationOriginY), 5.6, accuracy: 0.01)
            
            guard let rightInnerThumb = rotatedKeys.first(where: { $0.rotation == -30 }) else {
                XCTFail("Should have right inner thumb with -30 degree rotation")
                expectation.fulfill()
                return
            }
            XCTAssertEqual(Double(rightInnerThumb.x), 9.0, accuracy: 0.01)
            XCTAssertEqual(Double(rightInnerThumb.rotationOriginX), 9.7, accuracy: 0.01)
            XCTAssertEqual(Double(rightInnerThumb.rotationOriginY), 5.6, accuracy: 0.01)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testRotationTransformCalculation() {
        let keyUnit: CGFloat = 56
        let x: CGFloat = 6.0 * keyUnit
        let y: CGFloat = 4.7 * keyUnit
        let width: CGFloat = 1.0 * keyUnit
        let height: CGFloat = 1.0 * keyUnit
        let rotation: CGFloat = 30
        let pivotX: CGFloat = 6.3 * keyUnit
        let pivotY: CGFloat = 5.6 * keyUnit
        
        let keyCenterX = x + width / 2
        let keyCenterY = y + height / 2
        
        let dx = keyCenterX - pivotX
        let dy = keyCenterY - pivotY
        
        let angleRad = rotation * .pi / 180
        
        let newX = pivotX + dx * cos(angleRad) - dy * sin(angleRad)
        let newY = pivotY + dx * sin(angleRad) + dy * cos(angleRad)
        
        XCTAssertNotEqual(newX, keyCenterX, "X should change after rotation")
        XCTAssertNotEqual(newY, keyCenterY, "Y should change after rotation")
        
        let distanceBefore = sqrt(dx * dx + dy * dy)
        let dxAfter = newX - pivotX
        let dyAfter = newY - pivotY
        let distanceAfter = sqrt(dxAfter * dxAfter + dyAfter * dyAfter)
        
        XCTAssertEqual(distanceBefore, distanceAfter, accuracy: 0.001, "Distance from pivot should remain constant")
    }
    
    func testOppositeRotationsAreSymmetric() {
        let keyUnit: CGFloat = 56
        let pivotY: CGFloat = 5.6 * keyUnit
        
        let leftX: CGFloat = 6.0 * keyUnit
        let leftPivotX: CGFloat = 6.3 * keyUnit
        let leftRotation: CGFloat = 30
        
        let rightX: CGFloat = 9.0 * keyUnit
        let rightPivotX: CGFloat = 9.7 * keyUnit
        let rightRotation: CGFloat = -30
        
        let y: CGFloat = 4.7 * keyUnit
        let width: CGFloat = 1.0 * keyUnit
        let height: CGFloat = 1.0 * keyUnit
        
        func transform(centerX: CGFloat, centerY: CGFloat, pivotX: CGFloat, pivotY: CGFloat, rotation: CGFloat) -> (x: CGFloat, y: CGFloat) {
            let dx = centerX - pivotX
            let dy = centerY - pivotY
            let angleRad = rotation * .pi / 180
            let newX = pivotX + dx * cos(angleRad) - dy * sin(angleRad)
            let newY = pivotY + dx * sin(angleRad) + dy * cos(angleRad)
            return (newX, newY)
        }
        
        let leftCenter = (x: leftX + width / 2, y: y + height / 2)
        let rightCenter = (x: rightX + width / 2, y: y + height / 2)
        
        let leftTransformed = transform(centerX: leftCenter.x, centerY: leftCenter.y, pivotX: leftPivotX, pivotY: pivotY, rotation: leftRotation)
        let rightTransformed = transform(centerX: rightCenter.x, centerY: rightCenter.y, pivotX: rightPivotX, pivotY: pivotY, rotation: rightRotation)
        
        XCTAssertEqual(leftTransformed.y, rightTransformed.y, accuracy: 1.0, "Y positions should be approximately equal for symmetric rotations")
    }
}
