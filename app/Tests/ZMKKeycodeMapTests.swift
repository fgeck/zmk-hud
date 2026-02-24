import XCTest
@testable import ZMKHud

final class ZMKKeycodeMapTests: XCTestCase {
    
    // MARK: - Modifier Symbols
    
    func testLeftShiftMapsToSymbol() {
        XCTAssertEqual(ZMKKeycodeMap.convert("LSHFT"), "⇧")
        XCTAssertEqual(ZMKKeycodeMap.convert("LSHIFT"), "⇧")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT_SHIFT"), "⇧")
    }
    
    func testRightShiftMapsToSymbol() {
        XCTAssertEqual(ZMKKeycodeMap.convert("RSHFT"), "⇧")
        XCTAssertEqual(ZMKKeycodeMap.convert("RSHIFT"), "⇧")
        XCTAssertEqual(ZMKKeycodeMap.convert("RIGHT_SHIFT"), "⇧")
    }
    
    func testLeftControlMapsToSymbol() {
        XCTAssertEqual(ZMKKeycodeMap.convert("LCTRL"), "⌃")
        XCTAssertEqual(ZMKKeycodeMap.convert("LCTL"), "⌃")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT_CONTROL"), "⌃")
    }
    
    func testLeftAltMapsToSymbol() {
        XCTAssertEqual(ZMKKeycodeMap.convert("LALT"), "⌥")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT_ALT"), "⌥")
    }
    
    func testGuiMapsToCommand() {
        XCTAssertEqual(ZMKKeycodeMap.convert("LGUI"), "⌘")
        XCTAssertEqual(ZMKKeycodeMap.convert("LCMD"), "⌘")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT_GUI"), "⌘")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT_COMMAND"), "⌘")
    }
    
    // MARK: - Navigation Keys
    
    func testArrowKeys() {
        XCTAssertEqual(ZMKKeycodeMap.convert("UP"), "↑")
        XCTAssertEqual(ZMKKeycodeMap.convert("DOWN"), "↓")
        XCTAssertEqual(ZMKKeycodeMap.convert("LEFT"), "←")
        XCTAssertEqual(ZMKKeycodeMap.convert("RIGHT"), "→")
    }
    
    func testHomeEnd() {
        XCTAssertEqual(ZMKKeycodeMap.convert("HOME"), "⇱")
        XCTAssertEqual(ZMKKeycodeMap.convert("END"), "⇲")
    }
    
    func testPageUpDown() {
        XCTAssertEqual(ZMKKeycodeMap.convert("PG_UP"), "⇞")
        XCTAssertEqual(ZMKKeycodeMap.convert("PG_DN"), "⇟")
    }
    
    // MARK: - Editing Keys
    
    func testBackspace() {
        XCTAssertEqual(ZMKKeycodeMap.convert("BSPC"), "⌫")
        XCTAssertEqual(ZMKKeycodeMap.convert("BACKSPACE"), "⌫")
    }
    
    func testDelete() {
        XCTAssertEqual(ZMKKeycodeMap.convert("DEL"), "⌦")
        XCTAssertEqual(ZMKKeycodeMap.convert("DELETE"), "⌦")
    }
    
    func testEnter() {
        XCTAssertEqual(ZMKKeycodeMap.convert("RET"), "⏎")
        XCTAssertEqual(ZMKKeycodeMap.convert("ENTER"), "⏎")
        XCTAssertEqual(ZMKKeycodeMap.convert("RETURN"), "⏎")
    }
    
    func testEscape() {
        XCTAssertEqual(ZMKKeycodeMap.convert("ESC"), "⎋")
        XCTAssertEqual(ZMKKeycodeMap.convert("ESCAPE"), "⎋")
    }
    
    func testTab() {
        XCTAssertEqual(ZMKKeycodeMap.convert("TAB"), "⇥")
    }
    
    func testSpace() {
        XCTAssertEqual(ZMKKeycodeMap.convert("SPACE"), "␣")
        XCTAssertEqual(ZMKKeycodeMap.convert("SPC"), "␣")
    }
    
    // MARK: - Special Symbols
    
    func testPunctuation() {
        XCTAssertEqual(ZMKKeycodeMap.convert("SEMI"), ";")
        XCTAssertEqual(ZMKKeycodeMap.convert("COMMA"), ",")
        XCTAssertEqual(ZMKKeycodeMap.convert("DOT"), ".")
        XCTAssertEqual(ZMKKeycodeMap.convert("FSLH"), "/")
        XCTAssertEqual(ZMKKeycodeMap.convert("BSLH"), "\\")
    }
    
    func testQuotes() {
        XCTAssertEqual(ZMKKeycodeMap.convert("SQT"), "'")
        XCTAssertEqual(ZMKKeycodeMap.convert("APOS"), "'")
        XCTAssertEqual(ZMKKeycodeMap.convert("DQT"), "\"")
    }
    
    func testBrackets() {
        XCTAssertEqual(ZMKKeycodeMap.convert("LBKT"), "[")
        XCTAssertEqual(ZMKKeycodeMap.convert("RBKT"), "]")
        XCTAssertEqual(ZMKKeycodeMap.convert("LBRC"), "{")
        XCTAssertEqual(ZMKKeycodeMap.convert("RBRC"), "}")
        XCTAssertEqual(ZMKKeycodeMap.convert("LPAR"), "(")
        XCTAssertEqual(ZMKKeycodeMap.convert("RPAR"), ")")
    }
    
    // MARK: - Media Keys
    
    func testMediaPlayPause() {
        XCTAssertEqual(ZMKKeycodeMap.convert("C_PP"), "⏯")
        XCTAssertEqual(ZMKKeycodeMap.convert("C_PLAY_PAUSE"), "⏯")
    }
    
    func testVolumeControls() {
        XCTAssertEqual(ZMKKeycodeMap.convert("C_VOL_UP"), "🔊")
        XCTAssertEqual(ZMKKeycodeMap.convert("C_VOL_DN"), "🔉")
        XCTAssertEqual(ZMKKeycodeMap.convert("C_MUTE"), "🔇")
    }
    
    func testBrightnessControls() {
        XCTAssertEqual(ZMKKeycodeMap.convert("C_BRI_UP"), "🔆")
        XCTAssertEqual(ZMKKeycodeMap.convert("C_BRI_DN"), "🔅")
    }
    
    // MARK: - Numbers
    
    func testNumbers() {
        XCTAssertEqual(ZMKKeycodeMap.convert("N0"), "0")
        XCTAssertEqual(ZMKKeycodeMap.convert("N1"), "1")
        XCTAssertEqual(ZMKKeycodeMap.convert("N9"), "9")
    }
    
    // MARK: - Function Keys
    
    func testFunctionKeys() {
        XCTAssertEqual(ZMKKeycodeMap.convert("F1"), "F1")
        XCTAssertEqual(ZMKKeycodeMap.convert("F12"), "F12")
    }
    
    // MARK: - ZMK-specific
    
    func testBluetooth() {
        XCTAssertEqual(ZMKKeycodeMap.convert("BT_CLR"), "BT⌀")
        XCTAssertEqual(ZMKKeycodeMap.convert("BT_NXT"), "BT→")
        XCTAssertEqual(ZMKKeycodeMap.convert("BT_PRV"), "BT←")
    }
    
    func testOutput() {
        XCTAssertEqual(ZMKKeycodeMap.convert("OUT_USB"), "USB")
        XCTAssertEqual(ZMKKeycodeMap.convert("OUT_BLE"), "BLE")
    }
    
    // MARK: - Case Insensitivity
    
    func testCaseInsensitive() {
        XCTAssertEqual(ZMKKeycodeMap.convert("bspc"), "⌫")
        XCTAssertEqual(ZMKKeycodeMap.convert("Bspc"), "⌫")
        XCTAssertEqual(ZMKKeycodeMap.convert("BSPC"), "⌫")
    }
    
    // MARK: - Single Letters
    
    func testSingleLetters() {
        XCTAssertEqual(ZMKKeycodeMap.convert("A"), "A")
        XCTAssertEqual(ZMKKeycodeMap.convert("a"), "A")
        XCTAssertEqual(ZMKKeycodeMap.convert("Z"), "Z")
    }
    
    // MARK: - Unknown Keys
    
    func testUnknownKeyReturnsShortened() {
        let result = ZMKKeycodeMap.convert("SOME_VERY_LONG_UNKNOWN_KEY")
        XCTAssertEqual(result.count, 4, "Unknown keys should be truncated to 4 chars")
    }
    
    // MARK: - Transparent
    
    func testTransparent() {
        XCTAssertEqual(ZMKKeycodeMap.convert("TRANS"), "▽")
    }
}
