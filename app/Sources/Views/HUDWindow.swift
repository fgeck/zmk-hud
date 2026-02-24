import SwiftUI
import AppKit

class HUDWindow {
    private var panel: NSPanel?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        setupPanel()
    }
    
    private func setupPanel() {
        let contentView = HUDContentView()
            .environmentObject(appState)
        
        let hostingView = NSHostingView(rootView: contentView)
        
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        
        panel?.level = .floating
        panel?.isOpaque = false
        panel?.backgroundColor = .clear
        panel?.hasShadow = true
        panel?.contentView = hostingView
        panel?.isMovableByWindowBackground = true
        
        positionWindow()
    }
    
    private func positionWindow() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = panel.frame
        
        let x = screenFrame.maxX - windowFrame.width - 20
        let y = screenFrame.maxY - windowFrame.height - 20
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func show() {
        panel?.orderFront(nil)
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
}

struct HUDContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var currentLayerName: String {
        guard let keymap = appState.keymap,
              appState.currentLayer < keymap.layers.count else {
            return "Layer \(appState.currentLayer)"
        }
        return keymap.layers[appState.currentLayer].name
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Layer header
            LayerHeader(
                layerName: currentLayerName,
                layerIndex: appState.currentLayer,
                totalLayers: appState.keymap?.layers.count ?? 1,
                isConnected: appState.isConnected,
                testMode: appState.testModeEnabled
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            // Main content
            HStack(spacing: 16) {
                LeftComboPanel()
                
                if let layout = appState.physicalLayout {
                    ZStack {
                        KeyboardCanvas(
                            layout: layout,
                            colorScheme: systemColorScheme == .dark ? .dark : .light,
                            legends: appState.legends,
                            pressedKeys: appState.pressedKeys,
                            currentLayer: appState.currentLayer
                        )
                        
                        // Combo overlay
                        if let keymap = appState.keymap, !keymap.combos.isEmpty {
                            ComboOverlayView(
                                layout: layout,
                                combos: keymap.combos,
                                currentLayer: appState.currentLayer,
                                customLabels: appState.customLabels,
                                colorScheme: systemColorScheme == .dark ? .dark : .light
                            )
                        }
                    }
                    .frame(width: layout.width + 40, height: layout.height + 60)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard.badge.ellipsis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No layout loaded")
                            .foregroundColor(.secondary)
                        Text("Open Settings to configure")
                            .font(.caption)
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                    .frame(width: 400, height: 200)
                }
                
                RightComboPanel()
            }
            .padding(16)
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .onChange(of: appState.currentLayer) { _ in
            appState.updateLegends()
        }
    }
}

// MARK: - Layer Header

struct LayerHeader: View {
    let layerName: String
    let layerIndex: Int
    let totalLayers: Int
    let isConnected: Bool
    let testMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Layer indicator
            HStack(spacing: 8) {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Text(layerName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("(\(layerIndex + 1)/\(totalLayers))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Test mode indicator
            if testMode {
                HStack(spacing: 4) {
                    Image(systemName: "testtube.2")
                        .font(.caption)
                    Text("Test")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var statusColor: Color {
        if testMode { return .orange }
        return isConnected ? .green : .red
    }
    
    private var statusText: String {
        if testMode { return "Test Mode" }
        return isConnected ? "Connected" : "Disconnected"
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
