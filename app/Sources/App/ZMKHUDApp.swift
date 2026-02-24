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
        
        updateMenuBarIcon()
        
        let menu = NSMenu()
        
        // HUD controls
        let showItem = NSMenuItem(title: "Show HUD", action: #selector(showHUD), keyEquivalent: "h")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(showItem)
        
        let hideItem = NSMenuItem(title: "Hide HUD", action: #selector(hideHUD), keyEquivalent: "")
        menu.addItem(hideItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Test mode
        testModeMenuItem = NSMenuItem(title: "Enable Test Mode", action: #selector(toggleTestMode), keyEquivalent: "t")
        testModeMenuItem?.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(testModeMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        
        // Reload
        let reloadItem = NSMenuItem(title: "Reload Keymap", action: #selector(reloadKeymap), keyEquivalent: "r")
        reloadItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(reloadItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit ZMK HUD", action: #selector(quit), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Observe connection state
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStateChanged),
            name: NSNotification.Name("HIDConnectionChanged"),
            object: nil
        )
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusItem.button else { return }
        
        let symbolName: String
        let accessibilityDescription: String
        
        if appState.testModeEnabled {
            symbolName = "keyboard.badge.ellipsis"
            accessibilityDescription = "ZMK HUD (Test Mode)"
        } else if appState.isConnected {
            symbolName = "keyboard.fill"
            accessibilityDescription = "ZMK HUD (Connected)"
        } else {
            symbolName = "keyboard"
            accessibilityDescription = "ZMK HUD (Disconnected)"
        }
        
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription)
    }
    
    @objc func connectionStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMenuBarIcon()
        }
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
        
        updateMenuBarIcon()
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
