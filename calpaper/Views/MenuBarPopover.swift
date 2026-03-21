import SwiftUI

struct MenuBarPopover: View {
    @Environment(WallpaperManager.self) private var wallpaperManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 12) {
            CalendarPreviewView()
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if let lastUpdated = wallpaperManager.lastUpdated {
                Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("Set Wallpaper") {
                    wallpaperManager.updateWallpaper()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
