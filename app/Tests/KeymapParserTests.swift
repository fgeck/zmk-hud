import XCTest
@testable import ZMKHud

final class KeymapParserTests: XCTestCase {
    
    func testParsesLayerWithDisplayName() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                display-name = "Base";
                bindings = <&kp Q &kp W &kp E>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.layers.count, 1)
        XCTAssertEqual(keymap?.layers.first?.name, "Base")
    }
    
    func testParsesMultipleLayers() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                display-name = "Base";
                bindings = <&kp A>;
            };
            nav {
                display-name = "Nav";
                bindings = <&kp LEFT>;
            };
            num {
                display-name = "Num";
                bindings = <&kp N1>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertEqual(keymap?.layers.count, 3)
        XCTAssertEqual(keymap?.layers[0].name, "Base")
        XCTAssertEqual(keymap?.layers[1].name, "Nav")
        XCTAssertEqual(keymap?.layers[2].name, "Num")
    }
    
    func testParsesKeyPressBinding() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            test {
                display-name = "Test";
                bindings = <&kp A &kp SPACE &kp ENTER>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 3)
        XCTAssertEqual(bindings?[0].displayLabel, "A")
        XCTAssertEqual(bindings?[1].displayLabel, "␣")
        XCTAssertEqual(bindings?[2].displayLabel, "⏎")
    }
    
    func testParsesMomentaryLayerBinding() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            test {
                display-name = "Test";
                bindings = <&mo 1 &mo 2 &mo 3>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 3)
        XCTAssertEqual(bindings?[0].displayLabel, "L1")
        XCTAssertEqual(bindings?[1].displayLabel, "L2")
        XCTAssertEqual(bindings?[2].displayLabel, "L3")
    }
    
    func testParsesTransparentAndNoneBindings() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            test {
                display-name = "Test";
                bindings = <&trans &none &kp X>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 3)
        XCTAssertEqual(bindings?[0].displayLabel, "▽")
        XCTAssertEqual(bindings?[1].displayLabel, "")
        XCTAssertEqual(bindings?[2].displayLabel, "X")
    }
    
    func testParsesModTapBinding() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            test {
                display-name = "Test";
                bindings = <&mt LSHIFT A &mt LCTRL B>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 2)
        XCTAssertEqual(bindings?[0].displayLabel, "A")
        XCTAssertEqual(bindings?[0].holdLabel, "⇧")
        XCTAssertEqual(bindings?[1].displayLabel, "B")
        XCTAssertEqual(bindings?[1].holdLabel, "⌃")
    }
    
    func testParsesCombos() throws {
        let content = """
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
        };
        keymap {
            compatible = "zmk,keymap";
            base {
                display-name = "Base";
                bindings = <&kp Q>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertEqual(keymap?.combos.count, 2)
        XCTAssertEqual(keymap?.combos[0].name, "combo_excl")
        XCTAssertEqual(keymap?.combos[0].positions, [13, 25])
        XCTAssertEqual(keymap?.combos[0].result.displayLabel, "!")
        XCTAssertEqual(keymap?.combos[1].name, "combo_at")
        XCTAssertEqual(keymap?.combos[1].positions, [14, 26])
    }
    
    func testParsesThreeKeyCombo() throws {
        let content = """
        combos {
            compatible = "zmk,combos";
            combo_enter {
                key-positions = <31 32 33>;
                bindings = <&kp ENTER>;
            };
        };
        keymap {
            compatible = "zmk,keymap";
            base {
                display-name = "Base";
                bindings = <&kp Q>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertEqual(keymap?.combos.first?.positions, [31, 32, 33])
    }
    
    func testRemovesLineComments() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            // This is a comment
            base {
                display-name = "Base"; // inline comment
                bindings = <&kp Q>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.layers.count, 1)
    }
    
    func testRemovesBlockComments() throws {
        let content = """
        /*
         * Multi-line block comment
         */
        keymap {
            compatible = "zmk,keymap";
            base {
                display-name = "Base";
                bindings = <&kp Q>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.layers.count, 1)
    }
    
    func testReturnsNilForInvalidContent() throws {
        let content = "not a valid keymap"
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNil(keymap)
    }
    
    func testReturnsNilForEmptyContent() throws {
        let keymap = KeymapParser.parse(from: "")
        
        XCTAssertNil(keymap)
    }
    
    // MARK: - New Behavior Tests
    
    func testParsesCapsWordBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&caps_word>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .capsWord = binding?.type {
            // Success
        } else {
            XCTFail("Expected capsWord binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "CAPS")
    }
    
    func testParsesKeyRepeatBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&key_repeat>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .keyRepeat = binding?.type {
            // Success
        } else {
            XCTFail("Expected keyRepeat binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "⟳")
    }
    
    func testParsesStickyLayerBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&sl 2>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .stickyLayer(let layer) = binding?.type {
            XCTAssertEqual(layer, 2)
        } else {
            XCTFail("Expected stickyLayer binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "S2")
    }
    
    func testParsesToggleLayerBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&tog 1>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .toggleLayer(let layer) = binding?.type {
            XCTAssertEqual(layer, 1)
        } else {
            XCTFail("Expected toggleLayer binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "T1")
    }
    
    func testParsesToLayerBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&to 3>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .toLayer(let layer) = binding?.type {
            XCTAssertEqual(layer, 3)
        } else {
            XCTFail("Expected toLayer binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "→L3")
    }
    
    func testParsesBootloaderBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&bootloader>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .bootloader = binding?.type {
            // Success
        } else {
            XCTFail("Expected bootloader binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "Boot")
    }
    
    func testParsesResetBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&sys_reset>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let binding = keymap?.layers.first?.bindings.first
        
        XCTAssertNotNil(binding)
        if case .reset = binding?.type {
            // Success
        } else {
            XCTFail("Expected reset binding type")
        }
        XCTAssertEqual(binding?.displayLabel, "Reset")
    }
    
    func testParsesBluetoothBehaviors() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&bt BT_CLR &bt BT_SEL 0 &bt BT_NXT>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 3)
        XCTAssertEqual(bindings?[0].displayLabel, "BT✕")
        XCTAssertEqual(bindings?[1].displayLabel, "BT1")
        XCTAssertEqual(bindings?[2].displayLabel, "BT▶")
    }
    
    func testParsesOutputSelectBehavior() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&out OUT_USB &out OUT_BLE &out OUT_TOG>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 3)
        XCTAssertEqual(bindings?[0].displayLabel, "USB")
        XCTAssertEqual(bindings?[1].displayLabel, "BLE")
        XCTAssertEqual(bindings?[2].displayLabel, "⇄")
    }
    
    // MARK: - Behavior Definition Parsing Tests
    
    func testParsesBehaviorDefinitions() throws {
        let content = """
        / {
            behaviors {
                hml: hml {
                    compatible = "zmk,behavior-hold-tap";
                    #binding-cells = <2>;
                    flavor = "balanced";
                    tapping-term-ms = <280>;
                    bindings = <&kp>, <&kp>;
                };
                td_a: td_a {
                    compatible = "zmk,behavior-tap-dance";
                    #binding-cells = <0>;
                    bindings = <&kp A>, <&kp B>;
                };
            };
        };
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&hml LGUI A>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.behaviors.count, 2)
        
        // Check hml behavior
        let hml = keymap?.behaviors["hml"]
        XCTAssertNotNil(hml)
        XCTAssertEqual(hml?.type, "zmk,behavior-hold-tap")
        XCTAssertTrue(hml?.bindings.contains("&kp") ?? false)  // bindings are parsed from <&kp>, <&kp>;
        
        // Check td_a behavior
        let td = keymap?.behaviors["td_a"]
        XCTAssertNotNil(td)
        XCTAssertEqual(td?.type, "zmk,behavior-tap-dance")
    }
    
    func testParsesHomeRowModBinding() throws {
        let content = """
        keymap {
            compatible = "zmk,keymap";
            base {
                bindings = <&hml LGUI A &hmr RALT SEMI>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: content)
        let bindings = keymap?.layers.first?.bindings
        
        XCTAssertEqual(bindings?.count, 2)
        
        // First binding: &hml LGUI A
        if case .holdTap(let hold, let tap) = bindings?[0].type {
            XCTAssertEqual(hold, "⌘")  // LGUI -> ⌘
            XCTAssertEqual(tap, "A")
        } else {
            XCTFail("Expected holdTap binding type")
        }
        
        // Second binding: &hmr RALT SEMI
        if case .holdTap(let hold, let tap) = bindings?[1].type {
            XCTAssertEqual(hold, "⌥")  // RALT -> ⌥
            XCTAssertEqual(tap, ";")  // SEMI -> ;
        } else {
            XCTFail("Expected holdTap binding type")
        }
    }
}
