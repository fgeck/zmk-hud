import XCTest
@testable import ZMKHud

final class ConfigTests: XCTestCase {
    var tempDir: URL!
    var configManager: ConfigManager!
    
    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        configManager = ConfigManager(configDir: tempDir)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }
    
    func testDefaultConfigValues() {
        let config = configManager.load()
        
        XCTAssertNil(config.keymapPath)
        XCTAssertNil(config.layoutPath)
        XCTAssertNil(config.selectedLayoutId)
        XCTAssertEqual(config.hudPosition, "topRight")
        XCTAssertEqual(config.hudOpacity, 0.95)
        XCTAssertEqual(config.hudScale, 1.0)
    }
    
    func testSaveAndLoadConfig() throws {
        let config = HUDConfig(
            keymapPath: "/path/to/keymap.keymap",
            layoutPath: "https://example.com/layout.json",
            selectedLayoutId: "medium_layout",
            hudPosition: "topLeft",
            hudOpacity: 0.8,
            hudScale: 1.2
        )
        
        try configManager.save(config)
        let loaded = configManager.load()
        
        XCTAssertEqual(loaded.keymapPath, "/path/to/keymap.keymap")
        XCTAssertEqual(loaded.layoutPath, "https://example.com/layout.json")
        XCTAssertEqual(loaded.selectedLayoutId, "medium_layout")
        XCTAssertEqual(loaded.hudPosition, "topLeft")
        XCTAssertEqual(loaded.hudOpacity, 0.8, accuracy: 0.01)
        XCTAssertEqual(loaded.hudScale, 1.2, accuracy: 0.01)
    }
    
    func testConfigFileIsYAML() throws {
        let config = HUDConfig(
            keymapPath: "/test/path",
            layoutPath: "https://example.com/layout.json",
            selectedLayoutId: "large_layout"
        )
        
        try configManager.save(config)
        
        let configFile = tempDir.appendingPathComponent("config.yaml")
        let content = try String(contentsOf: configFile, encoding: .utf8)
        
        XCTAssertTrue(content.contains("# ZMK HUD Configuration"))
        XCTAssertTrue(content.contains("keymap_path: /test/path"))
        XCTAssertTrue(content.contains("layout_path: https://example.com/layout.json"))
        XCTAssertTrue(content.contains("selected_layout_id: large_layout"))
    }
    
    func testConfigCreatesDirectory() throws {
        let subDir = tempDir.appendingPathComponent("nested/config/dir")
        let nestedManager = ConfigManager(configDir: subDir)
        
        let config = HUDConfig(keymapPath: "/test")
        try nestedManager.save(config)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: subDir.path))
    }
    
    func testConfigHandlesEmptyValues() throws {
        let config = HUDConfig(
            keymapPath: nil,
            layoutPath: nil,
            selectedLayoutId: nil
        )
        
        try configManager.save(config)
        let loaded = configManager.load()
        
        XCTAssertNil(loaded.keymapPath)
        XCTAssertNil(loaded.layoutPath)
        XCTAssertNil(loaded.selectedLayoutId)
    }
    
    func testConfigIgnoresComments() throws {
        let yamlContent = """
        # This is a comment
        keymap_path: /test/path
        # Another comment
        layout_path: https://example.com/layout.json
        """
        
        let configFile = tempDir.appendingPathComponent("config.yaml")
        try yamlContent.write(to: configFile, atomically: true, encoding: .utf8)
        
        let loaded = configManager.load()
        
        XCTAssertEqual(loaded.keymapPath, "/test/path")
        XCTAssertEqual(loaded.layoutPath, "https://example.com/layout.json")
    }
    
    func testConfigHandlesMalformedLines() throws {
        let yamlContent = """
        keymap_path: /valid/path
        malformed line without colon
        layout_path: https://example.com/layout.json
        : empty key
        """
        
        let configFile = tempDir.appendingPathComponent("config.yaml")
        try yamlContent.write(to: configFile, atomically: true, encoding: .utf8)
        
        let loaded = configManager.load()
        
        XCTAssertEqual(loaded.keymapPath, "/valid/path")
        XCTAssertEqual(loaded.layoutPath, "https://example.com/layout.json")
    }
    
    func testConfigPersistsSelectedLayoutId() throws {
        let config = HUDConfig(
            keymapPath: "/path/keymap.keymap",
            layoutPath: "https://github.com/org/repo/blob/main/layout.json",
            selectedLayoutId: "medium_layout"
        )
        
        try configManager.save(config)
        let loaded = configManager.load()
        
        XCTAssertEqual(loaded.selectedLayoutId, "medium_layout")
    }
}
