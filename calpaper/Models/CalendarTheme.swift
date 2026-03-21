import Foundation

struct CalendarTheme: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var backgroundColorHex: String
    var textColorHex: String
    var highlightColorHex: String
    var weekdayColorHex: String
    var pastDayColorHex: String
    var futureDayColorHex: String
    var panelColorHex: String
    var captionFontName: String
    var isBuiltIn: Bool

    func matchesColors(of settings: CalendarSettings) -> Bool {
        backgroundColorHex == settings.backgroundColorHex &&
        textColorHex == settings.textColorHex &&
        highlightColorHex == settings.highlightColorHex &&
        weekdayColorHex == settings.weekdayColorHex &&
        pastDayColorHex == settings.pastDayColorHex &&
        futureDayColorHex == settings.futureDayColorHex &&
        panelColorHex == settings.panelColorHex
    }

    func matchesColors(of profile: DisplayProfile) -> Bool {
        backgroundColorHex == profile.backgroundColorHex &&
        textColorHex == profile.textColorHex &&
        highlightColorHex == profile.highlightColorHex &&
        weekdayColorHex == profile.weekdayColorHex &&
        pastDayColorHex == profile.pastDayColorHex &&
        futureDayColorHex == profile.futureDayColorHex &&
        panelColorHex == profile.panelColorHex
    }

    static let builtInThemes: [CalendarTheme] = [
        // Dark elegant — Catppuccin Mocha inspired
        CalendarTheme(
            id: "catppuccin-mocha",
            name: "Catppuccin Mocha",
            backgroundColorHex: "#1E1E2E",
            textColorHex: "#CDD6F4",
            highlightColorHex: "#89B4FA",
            weekdayColorHex: "#6C7086",
            pastDayColorHex: "#313244",
            futureDayColorHex: "#45475A",
            panelColorHex: "#2A2A3C",
            captionFontName: "Snell Roundhand",
            isBuiltIn: true
        ),
        // Warm dark — cozy amber tones
        CalendarTheme(
            id: "midnight-amber",
            name: "Midnight Amber",
            backgroundColorHex: "#1A1410",
            textColorHex: "#E8DCC8",
            highlightColorHex: "#E8913A",
            weekdayColorHex: "#7A6B5A",
            pastDayColorHex: "#2D2418",
            futureDayColorHex: "#3A2F22",
            panelColorHex: "#221C14",
            captionFontName: "Georgia",
            isBuiltIn: true
        ),
        // Nord inspired — cool blues
        CalendarTheme(
            id: "nordic-frost",
            name: "Nordic Frost",
            backgroundColorHex: "#2E3440",
            textColorHex: "#ECEFF4",
            highlightColorHex: "#88C0D0",
            weekdayColorHex: "#4C566A",
            pastDayColorHex: "#3B4252",
            futureDayColorHex: "#434C5E",
            panelColorHex: "#353B49",
            captionFontName: "Snell Roundhand",
            isBuiltIn: true
        ),
        // Rosé Pine
        CalendarTheme(
            id: "rose-pine",
            name: "Rosé Pine",
            backgroundColorHex: "#191724",
            textColorHex: "#E0DEF4",
            highlightColorHex: "#EB6F92",
            weekdayColorHex: "#6E6A86",
            pastDayColorHex: "#26233A",
            futureDayColorHex: "#2A2740",
            panelColorHex: "#1F1D2E",
            captionFontName: "Didot-Italic",
            isBuiltIn: true
        ),
        // Dracula
        CalendarTheme(
            id: "dracula",
            name: "Dracula",
            backgroundColorHex: "#282A36",
            textColorHex: "#F8F8F2",
            highlightColorHex: "#BD93F9",
            weekdayColorHex: "#6272A4",
            pastDayColorHex: "#343746",
            futureDayColorHex: "#3C3F58",
            panelColorHex: "#2F3143",
            captionFontName: "Snell Roundhand",
            isBuiltIn: true
        ),
        // Gruvbox dark
        CalendarTheme(
            id: "gruvbox-dark",
            name: "Gruvbox Dark",
            backgroundColorHex: "#282828",
            textColorHex: "#EBDBB2",
            highlightColorHex: "#FABD2F",
            weekdayColorHex: "#928374",
            pastDayColorHex: "#3C3836",
            futureDayColorHex: "#504945",
            panelColorHex: "#32302F",
            captionFontName: "Georgia",
            isBuiltIn: true
        ),
        // Ocean breeze — deep blue to teal
        CalendarTheme(
            id: "ocean-breeze",
            name: "Ocean Breeze",
            backgroundColorHex: "#0B1929",
            textColorHex: "#C4E0F0",
            highlightColorHex: "#4DD0E1",
            weekdayColorHex: "#3A5A7A",
            pastDayColorHex: "#112840",
            futureDayColorHex: "#1A3550",
            panelColorHex: "#0E2030",
            captionFontName: "Snell Roundhand",
            isBuiltIn: true
        ),
        // Minimal light
        CalendarTheme(
            id: "minimal-light",
            name: "Minimal Light",
            backgroundColorHex: "#F5F5F0",
            textColorHex: "#2C2C2C",
            highlightColorHex: "#E05050",
            weekdayColorHex: "#999999",
            pastDayColorHex: "#E8E8E3",
            futureDayColorHex: "#EDEDEA",
            panelColorHex: "#EAEAE5",
            captionFontName: "Didot",
            isBuiltIn: true
        ),
        // Solarized dark
        CalendarTheme(
            id: "solarized-dark",
            name: "Solarized Dark",
            backgroundColorHex: "#002B36",
            textColorHex: "#839496",
            highlightColorHex: "#B58900",
            weekdayColorHex: "#586E75",
            pastDayColorHex: "#073642",
            futureDayColorHex: "#0A3F4C",
            panelColorHex: "#05313C",
            captionFontName: "Baskerville",
            isBuiltIn: true
        ),
        // Tokyo Night
        CalendarTheme(
            id: "tokyo-night",
            name: "Tokyo Night",
            backgroundColorHex: "#1A1B26",
            textColorHex: "#C0CAF5",
            highlightColorHex: "#7AA2F7",
            weekdayColorHex: "#565F89",
            pastDayColorHex: "#24283B",
            futureDayColorHex: "#292E42",
            panelColorHex: "#1F2030",
            captionFontName: "Snell Roundhand",
            isBuiltIn: true
        ),
    ]
}

// MARK: - Theme Storage

final class ThemeStore {
    private static let userThemesKey = "calpaper_userThemes"

    static func loadUserThemes() -> [CalendarTheme] {
        guard let data = UserDefaults.standard.data(forKey: userThemesKey),
              let themes = try? JSONDecoder().decode([CalendarTheme].self, from: data) else {
            return []
        }
        return themes
    }

    static func saveUserThemes(_ themes: [CalendarTheme]) {
        if let data = try? JSONEncoder().encode(themes) {
            UserDefaults.standard.set(data, forKey: userThemesKey)
        }
    }

    static func allThemes() -> [CalendarTheme] {
        CalendarTheme.builtInThemes + loadUserThemes()
    }

    static func addTheme(_ theme: CalendarTheme) {
        var userThemes = loadUserThemes()
        userThemes.append(theme)
        saveUserThemes(userThemes)
    }

    static func deleteTheme(id: String) {
        var userThemes = loadUserThemes()
        userThemes.removeAll { $0.id == id }
        saveUserThemes(userThemes)
    }
}
