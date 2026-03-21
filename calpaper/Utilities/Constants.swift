import Foundation

enum Constants {
    static let appSupportDirectoryName = "com.berkaygure.calpaper"
    static let wallpapersDirectoryName = "wallpapers"

    static var appSupportURL: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(appSupportDirectoryName)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var wallpapersURL: URL {
        let url = appSupportURL.appendingPathComponent(wallpapersDirectoryName)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static let defaultBackgroundColorHex = "#1E1E2E"
    static let defaultTextColorHex = "#CDD6F4"
    static let defaultHighlightColorHex = "#89B4FA"
    static let defaultWeekdayColorHex = "#6C7086"
    static let defaultPastDayColorHex = "#313244"
    static let defaultFutureDayColorHex = "#45475A"
    static let defaultPanelColorHex = "#2A2A3C"
    static let defaultCaptionFontName = "Snell Roundhand"
    static let defaultEventDotColorsHex = ["#F38BA8", "#A6E3A1", "#FAB387", "#89DCEB"]
    static let defaultFontName = "SF Pro"
    static let defaultFontSize: CGFloat = 14.0
    static let defaultCalendarScale: CGFloat = 0.35
    static let maxEventDotsPerDay = 4
}
