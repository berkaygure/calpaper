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

    @State private var screens: [NSScreen] = NSScreen.screens

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        Form {
            Section("Displays") {
                if screens.count <= 1 {
                    Text("Only one display connected.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Choose which displays get the calendar wallpaper.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(screens, id: \.displayID) { screen in
                        let id = screen.displayID
                        let isMain = screen == NSScreen.main
                        Toggle(isOn: Binding(
                            get: {
                                settings.enabledDisplayIDs.isEmpty || settings.enabledDisplayIDs.contains(id)
                            },
                            set: { enabled in
                                // First use: populate with all display IDs
                                if settings.enabledDisplayIDs.isEmpty {
                                    settings.enabledDisplayIDs = Set(screens.map(\.displayID))
                                }
                                if enabled {
                                    settings.enabledDisplayIDs.insert(id)
                                } else {
                                    settings.enabledDisplayIDs.remove(id)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: isMain ? "display" : "rectangle.on.rectangle")
                                VStack(alignment: .leading) {
                                    Text(screen.displayName)
                                    Text("\(Int(screen.frame.width))x\(Int(screen.frame.height))\(isMain ? " — Main" : "")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
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
