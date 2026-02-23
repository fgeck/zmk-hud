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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHIDManager()
        
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
    
    @objc func reloadKeymap() {
        appState.reloadKeymap()
    }
    
    @objc func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}
