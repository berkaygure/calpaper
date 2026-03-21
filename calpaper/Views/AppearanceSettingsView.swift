import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager

    private let captionFonts: [FontItem] = FontItem.available()

    @State private var showSaveThemeSheet = false
    @State private var newThemeName = ""
    @State private var themes: [CalendarTheme] = ThemeStore.allThemes()

    // Display selection
    @State private var selectedDisplayID: String = "all"
    @State private var screens: [NSScreen] = NSScreen.screens
    @State private var profile: DisplayProfile?

    private var isPerDisplay: Bool { selectedDisplayID != "all" }

    var body: some View {
        @Bindable var settings = wallpaperManager.settings

        HSplitView {
            ScrollView {
                Form {
                    // Display picker — only show if multiple displays
                    if screens.count > 1 {
                        Section("Display") {
                            Picker("Configure for", selection: $selectedDisplayID) {
                                Text("All Displays").tag("all")
                                ForEach(screens, id: \.displayID) { screen in
                                    HStack {
                                        Text(screen.displayName)
                                        if screen == NSScreen.main {
                                            Text("(Main)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(screen.displayID)
                                }
                            }

                            if isPerDisplay {
                                if profile != nil {
                                    Button("Reset to Global Settings", role: .destructive) {
                                        DisplayProfileStore.removeProfile(for: selectedDisplayID)
                                        profile = nil
                                    }
                                    .font(.caption)
                                } else {
                                    Text("Using global settings. Change any setting below to create a custom profile for this display.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Theme") {
                        ThemeGridView(themes: themes, onSelect: { theme in
                            if isPerDisplay {
                                let base = profile ?? DisplayProfile.from(settings: settings)
                                profile = base.applyTheme(theme)
                                saveProfile()
                            } else {
                                settings.applyTheme(theme)
                            }
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
                        Picker("Mode", selection: displayModeBinding(settings)) {
                            ForEach(CalendarDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Font") {
                        Picker("Caption Font", selection: captionFontBinding(settings)) {
                            ForEach(captionFonts) { font in
                                Text(font.displayName)
                                    .font(.custom(font.name, size: 14))
                                    .tag(font.name)
                            }
                        }
                    }

                    Section("Colors") {
                        ColorPickerRow(title: "Calendar Background", hex: hexBinding(settings, \.backgroundColorHex))
                        ColorPickerRow(title: "Caption Background", hex: hexBinding(settings, \.panelColorHex))
                        ColorPickerRow(title: "Text", hex: hexBinding(settings, \.textColorHex))
                        ColorPickerRow(title: "Today Highlight", hex: hexBinding(settings, \.highlightColorHex))
                        ColorPickerRow(title: "Weekday Labels", hex: hexBinding(settings, \.weekdayColorHex))
                        ColorPickerRow(title: "Future Days", hex: hexBinding(settings, \.futureDayColorHex))
                        if currentDisplayMode(settings) == .progressBar {
                            ColorPickerRow(title: "Completed Days", hex: hexBinding(settings, \.pastDayColorHex))
                        }
                    }

                    Section("Grid Options") {
                        Toggle("Show Only Current Month", isOn: boolBinding(settings, \.showOnlyCurrentMonth))
                        Toggle("Show Day Numbers", isOn: boolBinding(settings, \.showDayNumbers))
                        HStack {
                            Text("Cell Shape")
                            Slider(value: cgFloatBinding(settings, \.cellCornerRadius), in: 0.0...1.0)
                        }
                    }

                    Section("Layout") {
                        HStack {
                            Text("Calendar Size")
                            Slider(value: cgFloatBinding(settings, \.calendarScale), in: 0.15...0.6)
                        }
                        HStack {
                            Text("Horizontal Position")
                            Slider(value: cgFloatBinding(settings, \.calendarPositionX), in: 0.1...0.9)
                        }
                        HStack {
                            Text("Vertical Position")
                            Slider(value: cgFloatBinding(settings, \.calendarPositionY), in: 0.1...0.9)
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
                CalendarPreviewView(displayID: isPerDisplay ? selectedDisplayID : nil)
                    .padding(8)
                Button {
                    wallpaperManager.updateWallpaper()
                } label: {
                    Label("Apply to Desktop", systemImage: "desktopcomputer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(minWidth: 220)
        }
        .padding()
        .onChange(of: selectedDisplayID) { _, newValue in
            if newValue == "all" {
                profile = nil
            } else {
                profile = DisplayProfileStore.profile(for: newValue)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
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
                        let theme: CalendarTheme
                        if isPerDisplay, let profile {
                            let s = profile.toSettings()
                            theme = s.toTheme(name: newThemeName)
                        } else {
                            theme = wallpaperManager.settings.toTheme(name: newThemeName)
                        }
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

    // MARK: - Bindings that route to profile or global settings

    private func ensureProfile(_ settings: CalendarSettings) {
        if isPerDisplay && profile == nil {
            profile = DisplayProfile.from(settings: settings)
            saveProfile()
        }
    }

    private func saveProfile() {
        if isPerDisplay, let profile {
            DisplayProfileStore.setProfile(profile, for: selectedDisplayID)
        }
    }

    private func currentDisplayMode(_ settings: CalendarSettings) -> CalendarDisplayMode {
        if isPerDisplay, let profile {
            return CalendarDisplayMode(rawValue: profile.displayMode) ?? .currentMonth
        }
        return settings.displayMode
    }

    private func displayModeBinding(_ settings: CalendarSettings) -> Binding<CalendarDisplayMode> {
        Binding(
            get: { currentDisplayMode(settings) },
            set: { newValue in
                if isPerDisplay {
                    ensureProfile(settings)
                    profile?.displayMode = newValue.rawValue
                    saveProfile()
                } else {
                    settings.displayMode = newValue
                }
            }
        )
    }

    private func captionFontBinding(_ settings: CalendarSettings) -> Binding<String> {
        Binding(
            get: {
                if isPerDisplay, let profile { return profile.captionFontName }
                return settings.captionFontName
            },
            set: { newValue in
                if isPerDisplay {
                    ensureProfile(settings)
                    profile?.captionFontName = newValue
                    saveProfile()
                } else {
                    settings.captionFontName = newValue
                }
            }
        )
    }

    private func hexBinding(_ settings: CalendarSettings, _ keyPath: WritableKeyPath<CalendarSettings, String>) -> Binding<String> {
        let profileKeyPath = profileKeyPathForHex(keyPath)
        return Binding(
            get: {
                if isPerDisplay, let profile { return profile[keyPath: profileKeyPath] }
                return settings[keyPath: keyPath]
            },
            set: { newValue in
                if isPerDisplay {
                    ensureProfile(settings)
                    profile?[keyPath: profileKeyPath] = newValue
                    saveProfile()
                } else {
                    setSettingsString(settings, keyPath, newValue)
                }
            }
        )
    }

    private func boolBinding(_ settings: CalendarSettings, _ keyPath: WritableKeyPath<CalendarSettings, Bool>) -> Binding<Bool> {
        let profileKeyPath = profileKeyPathForBool(keyPath)
        return Binding(
            get: {
                if isPerDisplay, let profile { return profile[keyPath: profileKeyPath] }
                return settings[keyPath: keyPath]
            },
            set: { newValue in
                if isPerDisplay {
                    ensureProfile(settings)
                    profile?[keyPath: profileKeyPath] = newValue
                    saveProfile()
                } else {
                    setSettingsBool(settings, keyPath, newValue)
                }
            }
        )
    }

    private func cgFloatBinding(_ settings: CalendarSettings, _ keyPath: WritableKeyPath<CalendarSettings, CGFloat>) -> Binding<CGFloat> {
        let profileKeyPath = profileKeyPathForCGFloat(keyPath)
        return Binding(
            get: {
                if isPerDisplay, let profile { return profile[keyPath: profileKeyPath] }
                return settings[keyPath: keyPath]
            },
            set: { newValue in
                if isPerDisplay {
                    ensureProfile(settings)
                    profile?[keyPath: profileKeyPath] = newValue
                    saveProfile()
                } else {
                    setSettingsCGFloat(settings, keyPath, newValue)
                }
            }
        )
    }

    // Direct property setters to avoid subscript assignment issues with @Observable
    private func setSettingsString(_ s: CalendarSettings, _ kp: WritableKeyPath<CalendarSettings, String>, _ v: String) {
        switch kp {
        case \.backgroundColorHex: s.backgroundColorHex = v
        case \.textColorHex: s.textColorHex = v
        case \.highlightColorHex: s.highlightColorHex = v
        case \.weekdayColorHex: s.weekdayColorHex = v
        case \.pastDayColorHex: s.pastDayColorHex = v
        case \.futureDayColorHex: s.futureDayColorHex = v
        case \.panelColorHex: s.panelColorHex = v
        default: break
        }
    }

    private func setSettingsBool(_ s: CalendarSettings, _ kp: WritableKeyPath<CalendarSettings, Bool>, _ v: Bool) {
        switch kp {
        case \.showOnlyCurrentMonth: s.showOnlyCurrentMonth = v
        case \.showDayNumbers: s.showDayNumbers = v
        default: break
        }
    }

    private func setSettingsCGFloat(_ s: CalendarSettings, _ kp: WritableKeyPath<CalendarSettings, CGFloat>, _ v: CGFloat) {
        switch kp {
        case \.cellCornerRadius: s.cellCornerRadius = v
        case \.calendarScale: s.calendarScale = v
        case \.calendarPositionX: s.calendarPositionX = v
        case \.calendarPositionY: s.calendarPositionY = v
        default: break
        }
    }

    // MARK: - KeyPath mapping

    private func profileKeyPathForHex(_ kp: WritableKeyPath<CalendarSettings, String>) -> WritableKeyPath<DisplayProfile, String> {
        switch kp {
        case \.backgroundColorHex: return \.backgroundColorHex
        case \.textColorHex: return \.textColorHex
        case \.highlightColorHex: return \.highlightColorHex
        case \.weekdayColorHex: return \.weekdayColorHex
        case \.pastDayColorHex: return \.pastDayColorHex
        case \.futureDayColorHex: return \.futureDayColorHex
        case \.panelColorHex: return \.panelColorHex
        default: return \.backgroundColorHex
        }
    }

    private func profileKeyPathForBool(_ kp: WritableKeyPath<CalendarSettings, Bool>) -> WritableKeyPath<DisplayProfile, Bool> {
        switch kp {
        case \.showOnlyCurrentMonth: return \.showOnlyCurrentMonth
        case \.showDayNumbers: return \.showDayNumbers
        default: return \.showOnlyCurrentMonth
        }
    }

    private func profileKeyPathForCGFloat(_ kp: WritableKeyPath<CalendarSettings, CGFloat>) -> WritableKeyPath<DisplayProfile, CGFloat> {
        switch kp {
        case \.cellCornerRadius: return \.cellCornerRadius
        case \.calendarScale: return \.calendarScale
        case \.calendarPositionX: return \.calendarPositionX
        case \.calendarPositionY: return \.calendarPositionY
        default: return \.calendarScale
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
                HStack(spacing: 0) {
                    Color(nsColor: NSColor(hex: theme.panelColorHex))
                    Color(nsColor: NSColor(hex: theme.backgroundColorHex))
                }
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
