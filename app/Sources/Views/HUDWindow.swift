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
    
    var body: some View {
        HStack(spacing: 16) {
            LeftComboPanel()
            KeyboardView()
            RightComboPanel()
        }
        .padding(20)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
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
