import AppKit

@Observable
final class SchedulerService {
    private var midnightTimer: Timer?
    var onUpdate: (() -> Void)?

    func start() {
        scheduleMidnightTimer()

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleWake()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onUpdate?()
        }
    }

    func stop() {
        midnightTimer?.invalidate()
        midnightTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else { return }
        let interval = tomorrow.timeIntervalSinceNow + 1 // 1 second after midnight

        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.onUpdate?()
            self?.scheduleMidnightTimer()
        }
    }

    private var lastUpdateDate: Date?

    private func handleWake() {
        let today = Calendar.current.startOfDay(for: Date())
        if lastUpdateDate != today {
            lastUpdateDate = today
            onUpdate?()
        }
    }
}
