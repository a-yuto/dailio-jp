import Testing
import Foundation
import SwiftData
@testable import dailio_jp

@MainActor
struct MoodRepositoryTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([MoodEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func upsertCreatesEntryWhenNoneExists() throws {
        let context = try makeContext()
        let repository = MoodRepository(context: context)

        try repository.upsert(on: .now, mood: 7, sleepHours: 7.5, sleepSource: .manual)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<MoodEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.mood == 7)
    }

    @Test func upsertUpdatesExistingEntryOnSameLogicalDay() throws {
        let context = try makeContext()
        let repository = MoodRepository(context: context)

        let calendar = Calendar.current
        let baseDay = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 9))!
        let laterSameDay = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 22))!

        try repository.upsert(on: baseDay, mood: 4, sleepHours: 6, sleepSource: .manual)
        try repository.upsert(on: laterSameDay, mood: 8, sleepHours: 7, sleepSource: .healthKit)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<MoodEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.mood == 8)
        #expect(entries.first?.sleepSource == .healthKit)
    }

    @Test func upsertCreatesSeparateEntriesForDifferentDays() throws {
        let context = try makeContext()
        let repository = MoodRepository(context: context)

        let calendar = Calendar.current
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5))!
        let day2 = calendar.date(from: DateComponents(year: 2026, month: 5, day: 6))!

        try repository.upsert(on: day1, mood: 5, sleepHours: 7, sleepSource: .manual)
        try repository.upsert(on: day2, mood: 6, sleepHours: 8, sleepSource: .manual)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<MoodEntry>())
        #expect(entries.count == 2)
    }
}

@MainActor
struct StreakCalculatorTests {

    private func entries(daysAgo: [Int], reference: Date, calendar: Calendar = .current) -> [MoodEntry] {
        daysAgo.map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: reference)!
            return MoodEntry(date: date, mood: 5)
        }
    }

    @Test func returnsZeroForEmpty() {
        let calculator = StreakCalculator()
        #expect(calculator.currentStreak(entries: [], reference: .now) == 0)
    }

    @Test func countsConsecutiveDaysIncludingToday() {
        let reference = Date()
        let calculator = StreakCalculator()
        let result = calculator.currentStreak(entries: entries(daysAgo: [0, 1, 2], reference: reference), reference: reference)
        #expect(result == 3)
    }

    @Test func allowsTodayMissingButCountsYesterdayBack() {
        let reference = Date()
        let calculator = StreakCalculator()
        let result = calculator.currentStreak(entries: entries(daysAgo: [1, 2, 3], reference: reference), reference: reference)
        #expect(result == 3)
    }

    @Test func breaksOnGap() {
        let reference = Date()
        let calculator = StreakCalculator()
        let result = calculator.currentStreak(entries: entries(daysAgo: [0, 1, 3, 4], reference: reference), reference: reference)
        #expect(result == 2)
    }
}
