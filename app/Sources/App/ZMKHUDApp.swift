import SwiftUI
import AppKit

@main
struct ZMKHUDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var appState = AppState()
    var hudWindow: HUDWindow?
    var hidManager: HIDManager?
    var keyboardSimulator: KeyboardSimulator?
    var testModeMenuItem: NSMenuItem?
    var settingsWindow: NSWindow?
    var globalHotkeyMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHIDManager()
        setupGlobalHotkey()
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ZMK HUD")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show HUD", action: #selector(showHUD), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Hide HUD", action: #selector(hideHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        testModeMenuItem = NSMenuItem(title: "Enable Test Mode", action: #selector(toggleTestMode), keyEquivalent: "t")
        menu.addItem(testModeMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reload Keymap", action: #selector(reloadKeymap), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func setupHIDManager() {
        hidManager = HIDManager(appState: appState)
        hidManager?.startMonitoring()
    }
    
    private func setupGlobalHotkey() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "h" {
                DispatchQueue.main.async {
                    self?.toggleHUD()
                }
            }
        }
    }
    
    @objc func toggleHUD() {
        if appState.hudVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }
    
    
    @objc func showHUD() {
        if hudWindow == nil {
            hudWindow = HUDWindow(appState: appState)
        }
        hudWindow?.show()
        appState.hudVisible = true
    }
    
    @objc func hideHUD() {
        hudWindow?.hide()
        appState.hudVisible = false
    }
    
    @objc func toggleTestMode() {
        appState.testModeEnabled.toggle()
        
        if appState.testModeEnabled {
            keyboardSimulator = KeyboardSimulator(appState: appState)
            keyboardSimulator?.startMonitoring()
            testModeMenuItem?.title = "Disable Test Mode"
            showHUD()
        } else {
            keyboardSimulator?.stopMonitoring()
            keyboardSimulator = nil
            testModeMenuItem?.title = "Enable Test Mode"
        }
    }
    
    @objc func reloadKeymap() {
        appState.reloadKeymap()
    }
    
    @objc func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        settingsWindow = createSettingsWindow()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createSettingsWindow() -> NSWindow {
        let settingsView = SettingsView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "ZMK HUD Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 450, height: 480))
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }
    
    @objc func quit() {
        keyboardSimulator?.stopMonitoring()
        NSApp.terminate(nil)
    }
}
