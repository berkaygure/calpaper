import Foundation

struct CalendarMonth {
    let year: Int
    let month: Int
    let monthName: String
    let weekdayHeaders: [String]
    var weeks: [[CalendarDay]] // 6 rows x 7 columns

    static func build(for date: Date = Date(), calendar: Calendar = .current) -> CalendarMonth {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year!
        let month = components.month!

        let monthName = calendar.monthSymbols[month - 1]

        let weekdayHeaders: [String] = {
            let symbols = calendar.shortWeekdaySymbols
            let firstWeekday = calendar.firstWeekday - 1
            return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
        }()

        let firstOfMonth = calendar.date(from: components)!
        let rangeOfDays = calendar.range(of: .day, in: .month, for: firstOfMonth)!

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7

        let today = calendar.startOfDay(for: date)

        // Build previous month days
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth)!
        let previousMonthLastDay = previousMonthRange.upperBound - 1

        var allDays: [CalendarDay] = []

        // Leading days from previous month
        for i in 0..<offset {
            let dayNum = previousMonthLastDay - offset + 1 + i
            let dayDate = calendar.date(byAdding: .day, value: -(offset - i), to: firstOfMonth)
            let isPast = dayDate.map { calendar.startOfDay(for: $0) < today } ?? false
            allDays.append(CalendarDay(
                date: dayDate,
                dayNumber: dayNum,
                isToday: false,
                isCurrentMonth: false,
                isPast: isPast,
                events: []
            ))
        }

        // Current month days
        for day in rangeOfDays {
            let dayDate = calendar.date(bySetting: .day, value: day, of: firstOfMonth)!
            let isToday = calendar.isDate(dayDate, inSameDayAs: today)
            let isPast = !isToday && calendar.startOfDay(for: dayDate) < today
            allDays.append(CalendarDay(
                date: dayDate,
                dayNumber: day,
                isToday: isToday,
                isCurrentMonth: true,
                isPast: isPast,
                events: []
            ))
        }

        // Trailing days from next month
        let remaining = 42 - allDays.count
        for i in 1...max(remaining, 1) {
            if allDays.count >= 42 { break }
            let dayDate = calendar.date(byAdding: .day, value: i, to: calendar.date(bySetting: .day, value: rangeOfDays.upperBound - 1, of: firstOfMonth)!)
            allDays.append(CalendarDay(
                date: dayDate,
                dayNumber: i,
                isToday: false,
                isCurrentMonth: false,
                isPast: false,
                events: []
            ))
        }

        // Split into 6 weeks
        var weeks: [[CalendarDay]] = []
        for weekIndex in 0..<6 {
            let start = weekIndex * 7
            let end = min(start + 7, allDays.count)
            if start < allDays.count {
                weeks.append(Array(allDays[start..<end]))
            }
        }

        return CalendarMonth(
            year: year,
            month: month,
            monthName: monthName,
            weekdayHeaders: weekdayHeaders,
            weeks: weeks
        )
    }
}
