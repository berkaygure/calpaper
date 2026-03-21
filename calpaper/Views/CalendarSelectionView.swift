import SwiftUI
import EventKit

struct CalendarSelectionView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager
    @Environment(CalendarService.self) private var calendarService

    @State private var showRestartAlert = false
    @State private var accessJustGranted = false

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        Form {
            Section {
                Toggle("Show Events on Wallpaper", isOn: $settings.showEvents)
            }

            if calendarService.authorizationStatus != .fullAccess {
                Section("Permission Required") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calendar access is needed to display events on the wallpaper.")
                            .foregroundStyle(.secondary)

                        if calendarService.authorizationStatus == .denied {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Permission was denied. Please grant access in System Settings > Privacy & Security > Calendars, then restart Calpaper.")
                                    .foregroundStyle(.red)
                                    .font(.caption)

                                HStack {
                                    Button("Open System Settings") {
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                                    }

                                    Button("Restart Calpaper") {
                                        restartApp()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        } else {
                            Button("Grant Calendar Access") {
                                Task {
                                    let granted = await calendarService.requestAccess()
                                    if granted {
                                        accessJustGranted = true
                                        wallpaperManager.updateWallpaper()
                                    } else {
                                        // Permission dialog was shown but access wasn't granted yet
                                        // Re-check status after a short delay
                                        try? await Task.sleep(for: .seconds(1))
                                        calendarService.refreshStatus()
                                        if calendarService.authorizationStatus == .fullAccess {
                                            calendarService.loadCalendars()
                                            accessJustGranted = true
                                            wallpaperManager.updateWallpaper()
                                        } else if calendarService.authorizationStatus != .notDetermined {
                                            showRestartAlert = true
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } else {
                if accessJustGranted {
                    Section {
                        Label("Calendar access granted!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                let grouped = Dictionary(grouping: calendarService.availableCalendars, by: { $0.source.title })
                ForEach(grouped.keys.sorted(), id: \.self) { sourceName in
                    Section(sourceName) {
                        ForEach(grouped[sourceName]!, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: Binding(
                                get: { settings.selectedCalendarIDs.contains(calendar.calendarIdentifier) },
                                set: { isOn in
                                    if isOn {
                                        settings.selectedCalendarIDs.insert(calendar.calendarIdentifier)
                                    } else {
                                        settings.selectedCalendarIDs.remove(calendar.calendarIdentifier)
                                    }
                                }
                            )) {
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            calendarService.refreshStatus()
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.loadCalendars()
            }
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now") {
                restartApp()
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Calendar access may require restarting Calpaper to take effect. Would you like to restart now?")
        }
    }

    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path, "--args", "--relaunch"]
        task.launch()
        NSApplication.shared.terminate(nil)
    }
}
