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
    @Environment(UpdaterService.self) private var updaterService

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        updateLoginItem(enabled: newValue)
                    }
            }

            Section("Updates") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Calpaper v\(Bundle.main.marketingVersion)")
                            .font(.headline)
                        Text("Build \(Bundle.main.buildNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates") {
                        updaterService.checkForUpdates()
                    }
                }
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

extension Bundle {
    var marketingVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
