import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager

    private let captionFonts: [FontItem] = FontItem.available()

    @State private var showSaveThemeSheet = false
    @State private var newThemeName = ""
    @State private var themes: [CalendarTheme] = ThemeStore.allThemes()

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        HSplitView {
            ScrollView {
                Form {
                    Section("Theme") {
                        ThemeGridView(themes: themes, onSelect: { theme in
                            settings.applyTheme(theme)
                        }, onDelete: { theme in
                            ThemeStore.deleteTheme(id: theme.id)
                            themes = ThemeStore.allThemes()
                        })

                        Button("Save Current as Theme...") {
                            newThemeName = ""
                            showSaveThemeSheet = true
                        }
                    }

                    Section("Display Mode") {
                        Picker("Mode", selection: $settings.displayMode) {
                            ForEach(CalendarDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Font") {
                        Picker("Caption Font", selection: $settings.captionFontName) {
                            ForEach(captionFonts) { font in
                                Text(font.displayName)
                                    .font(.custom(font.name, size: 14))
                                    .tag(font.name)
                            }
                        }
                    }

                    Section("Colors") {
                        ColorPickerRow(title: "Calendar Background", hex: $settings.backgroundColorHex)
                        ColorPickerRow(title: "Caption Background", hex: $settings.panelColorHex)
                        ColorPickerRow(title: "Text", hex: $settings.textColorHex)
                        ColorPickerRow(title: "Today Highlight", hex: $settings.highlightColorHex)
                        ColorPickerRow(title: "Weekday Labels", hex: $settings.weekdayColorHex)
                        ColorPickerRow(title: "Future Days", hex: $settings.futureDayColorHex)
                        if settings.displayMode == .progressBar {
                            ColorPickerRow(title: "Completed Days", hex: $settings.pastDayColorHex)
                        }
                    }

                    Section("Grid Options") {
                        Toggle("Show Only Current Month", isOn: $settings.showOnlyCurrentMonth)
                        Toggle("Show Day Numbers", isOn: $settings.showDayNumbers)
                        HStack {
                            Text("Cell Shape")
                            Slider(value: $settings.cellCornerRadius, in: 0.0...1.0)
                        }
                    }

                    Section("Layout") {
                        HStack {
                            Text("Calendar Size")
                            Slider(value: $settings.calendarScale, in: 0.15...0.6)
                        }
                        HStack {
                            Text("Horizontal Position")
                            Slider(value: $settings.calendarPositionX, in: 0.1...0.9)
                        }
                        HStack {
                            Text("Vertical Position")
                            Slider(value: $settings.calendarPositionY, in: 0.1...0.9)
                        }
                    }
                }
                .formStyle(.grouped)
            }
            .frame(minWidth: 300)

            VStack {
                Text("Preview")
                    .font(.headline)
                    .padding(.top, 8)
                CalendarPreviewView()
                    .padding(8)
            }
            .frame(minWidth: 220)
        }
        .padding()
        .sheet(isPresented: $showSaveThemeSheet) {
            VStack(spacing: 16) {
                Text("Save Theme")
                    .font(.headline)
                TextField("Theme Name", text: $newThemeName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                HStack {
                    Button("Cancel") {
                        showSaveThemeSheet = false
                    }
                    Button("Save") {
                        let theme = settings.toTheme(name: newThemeName)
                        ThemeStore.addTheme(theme)
                        themes = ThemeStore.allThemes()
                        showSaveThemeSheet = false
                    }
                    .disabled(newThemeName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Theme Grid

struct ThemeGridView: View {
    let themes: [CalendarTheme]
    let onSelect: (CalendarTheme) -> Void
    let onDelete: (CalendarTheme) -> Void

    let columns = [GridItem(.adaptive(minimum: 70, maximum: 90))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(themes) { theme in
                ThemeSwatchView(theme: theme)
                    .onTapGesture { onSelect(theme) }
                    .contextMenu {
                        if !theme.isBuiltIn {
                            Button("Delete", role: .destructive) {
                                onDelete(theme)
                            }
                        }
                    }
            }
        }
    }
}

struct ThemeSwatchView: View {
    let theme: CalendarTheme

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Background split
                HStack(spacing: 0) {
                    Color(nsColor: NSColor(hex: theme.panelColorHex))
                    Color(nsColor: NSColor(hex: theme.backgroundColorHex))
                }
                // Dots preview
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color(nsColor: NSColor(hex: theme.pastDayColorHex)))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color(nsColor: NSColor(hex: theme.highlightColorHex)))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color(nsColor: NSColor(hex: theme.futureDayColorHex)))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )

            Text(theme.name)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 80)
    }
}

// MARK: - Helpers

struct FontItem: Identifiable {
    let id: String
    let name: String
    let displayName: String

    init(name: String, displayName: String) {
        self.id = name
        self.name = name
        self.displayName = displayName
    }

    static func available() -> [FontItem] {
        let candidates: [(String, String)] = [
            ("Snell Roundhand", "Snell Roundhand"),
            ("SnellRoundhand-Bold", "Snell Roundhand Bold"),
            ("BradleyHandITCTT-Bold", "Bradley Hand"),
            ("SignPainter-HouseScript", "SignPainter"),
            ("Zapfino", "Zapfino"),
            ("Noteworthy-Light", "Noteworthy Light"),
            ("Noteworthy-Bold", "Noteworthy Bold"),
            ("Chalkboard SE", "Chalkboard SE"),
            ("Georgia", "Georgia"),
            ("Georgia-Italic", "Georgia Italic"),
            ("Baskerville", "Baskerville"),
            ("Baskerville-Italic", "Baskerville Italic"),
            ("Didot", "Didot"),
            ("Didot-Italic", "Didot Italic"),
        ]
        return candidates.compactMap { pair in
            NSFont(name: pair.0, size: 12) != nil ? FontItem(name: pair.0, displayName: pair.1) : nil
        }
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var hex: String

    @State private var color: Color = .black

    var body: some View {
        ColorPicker(title, selection: $color, supportsOpacity: false)
            .onAppear {
                color = Color(nsColor: NSColor(hex: hex))
            }
            .onChange(of: color) { _, newValue in
                hex = NSColor(newValue).hexString
            }
    }
}
