import Foundation
import AppKit
import Carbon.HIToolbox

/// Simulates keyboard layer changes for testing the HUD without actual keyboard hardware.
///
/// Supports two shortcut modes:
/// - **Fn + 1-5**: Uses the function key modifier (may not work on all keyboards)
/// - **Ctrl + Option + 1-5**: Alternative that works reliably on all Macs
///
/// Layer mapping:
/// - 1 → Layer 0 (Base) - hides HUD
/// - 2 → Layer 1 (Num)
/// - 3 → Layer 2 (Nav)
/// - 4 → Layer 3 (Fn)
/// - 5 → Layer 4 (Idea)
///
/// Usage:
/// 1. Enable "Test Mode" from the menubar
/// 2. Press Ctrl+Option+2 to show Num layer
/// 3. Press Ctrl+Option+1 to return to Base (hide HUD)
class KeyboardSimulator {
    private weak var appState: AppState?
    private var eventMonitor: Any?
    private var localEventMonitor: Any?
    private var flagsMonitor: Any?
    
    private var fnPressed = false
    private var currentSimulatedLayer = 0
    
    /// Maps key codes to layer indices (1-5 on keyboard → 0-4 layer index)
    /// Key codes: 18=1, 19=2, 20=3, 21=4, 23=5
    private let numberKeyToLayerIndex: [UInt16: Int] = [
        18: 0,  // Key "1" → Layer 0 (Base)
        19: 1,  // Key "2" → Layer 1 (Num)
        20: 2,  // Key "3" → Layer 2 (Nav)
        21: 3,  // Key "4" → Layer 3 (Fn)
        23: 4   // Key "5" → Layer 4 (Idea)
    ]
    
    /// Maps QWERTY key codes to key positions for simulating key presses
    /// This allows testing combo highlighting without hardware
    private let keyCodeToPosition: [UInt16: Int] = [
        // Top row: Q W E R T | Y U I O P
        12: 0, 13: 1, 14: 2, 15: 3, 17: 4,     // Q W E R T
        16: 5, 32: 6, 34: 7, 31: 8, 35: 9,     // Y U I O P
        // Home row: A S D F G | H J K L ;
        0: 10, 1: 11, 2: 12, 3: 13, 5: 14,     // A S D F G
        4: 15, 38: 16, 40: 17, 37: 18, 41: 19, // H J K L ;
        // Bottom row: Z X C V B | N M , . /
        6: 20, 7: 21, 8: 22, 9: 23, 11: 24,    // Z X C V B
        45: 25, 46: 26, 43: 27, 47: 28, 44: 29 // N M , . /
    ]
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startMonitoring() {
        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ KeyboardSimulator: Accessibility permission required!")
            print("   Go to System Settings → Privacy & Security → Accessibility → Enable ZMKHud")
            
            // Prompt user to grant permission
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            return
        }
        
        // Monitor global key events (when app is not focused)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }
        
        // Monitor local key events (when app is focused)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
        
        // Monitor modifier flag changes for Fn key detection
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        print("✓ KeyboardSimulator: Test mode active")
        print("  Shortcuts:")
        print("  - Ctrl+Option+1: Base layer (hide HUD)")
        print("  - Ctrl+Option+2: Num layer")
        print("  - Ctrl+Option+3: Nav layer")
        print("  - Ctrl+Option+4: Fn layer")
        print("  - Ctrl+Option+5: Idea layer")
        print("  - Fn+1-5: Alternative (if Fn key works on your keyboard)")
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        print("✓ KeyboardSimulator: Test mode disabled")
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        fnPressed = flags.contains(.function)
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Check for Ctrl+Option modifier combo (reliable on all Macs)
        let ctrlOptionPressed = flags.contains(.control) && flags.contains(.option)
        
        // Accept either Fn or Ctrl+Option as trigger
        guard fnPressed || ctrlOptionPressed else { return }
        
        // Check if this is a layer switching key (1-5)
        if let layerIndex = numberKeyToLayerIndex[event.keyCode] {
            simulateLayerChange(layerIndex)
            return
        }
        
        // Check if this is a key position simulation (for combo testing)
        if let position = keyCodeToPosition[event.keyCode] {
            simulateKeyPress(position: position)
        }
    }
    
    private func simulateLayerChange(_ layer: Int) {
        guard let appState = appState else { return }
        
        // Toggle layer if pressing same non-base layer
        if layer == currentSimulatedLayer && layer != 0 {
            // Return to base layer
            appState.handleLayerChange(layer: layer, active: false, state: 1)
            currentSimulatedLayer = 0
            print("→ Layer: Base (0)")
        } else {
            // Deactivate current layer first
            if currentSimulatedLayer != 0 {
                appState.handleLayerChange(layer: currentSimulatedLayer, active: false, state: 1)
            }
            
            // Activate new layer
            let state = UInt16(1 << layer)
            appState.handleLayerChange(layer: layer, active: true, state: state)
            currentSimulatedLayer = layer
            
            let layerNames = ["Base", "Num", "Nav", "Fn", "Idea"]
            let layerName = layer < layerNames.count ? layerNames[layer] : "Layer \(layer)"
            print("→ Layer: \(layerName) (\(layer))")
        }
    }
    
    private func simulateKeyPress(position: Int) {
        guard let appState = appState else { return }
        
        // Simulate key press
        appState.handleKeyPress(keycode: UInt8(position), pressed: true, mods: 0)
        
        // Auto-release after 150ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            appState.handleKeyPress(keycode: UInt8(position), pressed: false, mods: 0)
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
