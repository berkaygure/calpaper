import SwiftUI

@main
struct calpaperApp: App {
    @State private var settings = CalendarSettings()
    @State private var calendarService = CalendarService()
    @State private var wallpaperManager: WallpaperManager?
    @State private var updaterService = UpdaterService()

    var body: some Scene {
        MenuBarExtra("Calpaper", systemImage: "calendar") {
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

    init() {
        let s = CalendarSettings()
        let cs = CalendarService()
        _settings = State(initialValue: s)
        _calendarService = State(initialValue: cs)
        let wm = WallpaperManager(settings: s, calendarService: cs)
        _wallpaperManager = State(initialValue: wm)
        wm.start()
    }
}
