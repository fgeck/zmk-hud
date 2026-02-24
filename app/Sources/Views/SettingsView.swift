import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var keymapURL: String = ""
    @State private var layoutURL: String = ""
    @State private var selectedTab: SettingsTab = .files
    
    enum SettingsTab: String, CaseIterable {
        case files = "Files"
        case appearance = "Appearance"
        case about = "About"
        
        var icon: String {
            switch self {
            case .files: return "doc.text"
            case .appearance: return "paintbrush"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FilesSettingsView(keymapURL: $keymapURL, layoutURL: $layoutURL)
                .tabItem {
                    Label("Files", systemImage: "doc.text")
                }
                .tag(SettingsTab.files)
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(SettingsTab.appearance)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 420)
    }
}

// MARK: - Files Settings

struct FilesSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var keymapURL: String
    @Binding var layoutURL: String
    
    private var selectedLayoutBinding: Binding<String> {
        Binding(
            get: { appState.selectedLayoutId ?? "" },
            set: { appState.selectLayout($0) }
        )
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Current keymap status
                    HStack {
                        Image(systemName: appState.keymapPath != nil ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(appState.keymapPath != nil ? .green : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let path = appState.keymapPath {
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .fontWeight(.medium)
                                Text(path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            } else {
                                Text("No keymap loaded")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Choose...") {
                            chooseKeymapFile()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // URL input
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        TextField("Load from URL...", text: $keymapURL)
                            .textFieldStyle(.roundedBorder)
                        Button("Load") {
                            if keymapURL.hasPrefix("http") {
                                appState.loadKeymapFromURL(keymapURL)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!keymapURL.hasPrefix("http"))
                    }
                }
            } header: {
                Label("Keymap File (.keymap)", systemImage: "keyboard")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Current layout status
                    HStack {
                        Image(systemName: appState.layoutPath != nil ? "checkmark.circle.fill" : "questionmark.circle")
                            .foregroundColor(appState.layoutPath != nil ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let path = appState.layoutPath {
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .fontWeight(.medium)
                                if let layout = appState.physicalLayout {
                                    Text("\(appState.selectedLayoutId ?? "Layout") • \(layout.count) keys")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Auto-inferred from keymap")
                                    .foregroundColor(.orange)
                                if let layout = appState.physicalLayout {
                                    Text("Using auto layout • \(layout.count) keys")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if appState.layoutPath != nil {
                            Button("Clear") {
                                appState.clearLayout()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button("Choose...") {
                            chooseLayoutFile()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Layout variant picker
                    if appState.availableLayouts.count > 1 {
                        Divider()
                        Picker("Layout Variant", selection: selectedLayoutBinding) {
                            ForEach(appState.availableLayouts) { option in
                                Text("\(option.name) (\(option.keyCount) keys)")
                                    .tag(option.id)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // URL input
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        TextField("Load from URL...", text: $layoutURL)
                            .textFieldStyle(.roundedBorder)
                        
                        if appState.isLoadingLayout {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 50)
                        } else {
                            Button("Load") {
                                if layoutURL.hasPrefix("http") {
                                    appState.loadLayoutFromURL(layoutURL)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(!layoutURL.hasPrefix("http"))
                        }
                    }
                    
                    if let error = appState.layoutLoadError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            } header: {
                Label("Physical Layout (.json)", systemImage: "square.grid.3x3")
            }
            
            Section {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text("~/.config/zmk-hud/config.yaml")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Open in Finder") {
                        let path = NSString(string: "~/.config/zmk-hud").expandingTildeInPath
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Label("Config Location", systemImage: "gearshape")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func chooseKeymapFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, UTType(filenameExtension: "keymap") ?? .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Keymap File"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.loadKeymapFromFile(url.path)
        }
    }
    
    private func chooseLayoutFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Physical Layout JSON"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.loadLayoutFromFile(url.path)
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    private var opacityBinding: Binding<Double> {
        Binding(
            get: { appState.hudOpacity },
            set: { 
                appState.hudOpacity = $0
                appState.saveConfig()
            }
        )
    }
    
    private var scaleBinding: Binding<Double> {
        Binding(
            get: { appState.hudScale },
            set: { 
                appState.hudScale = $0
                appState.saveConfig()
            }
        )
    }
    
    private var comboDisplayBinding: Binding<AppState.ComboDisplayMode> {
        Binding(
            get: { appState.comboDisplayMode },
            set: {
                appState.comboDisplayMode = $0
                appState.saveConfig()
            }
        )
    }
    
    private var comboDisplayDescription: String {
        switch appState.comboDisplayMode {
        case .both:
            return "Show combo boxes on keyboard and combo lists in side panels"
        case .dendrons:
            return "Show combo boxes directly on keyboard with connecting lines"
        case .panels:
            return "Show combos as lists in left/right side panels"
        case .none:
            return "Hide all combo displays"
        }
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(.secondary)
                    Text("Opacity")
                    Spacer()
                    Text("\(Int(appState.hudOpacity * 100))%")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: opacityBinding, in: 0.5...1.0)
                
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.secondary)
                    Text("Scale")
                    Spacer()
                    Text("\(Int(appState.hudScale * 100))%")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: scaleBinding, in: 0.5...1.5)
            } header: {
                Label("HUD Window", systemImage: "rectangle.on.rectangle")
            }
            
            Section {
                Picker(selection: comboDisplayBinding, label: HStack {
                    Image(systemName: appState.comboDisplayMode.icon)
                        .foregroundColor(.secondary)
                    Text("Combo Display")
                }) {
                    ForEach(AppState.ComboDisplayMode.allCases, id: \.self) { mode in
                        Label(mode.label, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                
                Text(comboDisplayDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Combos", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            }
            
            Section {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                    Text("Test Mode")
                    Spacer()
                    Text(appState.testModeEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(appState.testModeEnabled ? .orange : .secondary)
                }
                
                Text("Test mode simulates layer switching using Fn+1/2/3/4/5 keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Testing", systemImage: "testtube.2")
            }
            
            Section {
                HStack {
                    Text("Press")
                    Text("⇧⌘H")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Text("to toggle HUD visibility")
                    Spacer()
                }
                
                HStack {
                    Text("Press")
                    Text("⇧⌘T")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Text("to toggle Test Mode")
                    Spacer()
                }
            } header: {
                Label("Keyboard Shortcuts", systemImage: "command")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App icon
            Image(systemName: "keyboard.badge.eye")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // App name and version
            VStack(spacing: 4) {
                Text("ZMK HUD")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text("A floating heads-up display for ZMK keyboards.\nShows active layers, key states, and combos in real-time.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Links
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/fgeck/zmk-hud")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub Repository")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/caksoylar/keymap-drawer")!) {
                    HStack {
                        Image(systemName: "paintbrush")
                        Text("keymap-drawer (rendering inspiration)")
                    }
                }
                
                Link(destination: URL(string: "https://zmk.dev")!) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("ZMK Firmware")
                    }
                }
            }
            .font(.callout)
            
            Spacer()
            
            // Credits
            Text("Made with ♥ for the mechanical keyboard community")
                .font(.caption)
                .foregroundColor(Color.secondary.opacity(0.6))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
