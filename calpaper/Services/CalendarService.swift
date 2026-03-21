import EventKit
import AppKit

@Observable
final class CalendarService {
    private let store = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var availableCalendars: [EKCalendar] = []

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                loadCalendars()
            }
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    func refreshStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func loadCalendars() {
        availableCalendars = store.calendars(for: .event)
    }

    func fetchEvents(for month: CalendarMonth, calendarIDs: Set<String>) -> [Date: [CalendarEvent]] {
        guard authorizationStatus == .fullAccess else { return [:] }

        let calendar = Calendar.current
        let startComponents = DateComponents(year: month.year, month: month.month, day: 1)
        guard let startDate = calendar.date(from: startComponents) else { return [:] }
        guard let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { return [:] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        var eventsByDate: [Date: [CalendarEvent]] = [:]

        for ekEvent in ekEvents {
            if !calendarIDs.isEmpty && !calendarIDs.contains(ekEvent.calendar.calendarIdentifier) {
                continue
            }

            let dayStart = calendar.startOfDay(for: ekEvent.startDate)
            let color = ekEvent.calendar.cgColor.flatMap { NSColor(cgColor: $0)?.hexString } ?? "#FFFFFF"
            let event = CalendarEvent(
                id: ekEvent.eventIdentifier,
                title: ekEvent.title ?? "",
                color: color
            )
            eventsByDate[dayStart, default: []].append(event)
        }

        return eventsByDate
    }
}
