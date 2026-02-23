import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 8) {
            Text(currentLayerName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Keyboard visualization coming soon")
                .foregroundColor(.secondary)
                .frame(width: 500, height: 250)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var currentLayerName: String {
        guard let keymap = appState.keymap,
              appState.currentLayer < keymap.layers.count else {
            return "Layer \(appState.currentLayer)"
        }
        return keymap.layers[appState.currentLayer].name
    }
}
