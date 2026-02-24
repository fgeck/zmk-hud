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
        
        // Use new OrthoLayoutGenerator instead of old LayoutLoader
        let generator = OrthoLayoutGenerator(
            split: true,
            rows: rowStructure.count,
            columns: (rowStructure.first ?? 10) / 2,
            thumbs: .count(rowStructure.last ?? 3)
        )
        let layout = generator.generate(keyW: 56, keyH: 56, splitGap: 30)
        
        XCTAssertGreaterThan(layout.count, 0, "Fallback should have keys")
    }
    
    func testFallbackLayoutIsSplit() throws {
        let keymap = KeymapParser.parse(from: sampleKeymapContent)
        guard let rowStructure = keymap?.rowStructure else {
            XCTFail("No row structure")
            return
        }
        let generator = OrthoLayoutGenerator(
            split: true,
            rows: rowStructure.count,
            columns: (rowStructure.first ?? 10) / 2,
            thumbs: .count(rowStructure.last ?? 3)
        )
        let layout = generator.generate(keyW: 56, keyH: 56, splitGap: 30)
        XCTAssertGreaterThan(layout.count, 0, "Should have keys")
        
        // Verify there's a gap between left and right halves
        let firstRowKeys = layout.keys.prefix(12)
        let leftHalf = firstRowKeys.prefix(6)
        let rightHalf = firstRowKeys.suffix(6)
        let leftMaxX = leftHalf.map { $0.pos.x }.max() ?? 0
        let rightMinX = rightHalf.map { $0.pos.x }.min() ?? 0
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
        // Use OrthoLayoutGenerator instead of old LayoutLoader
        let generator = OrthoLayoutGenerator(
            split: false,
            rows: 4,
            columns: 10,
            thumbs: .count(0)
        )
        let layout = generator.generate(keyW: 56, keyH: 56, splitGap: 0)
        
        XCTAssertGreaterThan(layout.count, 0, "Fallback grid should have keys")
        XCTAssertGreaterThan(layout.width, 0, "Layout should have positive width")
        XCTAssertGreaterThan(layout.height, 0, "Layout should have positive height")
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
        
        // Use QMKLayoutParser instead of old LayoutLoader
        let layout = QMKLayoutParser.parse(json: totemLayoutJSON)
        
        XCTAssertNotNil(layout, "Should parse Totem layout JSON")
        XCTAssertEqual(layout?.count, 38, "Totem should have 38 key positions")
        XCTAssertGreaterThan(layout?.width ?? 0, 0, "Layout should have positive width")
    }
    
    func testAppStateLoadsTotemKeymapFromURL() throws {
        let expectation = XCTestExpectation(description: "AppState loads Totem keymap")
        let appState = AppState()
        
        appState.loadKeymapFromURL(totemKeymapURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            XCTAssertNotNil(appState.keymap, "AppState should load keymap")
            XCTAssertEqual(appState.keymapPath, self.totemKeymapURL, "Should store URL as path")
            
            XCTAssertNotNil(appState.physicalLayout, "Should auto-create fallback layout from keymap")
            XCTAssertTrue(appState.physicalLayout?.count ?? 0 > 0, "Fallback layout should have keys")
            
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
            
            // Use OrthoLayoutGenerator instead of old LayoutLoader
            let generator = OrthoLayoutGenerator(
                split: true,
                rows: rowStructure.count,
                columns: (rowStructure.first ?? 10) / 2,
                thumbs: .count(rowStructure.last ?? 3)
            )
            let layout = generator.generate(keyW: 56, keyH: 56, splitGap: 30)
            
            XCTAssertGreaterThan(layout.count, 0, "Fallback should have keys")
            XCTAssertGreaterThan(layout.width, 0, "Should have positive width")
            XCTAssertGreaterThan(layout.height, 0, "Should have positive height")
        }.resume()
        
        wait(for: [expectation], timeout: 10.0)
    }
}

final class FlakeLayoutTests: XCTestCase {
    let flakeLayoutURL = "https://raw.githubusercontent.com/anywhy-io/flake-zmk-module/main/anywhy_flake.json"
    
    func testDetectsMultipleLayouts() throws {
        let expectation = XCTestExpectation(description: "Detect multiple layouts")
        guard let url = URL(string: flakeLayoutURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            let layouts = QMKLayoutParser.availableLayouts(from: data)
            XCTAssertEqual(layouts.count, 3, "Should detect 3 layout options")
        }.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsLargeLayout() throws {
        let expectation = XCTestExpectation(description: "Load large layout")
        guard let url = URL(string: flakeLayoutURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            let layout = QMKLayoutParser.parse(data: data, layoutName: "large_layout")
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.count, 58, "Large layout should have 58 keys")
        }.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsMediumLayout() throws {
        let expectation = XCTestExpectation(description: "Load medium layout")
        guard let url = URL(string: flakeLayoutURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            let layout = QMKLayoutParser.parse(data: data, layoutName: "medium_layout")
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.count, 46, "Medium layout should have 46 keys")
        }.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testLoadsSmallLayout() throws {
        let expectation = XCTestExpectation(description: "Load small layout")
        guard let url = URL(string: flakeLayoutURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            let layout = QMKLayoutParser.parse(data: data, layoutName: "small_layout")
            XCTAssertNotNil(layout)
            XCTAssertEqual(layout?.count, 40, "Small layout should have 40 keys")
        }.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    func testLargeLayoutHasRotatedThumbKeys() throws {
        let expectation = XCTestExpectation(description: "Check rotated thumb keys")
        guard let url = URL(string: flakeLayoutURL) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            guard let layout = QMKLayoutParser.parse(data: data, layoutName: "large_layout") else {
                XCTFail("Layout should not be nil")
                return
            }
            let rotatedKeys = layout.keys.filter { $0.rotation != 0 }
            XCTAssertEqual(rotatedKeys.count, 4, "Should have 4 rotated thumb keys")
            let positiveRotation = rotatedKeys.filter { $0.rotation > 0 }
            let negativeRotation = rotatedKeys.filter { $0.rotation < 0 }
            XCTAssertEqual(positiveRotation.count, 2, "Left thumb keys")
            XCTAssertEqual(negativeRotation.count, 2, "Right thumb keys")
        }.resume()
        wait(for: [expectation], timeout: 10.0)
    }
}

final class RotationTests: XCTestCase {
    
    func testNoRotationReturnsOriginalPosition() {
        // Use new PhysicalKey instead of old KeyPosition
        let key = PhysicalKey(id: 0, pos: Point(x: 5.0, y: 3.0), width: 56, height: 56, rotation: 0)
        
        XCTAssertEqual(key.rotation, 0)
        XCTAssertEqual(key.pos.x, 5.0)
        XCTAssertEqual(key.pos.y, 3.0)
    }
    
    func testRotationIsStoredCorrectly() {
        let key = PhysicalKey(id: 0, pos: Point(x: 5.0, y: 4.25), width: 56, height: 56, rotation: 15)
        
        XCTAssertEqual(key.rotation, 15)
    }
    
    func testFlakeThumbKeyRotationValues() throws {
        let expectation = XCTestExpectation(description: "Check Flake rotation values")
        let urlString = "https://raw.githubusercontent.com/anywhy-io/flake-zmk-module/main/anywhy_flake.json"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { expectation.fulfill() }
            guard let data = data else {
                XCTFail("Failed to fetch")
                return
            }
            guard let layout = QMKLayoutParser.parse(data: data, layoutName: "large_layout") else {
                XCTFail("Layout should load")
                return
            }
            
            let rotatedKeys = layout.keys.filter { $0.rotation != 0 }
            XCTAssertEqual(rotatedKeys.count, 4)
            
            guard let leftInnerThumb = rotatedKeys.first(where: { $0.rotation == 30 }) else {
                XCTFail("Should have left inner thumb with 30 degree rotation")
                return
            }
            XCTAssertEqual(leftInnerThumb.pos.x, 6.0 * 56 + 28, accuracy: 15.0)  // Remote data may vary
        }.resume()
        
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
