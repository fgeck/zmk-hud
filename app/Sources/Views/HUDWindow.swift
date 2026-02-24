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
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection status with pulse animation
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isAnimating && isConnected ? 1.5 : 1.0)
                        .opacity(isAnimating && isConnected ? 0 : 1)
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Layer indicator with animation
            HStack(spacing: 8) {
                layerIcon
                
                Text(layerName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .id(layerName) // Force view update on layer change
                
                Text("(\(layerIndex + 1)/\(totalLayers))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: layerIndex)
            
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
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.2), value: testMode)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private var statusColor: Color {
        if testMode { return .orange }
        return isConnected ? .green : .red
    }
    
    private var statusText: String {
        if testMode { return "Test Mode" }
        return isConnected ? "Connected" : "Disconnected"
    }
    
    @ViewBuilder
    private var layerIcon: some View {
        if #available(macOS 14.0, *) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce, value: layerIndex)
        } else {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
        }
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
