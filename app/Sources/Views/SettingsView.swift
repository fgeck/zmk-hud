import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hudPosition") private var hudPosition: HUDPosition = .topRight
    @AppStorage("comboPanelSide") private var comboPanelSide: ComboPanelSide = .right
    @AppStorage("hudOpacity") private var hudOpacity: Double = 0.95
    @AppStorage("hudScale") private var hudScale: Double = 1.0
    
    var body: some View {
        Form {
            Section("Keymap") {
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
                
                TextField("GitHub URL", text: Binding(
                    get: { appState.keymapPath ?? "" },
                    set: { if $0.hasPrefix("http") { appState.loadKeymapFromURL($0) }}
                ))
                .textFieldStyle(.roundedBorder)
            }
            
            Section("Position") {
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
            
            Section("Appearance") {
                Slider(value: $hudOpacity, in: 0.5...1.0) {
                    Text("Opacity")
                }
                
                Slider(value: $hudScale, in: 0.5...1.5) {
                    Text("Scale")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
    }
    
    private func chooseKeymapFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Keymap File"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState.loadKeymapFromFile(url.path)
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
