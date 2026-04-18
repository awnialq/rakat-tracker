//
//  ContentView.swift
//  Rakat Tracker
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var states: [RakatTrackerState]

#if os(macOS)
    @State private var selectedPrayer: PrayerKind?
#endif

    var body: some View {
        Group {
            if let state = todayState {
#if os(macOS)
                NavigationSplitView {
                    prayerSidebar(state: state)
                } detail: {
                    if let prayer = selectedPrayer {
                        PrayerDetailView(prayer: prayer, binding: state.binding(for: prayer))
                            .id(prayer.id)
                    } else {
                        placeholderDetail
                    }
                }
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
#else
                NavigationStack {
                    prayerHome(state: state)
                }
#endif
            } else {
                loadingView
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

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ContentUnavailableView(
                "Loading",
                systemImage: "moon.stars",
                description: Text("Preparing today’s tracker.")
            )
        }
    }

#if os(iOS)
    private func prayerHome(state: RakatTrackerState) -> some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(state: state)

                    VStack(spacing: 14) {
                        ForEach(PrayerKind.allCases) { prayer in
                            NavigationLink(value: prayer) {
                                PrayerListCard(prayer: prayer, binding: state.binding(for: prayer))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Rakat Tracker")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: PrayerKind.self) { prayer in
            PrayerDetailView(prayer: prayer, binding: state.binding(for: prayer))
        }
    }
#endif

#if os(macOS)
    private func prayerSidebar(state: RakatTrackerState) -> some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(state: state)

                    VStack(spacing: 12) {
                        ForEach(PrayerKind.allCases) { prayer in
                            Button {
                                selectedPrayer = prayer
                            } label: {
                                PrayerListCard(prayer: prayer, binding: state.binding(for: prayer))
                            }
                            .buttonStyle(.plain)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        selectedPrayer == prayer ? RakatTheme.accent : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Rakat Tracker")
        .onAppear {
            if selectedPrayer == nil {
                selectedPrayer = .fajr
            }
        }
    }

    private var placeholderDetail: some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            Text("Select a prayer")
                .font(.title3)
                .foregroundStyle(RakatTheme.textSecondary)
        }
    }
#endif

    private func header(state: RakatTrackerState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(daySubtitle(for: state.dayStart))
                .font(.subheadline)
                .foregroundStyle(RakatTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func daySubtitle(for dayStart: Date) -> String {
        let formatted = dayStart.formatted(date: .abbreviated, time: .omitted)
        return "Today · \(formatted) — counts reset at the start of each new day."
    }

}

// MARK: - Prayer list card

private struct PrayerListCard: View {
    let prayer: PrayerKind
    let binding: PrayerProgressBinding

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [prayer.cardAccent.opacity(0.55), prayer.cardAccent.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: prayer.symbolName)
                    .font(.title2)
                    .foregroundStyle(prayer.cardAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(prayer.localizedTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RakatTheme.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        "Fard · \(prayer.completedFardRakats(binding: binding))/\(prayer.fardTarget)"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RakatTheme.textSecondary)

                    if prayer.sunnahTargetTotal > 0 {
                        Text(
                            "Sunnah · \(prayer.completedSunnahRakats(binding: binding))/\(prayer.sunnahTargetTotal)"
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RakatTheme.textSecondary)
                    }
                }
            }

            Spacer(minLength: 8)

            completionTrailing
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RakatTheme.card)
                .shadow(color: RakatTheme.accent.opacity(0.12), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RakatTheme.cardStroke, lineWidth: 1)
        )
    }

    /// Green when fard is done; gold seal when sunnah is done; chevron when something remains.
    @ViewBuilder
    private var completionTrailing: some View {
        let fardDone = prayer.isFardComplete(binding: binding)
        let sunnahDone = prayer.isSunnahComplete(binding: binding)
        let fullyDone = fardDone && (prayer.sunnahTargetTotal == 0 || sunnahDone)

        HStack(spacing: 6) {
            if fardDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RakatTheme.complete)
            }
            if sunnahDone, prayer.sunnahTargetTotal > 0 {
                GoldSunnahCheckmark()
            }
            if !fullyDone {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RakatTheme.accentSecondary.opacity(0.85))
            }
        }
    }
}

// MARK: - Gold sunnah completion badge

private struct GoldSunnahCheckmark: View {
    var font: Font = .title2

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        RakatTheme.sunnahGoldTop,
                        RakatTheme.sunnahGoldMid,
                        RakatTheme.sunnahGoldBottom,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: RakatTheme.sunnahGoldTop.opacity(0.85), radius: 4, y: 1)
            .shadow(color: Color.white.opacity(0.45), radius: 0, y: -1)
    }
}

// MARK: - Detail (large controls)

struct PrayerDetailView: View {
    let prayer: PrayerKind
    let binding: PrayerProgressBinding

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [RakatTheme.backgroundTop, RakatTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    summaryHeader

                    VStack(spacing: 18) {
                        if prayer.sunnahBeforeTarget > 0 {
                            LargeRakatBlock(
                                title: "Sunnah (before)",
                                subtitle: "Emphasized sunnah before fard",
                                tint: RakatTheme.sunnahTint,
                                value: binding.sunnahBefore,
                                target: prayer.sunnahBeforeTarget
                            ) { binding.sunnahBefore = $0 }
                        }

                        LargeRakatBlock(
                            title: "Fard",
                            subtitle: "Obligatory prayer",
                            tint: RakatTheme.fardTint,
                            value: binding.fard,
                            target: prayer.fardTarget
                        ) { binding.fard = $0 }

                        if prayer.sunnahAfterTarget > 0 {
                            LargeRakatBlock(
                                title: "Sunnah (after)",
                                subtitle: "Emphasized sunnah after fard",
                                tint: RakatTheme.sunnahTint,
                                value: binding.sunnahAfter,
                                target: prayer.sunnahAfterTarget
                            ) { binding.sunnahAfter = $0 }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(prayer.localizedTitle)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var summaryHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [prayer.cardAccent.opacity(0.45), prayer.cardAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: prayer.symbolName)
                    .font(.system(size: 32))
                    .foregroundStyle(prayer.cardAccent)
            }

            VStack(spacing: 6) {
                Text("Fard · \(prayer.completedFardRakats(binding: binding))/\(prayer.fardTarget)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RakatTheme.textPrimary)
                if prayer.sunnahTargetTotal > 0 {
                    Text("Sunnah · \(prayer.completedSunnahRakats(binding: binding))/\(prayer.sunnahTargetTotal)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RakatTheme.textPrimary)
                }
            }

            HStack(spacing: 14) {
                if prayer.isFardComplete(binding: binding) {
                    Label("Fard complete", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RakatTheme.complete)
                }
                if prayer.isSunnahComplete(binding: binding), prayer.sunnahTargetTotal > 0 {
                    HStack(spacing: 6) {
                        GoldSunnahCheckmark(font: .body)
                        Text("Sunnah complete")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RakatTheme.textPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Large + / −

private struct LargeRakatBlock: View {
    let title: String
    let subtitle: String
    let tint: Color
    let value: Int
    let target: Int
    let setValue: (Int) -> Void

    private var clamped: Int {
        min(max(0, value), target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RakatTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RakatTheme.textSecondary)
            }

            HStack(spacing: 16) {
                tapChip(systemImage: "minus") {
                    guard clamped > 0 else { return }
                    setValue(clamped - 1)
                    RakatHaptics.lightTap()
                }
                .disabled(clamped <= 0)
                .opacity(clamped <= 0 ? 0.45 : 1)

                VStack(spacing: 4) {
                    Text("\(clamped)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(RakatTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text("of \(target)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RakatTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                tapChip(systemImage: "plus") {
                    guard clamped < target else { return }
                    setValue(clamped + 1)
                    RakatHaptics.lightTap()
                }
                .disabled(clamped >= target)
                .opacity(clamped >= target ? 0.45 : 1)
            }
            .padding(.vertical, 8)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RakatTheme.card)
                .shadow(color: tint.opacity(0.18), radius: 12, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1.5)
        )
    }

    private func tapChip(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 72, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.35), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private enum RakatHaptics {
    static func lightTap() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }
}

#Preview("List") {
    ContentView()
        .modelContainer(for: RakatTrackerState.self, inMemory: true)
}

#Preview("Detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RakatTrackerState.self, configurations: config)
    let state = RakatTrackerState(dayStart: .now)
    container.mainContext.insert(state)
    return NavigationStack {
        PrayerDetailView(prayer: .dhuhr, binding: state.binding(for: .dhuhr))
    }
    .modelContainer(container)
}
