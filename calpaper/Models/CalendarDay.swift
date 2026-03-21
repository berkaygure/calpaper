import Foundation

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let isPast: Bool
    var events: [CalendarEvent]

    static func empty() -> CalendarDay {
        CalendarDay(date: nil, dayNumber: 0, isToday: false, isCurrentMonth: false, isPast: false, events: [])
    }
}

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let color: String // hex color
}
