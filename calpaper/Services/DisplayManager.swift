import AppKit

extension NSScreen {
    var displayID: String {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        let id = deviceDescription[key] as? CGDirectDisplayID ?? 0
        return "\(id)"
    }

    var displayName: String {
        localizedName
    }
}

struct DisplayManager {
    func setWallpaper(imageURL: URL, for screen: NSScreen) throws {
        try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true
        ])
    }

    func setWallpaperForAllScreens(imageURLs: [NSScreen: URL]) throws {
        for (screen, url) in imageURLs {
            try setWallpaper(imageURL: url, for: screen)
        }
    }

    var screens: [NSScreen] {
        NSScreen.screens
    }
}
