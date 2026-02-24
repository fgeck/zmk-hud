import Foundation
import AppKit
import Carbon.HIToolbox

class KeyboardSimulator {
    private weak var appState: AppState?
    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    
    private var hyperPressed = false
    private var currentSimulatedLayer = 0
    
    private let layerKeyCodeToIndex: [UInt16: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4
    ]
    
    private let keyCodeToPosition: [UInt16: Int] = [
        12: 13, 13: 14, 14: 15, 15: 16, 17: 17,
        16: 18, 32: 19, 34: 20, 31: 21, 35: 22,
        0: 25, 1: 26, 2: 27, 3: 28, 5: 29,
        4: 30, 38: 31, 40: 32, 37: 33, 41: 34,
        6: 37, 7: 38, 8: 39, 9: 40, 11: 41,
        45: 42, 46: 43, 43: 44, 47: 45,
        49: 51
    ]
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startMonitoring() {
        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("KeyboardSimulator: ⚠️ Accessibility permission required!")
            print("Go to System Settings → Privacy & Security → Accessibility → Enable ZMKHud")
            
            // Prompt user to grant permission
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            return
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }
        
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        print("KeyboardSimulator: Test mode active (Fn + 1-5 for layers)")
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Fn key is represented by the .function flag
        hyperPressed = flags.contains(.function)
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        guard hyperPressed else { return }
        
        if let layerIndex = layerKeyCodeToIndex[event.keyCode] {
            simulateLayerChange(layerIndex)
        } else if let position = keyCodeToPosition[event.keyCode] {
            simulateKeyPress(position: position)
        }
    }
    
    private func simulateLayerChange(_ layer: Int) {
        guard let appState = appState else { return }
        
        if layer == currentSimulatedLayer && layer != 0 {
            appState.handleLayerChange(layer: layer, active: false, state: 1)
            currentSimulatedLayer = 0
        } else {
            if currentSimulatedLayer != 0 {
                appState.handleLayerChange(layer: currentSimulatedLayer, active: false, state: 1)
            }
            let state = UInt16(1 << layer)
            appState.handleLayerChange(layer: layer, active: true, state: state)
            currentSimulatedLayer = layer
        }
    }
    
    private func simulateKeyPress(position: Int) {
        guard let appState = appState else { return }
        
        appState.handleKeyPress(keycode: UInt8(position), pressed: true, mods: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            appState.handleKeyPress(keycode: UInt8(position), pressed: false, mods: 0)
        }
    }
}
