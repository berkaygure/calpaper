import Foundation
import SwiftUI

enum CalendarDisplayMode: String, CaseIterable, Codable {
    case currentMonth = "currentMonth"
    case progressBar = "progressBar"

    var label: String {
        switch self {
        case .currentMonth: "Current Month"
        case .progressBar: "Progress Tracker"
        }
    }
}

@Observable
final class CalendarSettings {
    // Display mode
    var displayMode: CalendarDisplayMode {
        didSet { save() }
    }

    // Appearance
    var backgroundColorHex: String {
        didSet { save() }
    }
    var textColorHex: String {
        didSet { save() }
    }
    var highlightColorHex: String {
        didSet { save() }
    }
    var weekdayColorHex: String {
        didSet { save() }
    }
    var pastDayColorHex: String {
        didSet { save() }
    }
    var futureDayColorHex: String {
        didSet { save() }
    }
    var panelColorHex: String {
        didSet { save() }
    }
    var panelCornerRadius: CGFloat {
        didSet { save() }
    }
    var captionFontName: String {
        didSet { save() }
    }
    var fontName: String {
        didSet { save() }
    }
    var fontSize: CGFloat {
        didSet { save() }
    }
    var calendarScale: CGFloat {
        didSet { save() }
    }
    var calendarPositionX: CGFloat {
        didSet { save() }
    }
    var calendarPositionY: CGFloat {
        didSet { save() }
    }

    // Grid options
    var showOnlyCurrentMonth: Bool {
        didSet { save() }
    }
    var showDayNumbers: Bool {
        didSet { save() }
    }
    var cellCornerRadius: CGFloat {
        didSet { save() }
    }

    // Calendar selection
    var selectedCalendarIDs: Set<String> {
        didSet { save() }
    }
    var showEvents: Bool {
        didSet { save() }
    }

    // General
    var launchAtLogin: Bool {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard
    private let prefix = "calpaper_"

    init() {
        displayMode = UserDefaults.standard.string(forKey: "calpaper_displayMode")
            .flatMap { CalendarDisplayMode(rawValue: $0) } ?? .currentMonth
        backgroundColorHex = UserDefaults.standard.string(forKey: "calpaper_backgroundColorHex") ?? Constants.defaultBackgroundColorHex
        textColorHex = UserDefaults.standard.string(forKey: "calpaper_textColorHex") ?? Constants.defaultTextColorHex
        highlightColorHex = UserDefaults.standard.string(forKey: "calpaper_highlightColorHex") ?? Constants.defaultHighlightColorHex
        weekdayColorHex = UserDefaults.standard.string(forKey: "calpaper_weekdayColorHex") ?? Constants.defaultWeekdayColorHex
        pastDayColorHex = UserDefaults.standard.string(forKey: "calpaper_pastDayColorHex") ?? Constants.defaultPastDayColorHex
        futureDayColorHex = UserDefaults.standard.string(forKey: "calpaper_futureDayColorHex") ?? Constants.defaultFutureDayColorHex
        panelColorHex = UserDefaults.standard.string(forKey: "calpaper_panelColorHex") ?? Constants.defaultPanelColorHex
        panelCornerRadius = UserDefaults.standard.object(forKey: "calpaper_panelCornerRadius") as? CGFloat ?? 0.3
        captionFontName = UserDefaults.standard.string(forKey: "calpaper_captionFontName") ?? Constants.defaultCaptionFontName
        fontName = UserDefaults.standard.string(forKey: "calpaper_fontName") ?? Constants.defaultFontName
        fontSize = UserDefaults.standard.object(forKey: "calpaper_fontSize") as? CGFloat ?? Constants.defaultFontSize
        calendarScale = UserDefaults.standard.object(forKey: "calpaper_calendarScale") as? CGFloat ?? Constants.defaultCalendarScale
        calendarPositionX = UserDefaults.standard.object(forKey: "calpaper_calendarPositionX") as? CGFloat ?? 0.5
        calendarPositionY = UserDefaults.standard.object(forKey: "calpaper_calendarPositionY") as? CGFloat ?? 0.5
        showOnlyCurrentMonth = UserDefaults.standard.object(forKey: "calpaper_showOnlyCurrentMonth") as? Bool ?? false
        showDayNumbers = UserDefaults.standard.object(forKey: "calpaper_showDayNumbers") as? Bool ?? true
        cellCornerRadius = UserDefaults.standard.object(forKey: "calpaper_cellCornerRadius") as? CGFloat ?? 0.5
        selectedCalendarIDs = Set(UserDefaults.standard.stringArray(forKey: "calpaper_selectedCalendarIDs") ?? [])
        showEvents = UserDefaults.standard.object(forKey: "calpaper_showEvents") as? Bool ?? true
        launchAtLogin = UserDefaults.standard.object(forKey: "calpaper_launchAtLogin") as? Bool ?? false
    }

    private func save() {
        defaults.set(displayMode.rawValue, forKey: "\(prefix)displayMode")
        defaults.set(backgroundColorHex, forKey: "\(prefix)backgroundColorHex")
        defaults.set(textColorHex, forKey: "\(prefix)textColorHex")
        defaults.set(highlightColorHex, forKey: "\(prefix)highlightColorHex")
        defaults.set(weekdayColorHex, forKey: "\(prefix)weekdayColorHex")
        defaults.set(pastDayColorHex, forKey: "\(prefix)pastDayColorHex")
        defaults.set(futureDayColorHex, forKey: "\(prefix)futureDayColorHex")
        defaults.set(panelColorHex, forKey: "\(prefix)panelColorHex")
        defaults.set(panelCornerRadius, forKey: "\(prefix)panelCornerRadius")
        defaults.set(captionFontName, forKey: "\(prefix)captionFontName")
        defaults.set(fontName, forKey: "\(prefix)fontName")
        defaults.set(fontSize, forKey: "\(prefix)fontSize")
        defaults.set(calendarScale, forKey: "\(prefix)calendarScale")
        defaults.set(calendarPositionX, forKey: "\(prefix)calendarPositionX")
        defaults.set(calendarPositionY, forKey: "\(prefix)calendarPositionY")
        defaults.set(showOnlyCurrentMonth, forKey: "\(prefix)showOnlyCurrentMonth")
        defaults.set(showDayNumbers, forKey: "\(prefix)showDayNumbers")
        defaults.set(cellCornerRadius, forKey: "\(prefix)cellCornerRadius")
        defaults.set(Array(selectedCalendarIDs), forKey: "\(prefix)selectedCalendarIDs")
        defaults.set(showEvents, forKey: "\(prefix)showEvents")
        defaults.set(launchAtLogin, forKey: "\(prefix)launchAtLogin")
    }

    var backgroundColor: NSColor { NSColor(hex: backgroundColorHex) }
    var textColor: NSColor { NSColor(hex: textColorHex) }
    var highlightColor: NSColor { NSColor(hex: highlightColorHex) }
    var weekdayColor: NSColor { NSColor(hex: weekdayColorHex) }
    var pastDayColor: NSColor { NSColor(hex: pastDayColorHex) }
    var futureDayColor: NSColor { NSColor(hex: futureDayColorHex) }
    var panelColor: NSColor { NSColor(hex: panelColorHex) }

    func applyTheme(_ theme: CalendarTheme) {
        backgroundColorHex = theme.backgroundColorHex
        textColorHex = theme.textColorHex
        highlightColorHex = theme.highlightColorHex
        weekdayColorHex = theme.weekdayColorHex
        pastDayColorHex = theme.pastDayColorHex
        futureDayColorHex = theme.futureDayColorHex
        panelColorHex = theme.panelColorHex
        captionFontName = theme.captionFontName
    }

    func toTheme(name: String) -> CalendarTheme {
        CalendarTheme(
            id: UUID().uuidString,
            name: name,
            backgroundColorHex: backgroundColorHex,
            textColorHex: textColorHex,
            highlightColorHex: highlightColorHex,
            weekdayColorHex: weekdayColorHex,
            pastDayColorHex: pastDayColorHex,
            futureDayColorHex: futureDayColorHex,
            panelColorHex: panelColorHex,
            captionFontName: captionFontName,
            isBuiltIn: false
        )
    }
}
