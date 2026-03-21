import Foundation

struct DisplayProfile: Codable, Equatable {
    var backgroundColorHex: String
    var textColorHex: String
    var highlightColorHex: String
    var weekdayColorHex: String
    var pastDayColorHex: String
    var futureDayColorHex: String
    var panelColorHex: String
    var captionFontName: String
    var displayMode: String // CalendarDisplayMode raw value
    var calendarScale: CGFloat
    var calendarPositionX: CGFloat
    var calendarPositionY: CGFloat
    var cellCornerRadius: CGFloat
    var showOnlyCurrentMonth: Bool
    var showDayNumbers: Bool

    static func from(settings: CalendarSettings) -> DisplayProfile {
        DisplayProfile(
            backgroundColorHex: settings.backgroundColorHex,
            textColorHex: settings.textColorHex,
            highlightColorHex: settings.highlightColorHex,
            weekdayColorHex: settings.weekdayColorHex,
            pastDayColorHex: settings.pastDayColorHex,
            futureDayColorHex: settings.futureDayColorHex,
            panelColorHex: settings.panelColorHex,
            captionFontName: settings.captionFontName,
            displayMode: settings.displayMode.rawValue,
            calendarScale: settings.calendarScale,
            calendarPositionX: settings.calendarPositionX,
            calendarPositionY: settings.calendarPositionY,
            cellCornerRadius: settings.cellCornerRadius,
            showOnlyCurrentMonth: settings.showOnlyCurrentMonth,
            showDayNumbers: settings.showDayNumbers
        )
    }

    func apply(to settings: CalendarSettings) {
        settings.backgroundColorHex = backgroundColorHex
        settings.textColorHex = textColorHex
        settings.highlightColorHex = highlightColorHex
        settings.weekdayColorHex = weekdayColorHex
        settings.pastDayColorHex = pastDayColorHex
        settings.futureDayColorHex = futureDayColorHex
        settings.panelColorHex = panelColorHex
        settings.captionFontName = captionFontName
        settings.displayMode = CalendarDisplayMode(rawValue: displayMode) ?? .currentMonth
        settings.calendarScale = calendarScale
        settings.calendarPositionX = calendarPositionX
        settings.calendarPositionY = calendarPositionY
        settings.cellCornerRadius = cellCornerRadius
        settings.showOnlyCurrentMonth = showOnlyCurrentMonth
        settings.showDayNumbers = showDayNumbers
    }

    func applyTheme(_ theme: CalendarTheme) -> DisplayProfile {
        var copy = self
        copy.backgroundColorHex = theme.backgroundColorHex
        copy.textColorHex = theme.textColorHex
        copy.highlightColorHex = theme.highlightColorHex
        copy.weekdayColorHex = theme.weekdayColorHex
        copy.pastDayColorHex = theme.pastDayColorHex
        copy.futureDayColorHex = theme.futureDayColorHex
        copy.panelColorHex = theme.panelColorHex
        copy.captionFontName = theme.captionFontName
        return copy
    }

    /// Creates a temporary CalendarSettings from this profile for rendering
    func toSettings() -> CalendarSettings {
        let s = CalendarSettings()
        apply(to: s)
        return s
    }
}

// MARK: - Storage

final class DisplayProfileStore {
    private static let key = "calpaper_displayProfiles"

    static func load() -> [String: DisplayProfile] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profiles = try? JSONDecoder().decode([String: DisplayProfile].self, from: data) else {
            return [:]
        }
        return profiles
    }

    static func save(_ profiles: [String: DisplayProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func profile(for displayID: String) -> DisplayProfile? {
        load()[displayID]
    }

    static func setProfile(_ profile: DisplayProfile, for displayID: String) {
        var profiles = load()
        profiles[displayID] = profile
        save(profiles)
    }

    static func removeProfile(for displayID: String) {
        var profiles = load()
        profiles.removeValue(forKey: displayID)
        save(profiles)
    }
}
