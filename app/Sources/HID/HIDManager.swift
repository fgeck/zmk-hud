import Foundation
import IOKit
import IOKit.hid

class HIDManager {
    private let appState: AppState
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    
    private let vendorID: Int = 0x1d50
    private let usagePage: Int = 0xFF60
    
    private enum MessageType: UInt8 {
        case layerChange = 0x01
        case keyPress = 0x02
    }
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startMonitoring() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else { return }
        
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: usagePage
        ]
        
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
        
        let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let hidManager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            hidManager.deviceConnected(device)
        }
        
        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let hidManager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            hidManager.deviceDisconnected(device)
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
    
    private func deviceConnected(_ device: IOHIDDevice) {
        self.device = device
        
        let inputCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
            guard let context = context else { return }
            let hidManager = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            hidManager.handleReport(report, length: reportLength)
        }
        
        var reportBuffer = [UInt8](repeating: 0, count: 32)
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        IOHIDDeviceRegisterInputReportCallback(
            device,
            &reportBuffer,
            reportBuffer.count,
            inputCallback,
            context
        )
        
        print("ZMK HUD device connected")
    }
    
    private func deviceDisconnected(_ device: IOHIDDevice) {
        if self.device == device {
            self.device = nil
            print("ZMK HUD device disconnected")
        }
    }
    
    private func handleReport(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length >= 4 else { return }
        
        let messageType = report[0]
        
        switch MessageType(rawValue: messageType) {
        case .layerChange:
            let layer = Int(report[1])
            let active = report[2] != 0
            let state = UInt16(report[3]) | (UInt16(report[4]) << 8)
            appState.handleLayerChange(layer: layer, active: active, state: state)
            
        case .keyPress:
            let keycode = report[1]
            let pressed = report[2] != 0
            let mods = report[3]
            appState.handleKeyPress(keycode: keycode, pressed: pressed, mods: mods)
            
        default:
            break
        }
    }
    
    func stopMonitoring() {
        guard let manager = manager else { return }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
    }
}
