import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hudPosition") private var hudPosition: HUDPosition = .topRight
    @AppStorage("comboPanelSide") private var comboPanelSide: ComboPanelSide = .right
    @AppStorage("hudOpacity") private var hudOpacity: Double = 0.95
    @AppStorage("hudScale") private var hudScale: Double = 1.0
    @State private var keymapURL: String = ""
    @State private var layoutURL: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                        Text(appState.layoutPath ?? "Auto-inferred from keymap")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
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
                    
                    HStack {
                        TextField("Or enter URL...", text: $layoutURL)
                            .textFieldStyle(.roundedBorder)
                        Button("Load") {
                            if layoutURL.hasPrefix("http") {
                                appState.loadLayoutFromURL(layoutURL)
                            }
                        }
                        .disabled(!layoutURL.hasPrefix("http"))
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Position") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("HUD Position", selection: $hudPosition) {
                        ForEach(HUDPosition.allCases, id: \.self) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    
                    Picker("Combo Panel", selection: $comboPanelSide) {
                        Text("Left").tag(ComboPanelSide.left)
                        Text("Right").tag(ComboPanelSide.right)
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Opacity")
                        Slider(value: $hudOpacity, in: 0.5...1.0)
                    }
                    
                    HStack {
                        Text("Scale")
                        Slider(value: $hudScale, in: 0.5...1.5)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 480)
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

enum HUDPosition: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    
    var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

enum ComboPanelSide: String {
    case left, right
}
