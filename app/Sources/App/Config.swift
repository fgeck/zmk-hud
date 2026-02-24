import Foundation

struct HUDConfig: Codable {
    var keymapPath: String?
    var layoutPath: String?
    var selectedLayoutId: String?
    var keymapDrawerConfigPath: String?  // Path to keymap_drawer.config.yaml
    var customLabels: [String: String]
    var tapDanceShifted: [String: String]  // Maps td_name -> double-tap label
    var hudPosition: String
    var hudOpacity: Double
    var hudScale: Double
    var comboDisplayMode: String  // "both", "dendrons", "panels", "none"
    
    init(
        keymapPath: String? = nil,
        layoutPath: String? = nil,
        selectedLayoutId: String? = nil,
        keymapDrawerConfigPath: String? = nil,
        customLabels: [String: String] = [:],
        tapDanceShifted: [String: String] = [:],
        hudPosition: String = "topRight",
        hudOpacity: Double = 0.95,
        hudScale: Double = 1.0,
        comboDisplayMode: String = "both"
    ) {
        self.keymapPath = keymapPath
        self.layoutPath = layoutPath
        self.selectedLayoutId = selectedLayoutId
        self.keymapDrawerConfigPath = keymapDrawerConfigPath
        self.customLabels = customLabels
        self.tapDanceShifted = tapDanceShifted
        self.hudPosition = hudPosition
        self.hudOpacity = hudOpacity
        self.hudScale = hudScale
        self.comboDisplayMode = comboDisplayMode
    }
}

class ConfigManager {
    static let shared = ConfigManager()
    
    private let configDir: URL
    private let configFile: URL
    
    init(configDir: URL? = nil) {
        if let dir = configDir {
            self.configDir = dir
            self.configFile = dir.appendingPathComponent("config.yaml")
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            self.configDir = home.appendingPathComponent(".config/zmk-hud")
            self.configFile = self.configDir.appendingPathComponent("config.yaml")
        }
    }
    
    func load() -> HUDConfig {
        guard FileManager.default.fileExists(atPath: configFile.path),
              let data = try? Data(contentsOf: configFile),
              let content = String(data: data, encoding: .utf8) else {
            return HUDConfig()
        }
        
        return parseYAML(content)
    }
    
    func save(_ config: HUDConfig) throws {
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let yaml = generateYAML(config)
        try yaml.write(to: configFile, atomically: true, encoding: .utf8)
    }
    
    private func parseYAML(_ content: String) -> HUDConfig {
        var config = HUDConfig()
        var currentSection: String? = nil
        
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            
            // Check for section headers
            if trimmed == "custom_labels:" {
                currentSection = "custom_labels"
                continue
            } else if trimmed == "tap_dance_shifted:" {
                currentSection = "tap_dance_shifted"
                continue
            }
            
            // Handle section content
            if let section = currentSection {
                if !line.hasPrefix(" ") && !line.hasPrefix("\t") {
                    currentSection = nil
                } else {
                    let parts = trimmed.split(separator: ":", maxSplits: 1)
                    if parts.count == 2 {
                        let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                        var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        if value.hasPrefix("\"") && value.hasSuffix("\"") {
                            value = String(value.dropFirst().dropLast())
                        }
                        if section == "custom_labels" {
                            config.customLabels[key] = value
                        } else if section == "tap_dance_shifted" {
                            config.tapDanceShifted[key] = value
                        }
                    }
                    continue
                }
            }
            
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "keymap_path":
                config.keymapPath = value.isEmpty ? nil : value
            case "layout_path":
                config.layoutPath = value.isEmpty ? nil : value
            case "selected_layout_id":
                config.selectedLayoutId = value.isEmpty ? nil : value
            case "keymap_drawer_config_path":
                config.keymapDrawerConfigPath = value.isEmpty ? nil : value
            case "hud_position":
                config.hudPosition = value
            case "hud_opacity":
                config.hudOpacity = Double(value) ?? 0.95
            case "hud_scale":
                config.hudScale = Double(value) ?? 1.0
            case "combo_display_mode":
                config.comboDisplayMode = value.isEmpty ? "both" : value
            default:
                break
            }
        }
        
        return config
    }
    
    private func generateYAML(_ config: HUDConfig) -> String {
        var lines: [String] = []
        lines.append("# ZMK HUD Configuration")
        lines.append("")
        lines.append("# Paths")
        lines.append("keymap_path: \(config.keymapPath ?? "")")
        lines.append("layout_path: \(config.layoutPath ?? "")")
        lines.append("selected_layout_id: \(config.selectedLayoutId ?? "")")
        lines.append("keymap_drawer_config_path: \(config.keymapDrawerConfigPath ?? "")")
        lines.append("")
        lines.append("# HUD Appearance")
        lines.append("hud_position: \(config.hudPosition)")
        lines.append("hud_opacity: \(config.hudOpacity)")
        lines.append("hud_scale: \(config.hudScale)")
        lines.append("")
        lines.append("# Combo Display: both, dendrons, panels, none")
        lines.append("combo_display_mode: \(config.comboDisplayMode)")
        lines.append("")
        lines.append("# Custom key label mappings (tap label)")
        lines.append("# Map behavior names to display labels")
        lines.append("custom_labels:")
        if config.customLabels.isEmpty {
            lines.append("  # td_u: U")
            lines.append("  # td_fslh: \"/\"")
        } else {
            for (key, value) in config.customLabels.sorted(by: { $0.key < $1.key }) {
                if value.contains(" ") || value.contains(":") {
                    lines.append("  \(key): \"\(value)\"")
                } else {
                    lines.append("  \(key): \(value)")
                }
            }
        }
        lines.append("")
        lines.append("# Tap-dance double-tap labels (shown smaller, in purple)")
        lines.append("# Map tap-dance names to their double-tap output")
        lines.append("tap_dance_shifted:")
        if config.tapDanceShifted.isEmpty {
            lines.append("  # td_u: \"ü\"")
            lines.append("  # td_fslh: \"?\"")
        } else {
            for (key, value) in config.tapDanceShifted.sorted(by: { $0.key < $1.key }) {
                if value.contains(" ") || value.contains(":") {
                    lines.append("  \(key): \"\(value)\"")
                } else {
                    lines.append("  \(key): \(value)")
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}
