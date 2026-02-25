import XCTest
@testable import ZMKHud

final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    var tempDir: URL!
    
    override func setUp() {
        super.setUp()
        // Use temporary config directory to avoid affecting user's real config
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempConfigManager = ConfigManager(configDir: tempDir)
        appState = AppState(configManager: tempConfigManager)
    }
    
    override func tearDown() {
        appState = nil
        // Cleanup temp directory
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(appState.currentLayer, 0)
        XCTAssertTrue(appState.pressedKeys.isEmpty)
        XCTAssertTrue(appState.modifiers.isEmpty)
        XCTAssertFalse(appState.hudVisible)
        XCTAssertNil(appState.keymap)
    }
    
    func testActiveLayerReturnsZeroWhenNoLayersActive() {
        XCTAssertEqual(appState.activeLayer, 0)
    }
    
    func testShouldShowHUDIsFalseOnBaseLayer() {
        XCTAssertFalse(appState.shouldShowHUD)
    }
    
    func testHandleLayerChangeUpdatesState() {
        appState.handleLayerChange(layer: 1, active: true, state: 0b0010)
        
        XCTAssertEqual(appState.currentLayer, 1)
    }
    
    func testHandleLayerChangeWithMultipleLayers() {
        appState.handleLayerChange(layer: 2, active: true, state: 0b0110)
        
        XCTAssertEqual(appState.activeLayer, 2)
    }
    
    func testHandleLayerChangeReturnsToBase() {
        appState.handleLayerChange(layer: 1, active: true, state: 0b0010)
        appState.handleLayerChange(layer: 1, active: false, state: 0b0000)
        
        XCTAssertEqual(appState.activeLayer, 0)
    }
    
    func testModifierFlagsCtrl() {
        let flags = AppState.ModifierFlags.ctrl
        
        XCTAssertEqual(flags.rawValue, 1)
    }
    
    func testModifierFlagsShift() {
        let flags = AppState.ModifierFlags.shift
        
        XCTAssertEqual(flags.rawValue, 2)
    }
    
    func testModifierFlagsAlt() {
        let flags = AppState.ModifierFlags.alt
        
        XCTAssertEqual(flags.rawValue, 4)
    }
    
    func testModifierFlagsGui() {
        let flags = AppState.ModifierFlags.gui
        
        XCTAssertEqual(flags.rawValue, 8)
    }
    
    func testModifierFlagsCombined() {
        let flags: AppState.ModifierFlags = [.ctrl, .shift]
        
        XCTAssertTrue(flags.contains(.ctrl))
        XCTAssertTrue(flags.contains(.shift))
        XCTAssertFalse(flags.contains(.alt))
        XCTAssertFalse(flags.contains(.gui))
    }
}
