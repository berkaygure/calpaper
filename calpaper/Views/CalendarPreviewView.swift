import SwiftUI

struct CalendarPreviewView: View {
    @Environment(WallpaperManager.self) private var wallpaperManager

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let nsSize = NSSize(width: size.width * 2, height: size.height * 2)
            let image = wallpaperManager.generatePreview(size: nsSize)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
