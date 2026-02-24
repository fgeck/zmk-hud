import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var keymapURL: String = ""
    @State private var layoutURL: String = ""
    
    private var selectedLayoutBinding: SwiftUI.Binding<String> {
        SwiftUI.Binding(
            get: { appState.selectedLayoutId ?? "" },
            set: { appState.selectLayout($0) }
        )
    }
    
    private var opacityBinding: SwiftUI.Binding<Double> {
        SwiftUI.Binding(
            get: { appState.hudOpacity },
            set: { 
                appState.hudOpacity = $0
                appState.saveConfig()
            }
        )
    }
    
    private var scaleBinding: SwiftUI.Binding<Double> {
        SwiftUI.Binding(
            get: { appState.hudScale },
            set: { 
                appState.hudScale = $0
                appState.saveConfig()
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Keymap (.keymap file)") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(appState.keymapPath ?? "No keymap loaded")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose...") {
                            chooseKeymapFile()
                        }
                    }
                    
                    HStack {
                        TextField("Or enter URL...", text: $keymapURL)
                            .textFieldStyle(.roundedBorder)
                        Button("Load") {
                            if keymapURL.hasPrefix("http") {
                                appState.loadKeymapFromURL(keymapURL)
                            }
                        }
                        .disabled(!keymapURL.hasPrefix("http"))
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Physical Layout (.json file)") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let layoutPath = appState.layoutPath {
                                Text(layoutPath)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                if let layout = appState.physicalLayout {
                                    Text("✓ \(layout.name) (\(layout.positions.count) keys)")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            } else {
                                Text("Auto-inferred from keymap")
                                    .foregroundColor(.secondary)
                                if let layout = appState.physicalLayout {
                                    Text("Using: \(layout.name)")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                        Spacer()
                        if appState.layoutPath != nil {
                            Button("Clear") {
                                appState.clearLayout()
                            }
                        }
                        Button("Choose...") {
                            chooseLayoutFile()
                        }
                    }
                    
                    if appState.availableLayouts.count > 1 {
                        Picker("Layout Size", selection: selectedLayoutBinding) {
                            ForEach(appState.availableLayouts) { option in
                                Text("\(option.name) (\(option.keyCount) keys)")
                                    .tag(option.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        TextField("Or enter URL...", text: $layoutURL)
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
                            .disabled(!layoutURL.hasPrefix("http"))
                        }
                    }
                    
                    if let error = appState.layoutLoadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Opacity")
                        Slider(value: opacityBinding, in: 0.5...1.0)
                    }
                    
                    HStack {
                        Text("Scale")
                        Slider(value: scaleBinding, in: 0.5...1.5)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Text("Config: ~/.config/zmk-hud/config.yaml")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 500)
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
