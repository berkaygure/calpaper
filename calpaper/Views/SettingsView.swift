import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Appearance", systemImage: "paintbrush") {
                AppearanceSettingsView()
            }
            Tab("Calendars", systemImage: "calendar") {
                CalendarSelectionView()
            }
            Tab("General", systemImage: "gear") {
                GeneralSettingsView()
            }
        }
        .frame(width: 700, height: 580)
    }
}

struct GeneralSettingsView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    updateLoginItem(enabled: newValue)
                }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
