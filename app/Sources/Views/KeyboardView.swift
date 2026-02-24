import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(currentLayerName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if appState.testModeEnabled {
                    Text("TEST MODE")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 4)
            
            if let layout = appState.physicalLayout {
                ZStack {
                    ForEach(currentBindings.indices, id: \.self) { index in
                        if let scaled = layout.scaledPosition(for: index) {
                            KeyView(
                                binding: currentBindings[index],
                                position: ScaledKeyPosition(
                                    index: index,
                                    x: scaled.x,
                                    y: scaled.y,
                                    width: scaled.width,
                                    height: scaled.height,
                                    rotation: scaled.rotation
                                ),
                                isPressed: appState.pressedKeys.contains(index)
                            )
                            .position(x: scaled.x + scaled.width / 2, y: scaled.y + scaled.height / 2)
                            .rotationEffect(.degrees(scaled.rotation))
                        }
                    }
                }
                .frame(width: layout.layoutSize.width, height: layout.layoutSize.height)
            } else {
                Text("No layout loaded")
                    .foregroundColor(.secondary)
                    .frame(width: 300, height: 150)
            }
        }
        .padding()
    }
    
    private var currentLayerName: String {
        guard let keymap = appState.keymap,
              appState.currentLayer < keymap.layers.count else {
            return "Layer \(appState.currentLayer)"
        }
        return keymap.layers[appState.currentLayer].name
    }
    
    private var currentBindings: [Binding] {
        guard let keymap = appState.keymap,
              appState.currentLayer < keymap.layers.count else {
            return []
        }
        return keymap.layers[appState.currentLayer].bindings
    }
}


