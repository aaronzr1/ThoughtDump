import SwiftUI
import SwiftData

@main
struct ThoughtDumpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible scenes — everything is driven by the AppDelegate's status item
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var modelContainer: ModelContainer!
    private var previousApp: NSRunningApplication?
    private var rightClickMenu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftData container — store in ~/Documents/ThoughtDump/
        let storeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/ThoughtDump")
        try! FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        let storeURL = storeDir.appendingPathComponent("thoughts.store")
        let config = ModelConfiguration(url: storeURL)
        modelContainer = try! ModelContainer(for: Thought.self, configurations: config)

        // Panel — positioned below the menubar icon
        let hostingView = NSHostingView(
            rootView: ContentView()
                .modelContainer(modelContainer)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 360, height: 480)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none

        // Status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "ThoughtDump")
            button.action = #selector(togglePanel)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Right-click context menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit ThoughtDump", action: #selector(quitApp), keyEquivalent: "q"))
        rightClickMenu = menu

        // Global hotkey
        HotKeyManager.shared.onToggle = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        HotKeyManager.shared.register()
    }

    @objc func togglePanel() {
        let event = NSApp.currentEvent

        // Right-click → show context menu
        if event?.type == .rightMouseUp {
            if let button = statusItem.button {
                statusItem.menu = rightClickMenu
                button.performClick(nil)
                statusItem.menu = nil
            }
            return
        }

        if panel.isVisible {
            panel.orderOut(nil)
            // Restore focus to the previously active app
            previousApp?.activate()
            previousApp = nil
        } else {
            // Remember which app had focus before we steal it
            previousApp = NSWorkspace.shared.frontmostApplication
            // Position below the status item
            if let button = statusItem.button, let window = button.window {
                let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
                let x = buttonFrame.midX - panel.frame.width / 2
                let y = buttonFrame.minY - panel.frame.height - 4
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
