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
            
            ZStack {
                ForEach(currentBindings.indices, id: \.self) { index in
                    if let position = KeyboardLayout.position(for: bindingIndex(for: index)) {
                        KeyView(
                            binding: currentBindings[index],
                            position: position,
                            isPressed: appState.pressedKeys.contains(position.index)
                        )
                        .position(x: position.x + position.width / 2, y: position.y + position.height / 2)
                    }
                }
            }
            .frame(width: KeyboardLayout.layoutSize.width, height: KeyboardLayout.layoutSize.height)
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
    
    private func bindingIndex(for arrayIndex: Int) -> Int {
        let flakeLOffset = 12
        return flakeLOffset + arrayIndex
    }
}
