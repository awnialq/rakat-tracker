//
//  WatchRootView.swift
//  Rakat Tracker Watch App
//

import SwiftUI
import SwiftData
#if os(watchOS)
import WatchKit
#endif

struct WatchRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var states: [RakatTrackerState]

    var body: some View {
        Group {
            if let state = todayState {
                NavigationStack {
                    watchPrayerHome(state: state)
                }
            } else {
                loadingWatch
            }
        }
        .onAppear { RakatDaySync.sync(modelContext: modelContext, states: states) }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                RakatDaySync.sync(modelContext: modelContext, states: states)
            }
        }
    }

    private var todayState: RakatTrackerState? {
        let today = DayBoundary.startOfToday()
        return states.first { DayBoundary.isSameCalendarDay($0.dayStart, today) }
    }

    private var loadingWatch: some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ProgressView()
                .tint(RakatTheme.accent)
        }
    }

    private func watchPrayerHome(state: RakatTrackerState) -> some View {
        GeometryReader { geo in
            let scale = WatchMetrics.scale(forWidth: geo.size.width)

            ZStack {
                LinearGradient(
                    colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 10 * scale) {
                        Text(daySubtitle(for: state.dayStart))
                            .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                            .foregroundStyle(RakatTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(PrayerKind.allCases) { prayer in
                            NavigationLink(value: prayer) {
                                WatchPrayerListCard(
                                    prayer: prayer,
                                    binding: state.binding(for: prayer),
                                    scale: scale
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6 * scale)
                    .padding(.vertical, 4 * scale)
                }
            }
        }
        .navigationTitle("Rakat")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PrayerKind.self) { prayer in
            WatchPrayerDetailView(
                prayer: prayer,
                binding: state.binding(for: prayer)
            )
        }
    }

    private func daySubtitle(for dayStart: Date) -> String {
        let formatted = dayStart.formatted(date: .abbreviated, time: .omitted)
        return "Today · \(formatted) · resets daily"
    }
}

// MARK: - Watch scaling (38mm → Ultra)

enum WatchMetrics {
    /// Baseline: ~184pt small watch width. Clamped so buttons stay tappable on all cases.
    static func scale(forWidth width: CGFloat) -> CGFloat {
        let raw = width / 184
        return min(max(raw, 0.85), 1.35)
    }
}

// MARK: - Gold sunnah seal (compact, matches iOS intent)

private struct GoldSunnahSeal: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            RakatTheme.sunnahGoldTop,
                            RakatTheme.sunnahGoldMid,
                            RakatTheme.sunnahGoldBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18 * scale, height: 18 * scale)
                .shadow(color: RakatTheme.sunnahGoldMid.opacity(0.45), radius: 2 * scale, y: 1 * scale)

            Image(systemName: "checkmark")
                .font(.system(size: 9 * scale, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Sunnah complete")
    }
}

// MARK: - List card

private struct WatchPrayerListCard: View {
    let prayer: PrayerKind
    let binding: PrayerProgressBinding
    let scale: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 8 * scale) {
            ZStack {
                RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [prayer.cardAccent.opacity(0.55), prayer.cardAccent.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32 * scale, height: 32 * scale)

                Image(systemName: prayer.symbolName)
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(prayer.cardAccent)
            }

            VStack(alignment: .leading, spacing: 3 * scale) {
                Text(prayer.localizedTitle)
                    .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(RakatTheme.textPrimary)

                Text(fardProgressLine)
                    .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(RakatTheme.textSecondary)

                if let sunnah = sunnahProgressLine {
                    Text(sunnah)
                        .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                        .foregroundStyle(RakatTheme.textSecondary)
                }
            }

            Spacer(minLength: 2 * scale)

            HStack(spacing: 5 * scale) {
                if prayer.isFardComplete(binding: binding) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16 * scale))
                        .foregroundStyle(RakatTheme.complete)
                        .accessibilityLabel("Fard complete")
                }
                if prayer.sunnahTargetTotal > 0, prayer.isSunnahComplete(binding: binding) {
                    GoldSunnahSeal(scale: scale)
                }
                if !prayer.isComplete(binding: binding) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11 * scale, weight: .semibold))
                        .foregroundStyle(RakatTheme.accentSecondary.opacity(0.9))
                }
            }
        }
        .padding(10 * scale)
        .background(
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(RakatTheme.card)
                .shadow(color: RakatTheme.accent.opacity(0.12), radius: 4 * scale, y: 2 * scale)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .stroke(RakatTheme.cardStroke, lineWidth: 1)
        )
    }

    private var fardProgressLine: String {
        let c = prayer.completedFardRakats(binding: binding)
        return "Fard · \(c)/\(prayer.fardTarget)"
    }

    private var sunnahProgressLine: String? {
        guard prayer.sunnahTargetTotal > 0 else { return nil }
        let c = prayer.completedSunnahRakats(binding: binding)
        return "Sunnah · \(c)/\(prayer.sunnahTargetTotal)"
    }
}

// MARK: - Detail

struct WatchPrayerDetailView: View {
    let prayer: PrayerKind
    let binding: PrayerProgressBinding

    var body: some View {
        GeometryReader { geo in
            let scale = WatchMetrics.scale(forWidth: geo.size.width)
            let buttonSize = max(36, min(geo.size.width * 0.34, 58))

            ZStack {
                LinearGradient(
                    colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14 * scale) {
                        summaryHeader(scale: scale, width: geo.size.width)

                        VStack(spacing: 12 * scale) {
                            if prayer.sunnahBeforeTarget > 0 {
                                WatchLargeRakatBlock(
                                    title: "Sunnah (before)",
                                    subtitle: "Before fard",
                                    tint: RakatTheme.sunnahTint,
                                    value: binding.sunnahBefore,
                                    target: prayer.sunnahBeforeTarget,
                                    scale: scale,
                                    buttonSize: buttonSize
                                ) { binding.sunnahBefore = $0 }
                            }

                            WatchLargeRakatBlock(
                                title: "Fard",
                                subtitle: "Obligatory",
                                tint: RakatTheme.fardTint,
                                value: binding.fard,
                                target: prayer.fardTarget,
                                scale: scale,
                                buttonSize: buttonSize
                            ) { binding.fard = $0 }

                            if prayer.sunnahAfterTarget > 0 {
                                WatchLargeRakatBlock(
                                    title: "Sunnah (after)",
                                    subtitle: "After fard",
                                    tint: RakatTheme.sunnahTint,
                                    value: binding.sunnahAfter,
                                    target: prayer.sunnahAfterTarget,
                                    scale: scale,
                                    buttonSize: buttonSize
                                ) { binding.sunnahAfter = $0 }
                            }
                        }
                    }
                    .padding(.horizontal, 4 * scale)
                    .padding(.bottom, 12 * scale)
                }
            }
        }
        .navigationTitle(prayer.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryHeader(scale: CGFloat, width: CGFloat) -> some View {
        let countSize = max(22, min(width * 0.12, 30))
        let fardDone = prayer.completedFardRakats(binding: binding)
        let sunDone = prayer.completedSunnahRakats(binding: binding)

        return VStack(spacing: 6 * scale) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [prayer.cardAccent.opacity(0.45), prayer.cardAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44 * scale, height: 44 * scale)

                Image(systemName: prayer.symbolName)
                    .font(.system(size: 20 * scale))
                    .foregroundStyle(prayer.cardAccent)
            }

            Text("\(prayer.completedRakats(binding: binding)) / \(prayer.totalTargetRakats) rakat")
                .font(.system(size: countSize, weight: .semibold, design: .rounded))
                .foregroundStyle(RakatTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            VStack(spacing: 4 * scale) {
                HStack(spacing: 6 * scale) {
                    Text("Fard · \(fardDone)/\(prayer.fardTarget)")
                        .font(.system(size: 12 * scale, weight: .medium, design: .rounded))
                        .foregroundStyle(RakatTheme.textSecondary)
                    if prayer.isFardComplete(binding: binding) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14 * scale))
                            .foregroundStyle(RakatTheme.complete)
                    }
                }
                if prayer.sunnahTargetTotal > 0 {
                    HStack(spacing: 6 * scale) {
                        Text("Sunnah · \(sunDone)/\(prayer.sunnahTargetTotal)")
                            .font(.system(size: 12 * scale, weight: .medium, design: .rounded))
                            .foregroundStyle(RakatTheme.textSecondary)
                        if prayer.isSunnahComplete(binding: binding) {
                            GoldSunnahSeal(scale: scale * 0.9)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6 * scale)
    }
}

private struct WatchLargeRakatBlock: View {
    let title: String
    let subtitle: String
    let tint: Color
    let value: Int
    let target: Int
    let scale: CGFloat
    let buttonSize: CGFloat
    let setValue: (Int) -> Void

    private var clamped: Int {
        min(max(0, value), target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * scale) {
            VStack(alignment: .leading, spacing: 2 * scale) {
                Text(title)
                    .font(.system(size: 14 * scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(RakatTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(RakatTheme.textSecondary)
            }

            HStack(spacing: 10 * scale) {
                tapChip(systemImage: "minus", scale: scale) {
                    guard clamped > 0 else { return }
                    setValue(clamped - 1)
                    watchHaptic()
                }
                .disabled(clamped <= 0)
                .opacity(clamped <= 0 ? 0.45 : 1)

                VStack(spacing: 2 * scale) {
                    Text("\(clamped)")
                        .font(.system(size: max(28, buttonSize * 0.72), weight: .bold, design: .rounded))
                        .foregroundStyle(RakatTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text("of \(target)")
                        .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                        .foregroundStyle(RakatTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                tapChip(systemImage: "plus", scale: scale) {
                    guard clamped < target else { return }
                    setValue(clamped + 1)
                    watchHaptic()
                }
                .disabled(clamped >= target)
                .opacity(clamped >= target ? 0.45 : 1)
            }
            .padding(.vertical, 4 * scale)
        }
        .padding(12 * scale)
        .background(
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(RakatTheme.card)
                .shadow(color: tint.opacity(0.18), radius: 6 * scale, y: 3 * scale)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1.2)
        )
    }

    private func tapChip(systemImage: String, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22 * scale, weight: .bold))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.35), radius: 4 * scale, y: 2 * scale)
        }
        .buttonStyle(.plain)
    }
}

private func watchHaptic() {
#if os(watchOS)
    WKInterfaceDevice.current().play(.click)
#endif
}

// MARK: - Previews (Editor → Canvas, or ⌥⌘↩ — pick an Apple Watch device in the canvas bar)

#Preview("Watch — list") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RakatTrackerState.self, configurations: config)
    let state = RakatTrackerState(dayStart: .now)
    state.dhuhrFard = 2
    state.dhuhrSunnahBefore = 2
    container.mainContext.insert(state)
    return WatchRootView()
        .modelContainer(container)
}

#Preview("Watch — detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RakatTrackerState.self, configurations: config)
    let state = RakatTrackerState(dayStart: .now)
    container.mainContext.insert(state)
    return NavigationStack {
        WatchPrayerDetailView(prayer: .dhuhr, binding: state.binding(for: .dhuhr))
    }
    .modelContainer(container)
}
