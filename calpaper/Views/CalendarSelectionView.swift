import SwiftUI
import EventKit

struct CalendarSelectionView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager
    @Environment(CalendarService.self) private var calendarService

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
                            Text("Permission was denied. Please grant access in System Settings > Privacy & Security > Calendars.")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }

                        Button("Grant Calendar Access") {
                            Task {
                                await calendarService.requestAccess()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
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
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.loadCalendars()
            }
        }
    }
}
