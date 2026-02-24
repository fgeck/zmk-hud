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
                    ForEach(layout.positions.indices, id: \.self) { index in
                        if index < currentBindings.count, let scaled = layout.scaledPosition(for: index) {
                            RotatedKeyView(
                                binding: currentBindings[index],
                                scaled: scaled,
                                index: index,
                                isPressed: appState.pressedKeys.contains(index),
                                customLabels: appState.customLabels,
                                tapDanceShifted: appState.tapDanceShifted
                            )
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
        appState.currentBindings(for: appState.currentLayer)
    }
}

struct RotatedKeyView: View {
    let binding: Binding
    let scaled: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, rotation: CGFloat, rotationOriginX: CGFloat, rotationOriginY: CGFloat)
    let index: Int
    let isPressed: Bool
    var customLabels: [String: String] = [:]
    var tapDanceShifted: [String: String] = [:]
    
    var body: some View {
        let position = transformedPosition()
        
        KeyView(
            binding: binding,
            position: ScaledKeyPosition(
                index: index,
                x: scaled.x,
                y: scaled.y,
                width: scaled.width,
                height: scaled.height,
                rotation: scaled.rotation
            ),
            isPressed: isPressed,
            customLabels: customLabels,
            tapDanceShifted: tapDanceShifted
        )
        .rotationEffect(.degrees(scaled.rotation))
        .position(x: position.x, y: position.y)
    }
    
    private func transformedPosition() -> CGPoint {
        let keyCenterX = scaled.x + scaled.width / 2
        let keyCenterY = scaled.y + scaled.height / 2
        
        guard scaled.rotation != 0 else {
            return CGPoint(x: keyCenterX, y: keyCenterY)
        }
        
        let pivotX = scaled.rotationOriginX
        let pivotY = scaled.rotationOriginY
        
        let dx = keyCenterX - pivotX
        let dy = keyCenterY - pivotY
        
        let angleRad = scaled.rotation * .pi / 180
        
        let newX = pivotX + dx * cos(angleRad) - dy * sin(angleRad)
        let newY = pivotY + dx * sin(angleRad) + dy * cos(angleRad)
        
        return CGPoint(x: newX, y: newY)
    }
}
