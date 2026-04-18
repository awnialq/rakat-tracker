//
//  PrayerModels.swift
//  Rakat Tracker Watch App — keep in sync with iOS Rakat Tracker/PrayerModels.swift
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Theme (greyish blue)

enum RakatTheme {
    static let backgroundTop = Color(red: 0.86, green: 0.90, blue: 0.95)
    static let backgroundBottom = Color(red: 0.78, green: 0.84, blue: 0.92)
    static let card = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let cardStroke = Color(red: 0.72, green: 0.80, blue: 0.90)
    static let accent = Color(red: 0.28, green: 0.45, blue: 0.62)
    static let accentSecondary = Color(red: 0.42, green: 0.58, blue: 0.76)
    static let sunnahTint = Color(red: 0.35, green: 0.55, blue: 0.68)
    static let fardTint = Color(red: 0.22, green: 0.42, blue: 0.58)
    static let textPrimary = Color(red: 0.15, green: 0.22, blue: 0.32)
    static let textSecondary = Color(red: 0.38, green: 0.46, blue: 0.56)
    static let complete = Color(red: 0.30, green: 0.62, blue: 0.55)
    static let sunnahGoldTop = Color(red: 1.0, green: 0.88, blue: 0.45)
    static let sunnahGoldMid = Color(red: 0.92, green: 0.72, blue: 0.22)
    static let sunnahGoldBottom = Color(red: 0.78, green: 0.55, blue: 0.12)
}

// MARK: - Prayer metadata (targets)

enum PrayerKind: String, CaseIterable, Identifiable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var sunnahBeforeTarget: Int {
        switch self {
        case .fajr: return 2
        case .dhuhr: return 4
        case .asr: return 4
        case .maghrib: return 0
        case .isha: return 4
        }
    }

    var fardTarget: Int {
        switch self {
        case .fajr: return 2
        case .dhuhr, .asr, .isha: return 4
        case .maghrib: return 3
        }
    }

    var sunnahAfterTarget: Int {
        switch self {
        case .fajr: return 0
        case .dhuhr: return 2
        case .asr: return 0
        case .maghrib: return 2
        case .isha: return 2
        }
    }

    var totalTargetRakats: Int {
        sunnahBeforeTarget + fardTarget + sunnahAfterTarget
    }

    var sunnahTargetTotal: Int {
        sunnahBeforeTarget + sunnahAfterTarget
    }

    func completedFardRakats(binding: PrayerProgressBinding) -> Int {
        min(binding.fard, fardTarget)
    }

    func completedSunnahRakats(binding: PrayerProgressBinding) -> Int {
        var n = 0
        if sunnahBeforeTarget > 0 { n += min(binding.sunnahBefore, sunnahBeforeTarget) }
        if sunnahAfterTarget > 0 { n += min(binding.sunnahAfter, sunnahAfterTarget) }
        return n
    }

    func isFardComplete(binding: PrayerProgressBinding) -> Bool {
        binding.fard >= fardTarget
    }

    func isSunnahComplete(binding: PrayerProgressBinding) -> Bool {
        guard sunnahTargetTotal > 0 else { return false }
        let beforeOK = sunnahBeforeTarget == 0 || binding.sunnahBefore >= sunnahBeforeTarget
        let afterOK = sunnahAfterTarget == 0 || binding.sunnahAfter >= sunnahAfterTarget
        return beforeOK && afterOK
    }

    var symbolName: String {
        switch self {
        case .fajr: return "sun.horizon.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "moon.stars.fill"
        case .isha: return "moon.fill"
        }
    }

    var cardAccent: Color {
        switch self {
        case .fajr: return Color(red: 0.45, green: 0.62, blue: 0.82)
        case .dhuhr: return Color(red: 0.38, green: 0.55, blue: 0.75)
        case .asr: return Color(red: 0.32, green: 0.50, blue: 0.68)
        case .maghrib: return Color(red: 0.40, green: 0.48, blue: 0.72)
        case .isha: return Color(red: 0.35, green: 0.42, blue: 0.65)
        }
    }

    func completedRakats(binding: PrayerProgressBinding) -> Int {
        var n = 0
        if sunnahBeforeTarget > 0 { n += min(binding.sunnahBefore, sunnahBeforeTarget) }
        n += min(binding.fard, fardTarget)
        if sunnahAfterTarget > 0 { n += min(binding.sunnahAfter, sunnahAfterTarget) }
        return n
    }

    func isComplete(binding: PrayerProgressBinding) -> Bool {
        completedRakats(binding: binding) >= totalTargetRakats
    }
}

// MARK: - Persisted daily state

@Model
final class RakatTrackerState {
    var dayStart: Date

    var fajrSunnahBefore: Int
    var fajrFard: Int

    var dhuhrSunnahBefore: Int
    var dhuhrFard: Int
    var dhuhrSunnahAfter: Int

    var asrSunnahBefore: Int
    var asrFard: Int

    var maghribFard: Int
    var maghribSunnahAfter: Int

    var ishaSunnahBefore: Int
    var ishaFard: Int
    var ishaSunnahAfter: Int

    init(dayStart: Date) {
        self.dayStart = dayStart
        self.fajrSunnahBefore = 0
        self.fajrFard = 0
        self.dhuhrSunnahBefore = 0
        self.dhuhrFard = 0
        self.dhuhrSunnahAfter = 0
        self.asrSunnahBefore = 0
        self.asrFard = 0
        self.maghribFard = 0
        self.maghribSunnahAfter = 0
        self.ishaSunnahBefore = 0
        self.ishaFard = 0
        self.ishaSunnahAfter = 0
    }

    func reset(to newDayStart: Date) {
        dayStart = newDayStart
        fajrSunnahBefore = 0
        fajrFard = 0
        dhuhrSunnahBefore = 0
        dhuhrFard = 0
        dhuhrSunnahAfter = 0
        asrSunnahBefore = 0
        asrFard = 0
        maghribFard = 0
        maghribSunnahAfter = 0
        ishaSunnahBefore = 0
        ishaFard = 0
        ishaSunnahAfter = 0
    }

    func binding(for prayer: PrayerKind) -> PrayerProgressBinding {
        PrayerProgressBinding(prayer: prayer, state: self)
    }
}

struct PrayerProgressBinding {
    let prayer: PrayerKind
    private let state: RakatTrackerState

    init(prayer: PrayerKind, state: RakatTrackerState) {
        self.prayer = prayer
        self.state = state
    }

    var sunnahBefore: Int {
        get {
            switch prayer {
            case .fajr: return state.fajrSunnahBefore
            case .dhuhr: return state.dhuhrSunnahBefore
            case .asr: return state.asrSunnahBefore
            case .maghrib: return 0
            case .isha: return state.ishaSunnahBefore
            }
        }
        nonmutating set {
            switch prayer {
            case .fajr: state.fajrSunnahBefore = newValue
            case .dhuhr: state.dhuhrSunnahBefore = newValue
            case .asr: state.asrSunnahBefore = newValue
            case .maghrib: break
            case .isha: state.ishaSunnahBefore = newValue
            }
        }
    }

    var fard: Int {
        get {
            switch prayer {
            case .fajr: return state.fajrFard
            case .dhuhr: return state.dhuhrFard
            case .asr: return state.asrFard
            case .maghrib: return state.maghribFard
            case .isha: return state.ishaFard
            }
        }
        nonmutating set {
            switch prayer {
            case .fajr: state.fajrFard = newValue
            case .dhuhr: state.dhuhrFard = newValue
            case .asr: state.asrFard = newValue
            case .maghrib: state.maghribFard = newValue
            case .isha: state.ishaFard = newValue
            }
        }
    }

    var sunnahAfter: Int {
        get {
            switch prayer {
            case .fajr: return 0
            case .dhuhr: return state.dhuhrSunnahAfter
            case .asr: return 0
            case .maghrib: return state.maghribSunnahAfter
            case .isha: return state.ishaSunnahAfter
            }
        }
        nonmutating set {
            switch prayer {
            case .fajr, .asr: break
            case .dhuhr: state.dhuhrSunnahAfter = newValue
            case .maghrib: state.maghribSunnahAfter = newValue
            case .isha: state.ishaSunnahAfter = newValue
            }
        }
    }
}

enum DayBoundary {
    static func startOfToday() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    static func isSameCalendarDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }
}

enum RakatDaySync {
    @MainActor
    static func sync(modelContext: ModelContext, states: [RakatTrackerState]) {
        let today = DayBoundary.startOfToday()

        let matchingToday = states.filter { DayBoundary.isSameCalendarDay($0.dayStart, today) }
        if let keep = matchingToday.first {
            for extra in states where extra.persistentModelID != keep.persistentModelID {
                modelContext.delete(extra)
            }
            return
        }

        if let reuse = states.first {
            reuse.reset(to: today)
            for extra in states.dropFirst() {
                modelContext.delete(extra)
            }
            return
        }

        modelContext.insert(RakatTrackerState(dayStart: today))
    }
}
