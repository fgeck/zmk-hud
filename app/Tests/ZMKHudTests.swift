import XCTest

final class ZMKHudTests: XCTestCase {
    func testKeymapParserFindsLayers() throws {
        let keymapContent = """
        keymap {
            compatible = "zmk,keymap";
            
            base {
                display-name = "Base";
                bindings = <&kp Q &kp W &kp E>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: keymapContent)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.layers.count, 1)
        XCTAssertEqual(keymap?.layers.first?.name, "Base")
    }
    
    func testKeymapParserParsesBindings() throws {
        let keymapContent = """
        keymap {
            compatible = "zmk,keymap";
            
            test {
                display-name = "Test";
                bindings = <&kp A &mo 1 &trans &none>;
            };
        };
        """
        
        let keymap = KeymapParser.parse(from: keymapContent)
        
        XCTAssertNotNil(keymap)
        XCTAssertEqual(keymap?.layers.first?.bindings.count, 4)
    }
}
