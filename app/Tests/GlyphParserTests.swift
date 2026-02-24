import XCTest
@testable import ZMKHud

final class GlyphParserTests: XCTestCase {
    
    // MARK: - Basic Parsing Tests
    
    func testPlainTextPassesThrough() {
        let result = GlyphParser.parse("Hello")
        
        XCTAssertEqual(result.text, "Hello")
        XCTAssertFalse(result.isSFSymbol)
    }
    
    func testEmptyStringPassesThrough() {
        let result = GlyphParser.parse("")
        
        XCTAssertEqual(result.text, "")
        XCTAssertFalse(result.isSFSymbol)
    }
    
    func testIncompleteGlyphSyntaxPassesThrough() {
        let result1 = GlyphParser.parse("$$mdi:play")  // Missing closing $$
        let result2 = GlyphParser.parse("mdi:play$$")  // Missing opening $$
        
        XCTAssertEqual(result1.text, "$$mdi:play")
        XCTAssertFalse(result1.isSFSymbol)
        XCTAssertEqual(result2.text, "mdi:play$$")
        XCTAssertFalse(result2.isSFSymbol)
    }
    
    // MARK: - MDI Icon Tests
    
    func testMdiPlayIcon() {
        let result = GlyphParser.parse("$$mdi:play$$")
        
        XCTAssertEqual(result.text, "play.fill")
        XCTAssertTrue(result.isSFSymbol)
    }
    
    func testMdiArrowIcons() {
        let left = GlyphParser.parse("$$mdi:arrow-left$$")
        let right = GlyphParser.parse("$$mdi:arrow-right$$")
        let up = GlyphParser.parse("$$mdi:arrow-up$$")
        let down = GlyphParser.parse("$$mdi:arrow-down$$")
        
        XCTAssertEqual(left.text, "arrow.left")
        XCTAssertEqual(right.text, "arrow.right")
        XCTAssertEqual(up.text, "arrow.up")
        XCTAssertEqual(down.text, "arrow.down")
        XCTAssertTrue(left.isSFSymbol)
    }
    
    func testMdiVolumeIcons() {
        let high = GlyphParser.parse("$$mdi:volume-high$$")
        let mute = GlyphParser.parse("$$mdi:volume-mute$$")
        
        XCTAssertEqual(high.text, "speaker.wave.3.fill")
        XCTAssertEqual(mute.text, "speaker.slash.fill")
        XCTAssertTrue(high.isSFSymbol)
    }
    
    func testMdiBluetoothIcon() {
        let result = GlyphParser.parse("$$mdi:bluetooth$$")
        
        XCTAssertEqual(result.text, "antenna.radiowaves.left.and.right")
        XCTAssertTrue(result.isSFSymbol)
    }
    
    func testMdiKeyboardIcons() {
        let backspace = GlyphParser.parse("$$mdi:backspace$$")
        let keyboard = GlyphParser.parse("$$mdi:keyboard$$")
        
        XCTAssertEqual(backspace.text, "delete.left")
        XCTAssertEqual(keyboard.text, "keyboard")
        XCTAssertTrue(backspace.isSFSymbol)
    }
    
    func testMdiAppleModifierIcons() {
        let command = GlyphParser.parse("$$mdi:apple-keyboard-command$$")
        let option = GlyphParser.parse("$$mdi:apple-keyboard-option$$")
        let control = GlyphParser.parse("$$mdi:apple-keyboard-control$$")
        let shift = GlyphParser.parse("$$mdi:apple-keyboard-shift$$")
        
        XCTAssertEqual(command.text, "command")
        XCTAssertEqual(option.text, "option")
        XCTAssertEqual(control.text, "control")
        XCTAssertEqual(shift.text, "shift")
    }
    
    func testMdiUnknownIconFallsBack() {
        let result = GlyphParser.parse("$$mdi:some-unknown-icon$$")
        
        // Should convert kebab-case to title case
        XCTAssertEqual(result.text, "Some Unknown Icon")
        XCTAssertFalse(result.isSFSymbol)
    }
    
    // MARK: - Tabler Icon Tests
    
    func testTablerIcons() {
        let home = GlyphParser.parse("$$tabler:home$$")
        let settings = GlyphParser.parse("$$tabler:settings$$")
        
        XCTAssertEqual(home.text, "house")
        XCTAssertEqual(settings.text, "gearshape")
        XCTAssertTrue(home.isSFSymbol)
    }
    
    // MARK: - Unknown Prefix Tests
    
    func testUnknownPrefixReturnsInner() {
        let result = GlyphParser.parse("$$unknown:icon$$")
        
        XCTAssertEqual(result.text, "unknown:icon")
        XCTAssertFalse(result.isSFSymbol)
    }
    
    // MARK: - containsGlyph Tests
    
    func testContainsGlyphDetectsGlyphSyntax() {
        XCTAssertTrue(GlyphParser.containsGlyph("$$mdi:play$$"))
        XCTAssertFalse(GlyphParser.containsGlyph("plain text"))
        XCTAssertFalse(GlyphParser.containsGlyph("$$mdi:play"))  // Incomplete
        XCTAssertFalse(GlyphParser.containsGlyph("mdi:play$$"))  // Incomplete
    }
    
    // MARK: - Integration with Binding
    
    func testBindingParsedDisplayLabelWithGlyph() {
        let binding = Binding(type: .custom("myIcon"), raw: "&myIcon")
        let customLabels = ["myIcon": "$$mdi:play$$"]
        
        let parsed = binding.parsedDisplayLabel(with: customLabels)
        
        XCTAssertEqual(parsed.text, "play.fill")
        XCTAssertTrue(parsed.isSFSymbol)
    }
    
    func testBindingParsedDisplayLabelWithoutGlyph() {
        let binding = Binding(type: .keyPress("SPACE"), raw: "&kp SPACE")
        
        let parsed = binding.parsedDisplayLabel()
        
        XCTAssertEqual(parsed.text, "␣")
        XCTAssertFalse(parsed.isSFSymbol)
    }
}
