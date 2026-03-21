import SwiftUI

@main
struct calpaperApp: App {
    @State private var settings: CalendarSettings
    @State private var calendarService = CalendarService()
    @State private var wallpaperManager: WallpaperManager?
    @State private var updaterService = UpdaterService()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("Calpaper", systemImage: "calendar", isInserted: menuBarInserted) {
            if let wallpaperManager {
                MenuBarPopover()
                    .environment(wallpaperManager)
                    .environment(calendarService)
                    .environment(updaterService)
            } else {
                ProgressView("Loading...")
                    .padding()
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            if let wallpaperManager {
                SettingsView()
                    .environment(wallpaperManager)
                    .environment(calendarService)
                    .environment(updaterService)
            }
        }
    }

    private var menuBarInserted: Binding<Bool> {
        Binding(
            get: { !settings.hideMenuBarIcon },
            set: { settings.hideMenuBarIcon = !$0 }
        )
    }

    init() {
        let s = CalendarSettings()
        let cs = CalendarService()
        _settings = State(initialValue: s)
        _calendarService = State(initialValue: cs)
        let wm = WallpaperManager(settings: s, calendarService: cs)
        _wallpaperManager = State(initialValue: wm)
        wm.start()

        // If menu bar icon is hidden and app is relaunched, open settings
        if s.hideMenuBarIcon {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }
}
