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
}
