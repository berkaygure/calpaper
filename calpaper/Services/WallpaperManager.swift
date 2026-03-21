import AppKit
import EventKit

@Observable
final class WallpaperManager {
    let settings: CalendarSettings
    let calendarService: CalendarService
    let scheduler: SchedulerService
    private let displayManager = DisplayManager()
    private let renderer: CalendarRenderer

    var lastUpdated: Date?
    var previewImage: NSImage?

    init(settings: CalendarSettings, calendarService: CalendarService) {
        self.settings = settings
        self.calendarService = calendarService
        self.scheduler = SchedulerService()
        self.renderer = CalendarRenderer(settings: settings)

        scheduler.onUpdate = { [weak self] in
            self?.updateWallpaper()
        }
    }

    func start() {
        scheduler.start()
        updateWallpaper()
    }

    func updateWallpaper() {
        var month = CalendarMonth.build()

        // Fetch events if enabled
        if settings.showEvents && calendarService.authorizationStatus == .fullAccess {
            let eventsByDate = calendarService.fetchEvents(for: month, calendarIDs: settings.selectedCalendarIDs)
            let calendar = Calendar.current
            for weekIndex in month.weeks.indices {
                for dayIndex in month.weeks[weekIndex].indices {
                    if let date = month.weeks[weekIndex][dayIndex].date {
                        let dayStart = calendar.startOfDay(for: date)
                        if let events = eventsByDate[dayStart] {
                            month.weeks[weekIndex][dayIndex].events = events
                        }
                    }
                }
            }
        }

        // Collect today's events for the caption area
        let todayEvents = todayEventsFrom(month: month)

        // Clean up old wallpapers
        let wallpapersDir = Constants.wallpapersURL
        if let oldFiles = try? FileManager.default.contentsOfDirectory(at: wallpapersDir, includingPropertiesForKeys: nil) {
            for file in oldFiles where file.pathExtension == "png" {
                try? FileManager.default.removeItem(at: file)
            }
        }

        let allScreens = displayManager.screens
        let enabledIDs = settings.enabledDisplayIDs
        // Empty set = all displays enabled (default behavior)
        let screens = allScreens.filter { screen in
            enabledIDs.isEmpty || enabledIDs.contains(screen.displayID)
        }

        var imageURLs: [NSScreen: URL] = [:]
        let timestamp = Int(Date().timeIntervalSince1970)

        for (index, screen) in screens.enumerated() {
            let size = screen.frame.size
            let scaleFactor = screen.backingScaleFactor

            let image = renderer.render(month: month, screenSize: size, scaleFactor: scaleFactor, todayEvents: todayEvents)

            let fileName = "wallpaper_\(index)_\(timestamp).png"
            let fileURL = wallpapersDir.appendingPathComponent(fileName)

            guard let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                continue
            }

            do {
                try pngData.write(to: fileURL)
                imageURLs[screen] = fileURL
            } catch {
                print("Failed to save wallpaper: \(error)")
            }

            if index == 0 {
                previewImage = image
            }
        }

        do {
            try displayManager.setWallpaperForAllScreens(imageURLs: imageURLs)
            lastUpdated = Date()
        } catch {
            print("Failed to set wallpaper: \(error)")
        }
    }

    func generatePreview(size: NSSize) -> NSImage {
        var month = CalendarMonth.build()

        if settings.showEvents && calendarService.authorizationStatus == .fullAccess {
            let eventsByDate = calendarService.fetchEvents(for: month, calendarIDs: settings.selectedCalendarIDs)
            let calendar = Calendar.current
            for weekIndex in month.weeks.indices {
                for dayIndex in month.weeks[weekIndex].indices {
                    if let date = month.weeks[weekIndex][dayIndex].date {
                        let dayStart = calendar.startOfDay(for: date)
                        if let events = eventsByDate[dayStart] {
                            month.weeks[weekIndex][dayIndex].events = events
                        }
                    }
                }
            }
        }

        let todayEvents = todayEventsFrom(month: month)
        return renderer.render(month: month, screenSize: size, todayEvents: todayEvents)
    }

    private func todayEventsFrom(month: CalendarMonth) -> [CalendarEvent] {
        for week in month.weeks {
            for day in week {
                if day.isToday {
                    return day.events
                }
            }
        }
        return []
    }
}
