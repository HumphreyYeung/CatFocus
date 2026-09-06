import SwiftUI

struct StatsView: View {
    var cat: CatProfile = .default
    var records: [TrainingSessionRecord] = []
    var onShare: () -> Void = {}
    var onTabSelected: (CFAppTab) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.top, CFTabScreenLayout.headerTopPadding)
                .padding(.bottom, CFTabScreenLayout.headerBottomPadding)
                .cfEntrance(offset: -4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: CFSpacing.xxl) {
                    metricGrid.cfEntrance(delay: 0.08)
                    weeklySection.cfEntrance(delay: 0.16)
                    recentSection.cfEntrance(delay: 0.24)
                }
                .padding(.horizontal, CFTabScreenLayout.horizontalPadding)
                .padding(.bottom, CFTabScreenLayout.scrollBottomPadding)
            }

        }
        .background(CFColor.backgroundPrimary)
    }

    private var header: some View {
        HStack {
            Text("Stats")
                .font(CFFont.screenTitle)
                .foregroundStyle(CFColor.textPrimary)

            Spacer()

            CFIconCircleButton(icon: .share, label: "Share", action: onShare)
        }
    }

    private var metricGrid: some View {
        HStack(spacing: CFSpacing.lg) {
            CFMetricCard(label: "Focus Time", value: focusTimeText, footnote: "\(completedSessionCount) sessions", tone: .success)
            CFMetricCard(label: "Fitness", value: "\(fitnessScore.value)%", status: fitnessScore.healthStatus.displayLabel, tone: .health)
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            Text("Weekly Activity")
                .font(CFFont.cardTitle)
                .foregroundStyle(CFColor.textPrimary)

            CFWeeklyActivityChart(days: weeklyActivity)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: CFSpacing.lg) {
            Text("Recent Sessions")
                .font(CFFont.cardTitle)
                .foregroundStyle(CFColor.textPrimary)

            if recentSessions.isEmpty {
                Text("Complete your first focus session to see it here.")
                    .font(CFFont.bodySmall)
                    .foregroundStyle(CFColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(CFColor.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
                    .cfShadow(CFCloudLayer.cardShadow)
            } else {
                VStack(spacing: CFSpacing.md) {
                    ForEach(recentSessions) { session in
                        CFSessionRow(session: session)
                    }
                }
            }
        }
    }

    private var totalCompletedMinutes: Int {
        records
            .filter { $0.result == .success }
            .reduce(0) { $0 + $1.focusMinutes }
    }

    private var completedSessionCount: Int {
        records.filter { $0.result == .success }.count
    }

    private var focusTimeText: String {
        if totalCompletedMinutes >= 60 {
            return String(format: "%.1fh", Double(totalCompletedMinutes) / 60)
        }
        return "\(totalCompletedMinutes)m"
    }

    private var fitnessScore: FitnessScore {
        cat.fitnessScore
    }

    private var weeklyActivity: [CFActivityDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dailyMinutes = (-6...0).map { offset -> Int in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return records
                .filter { $0.result == .success && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + durationMinutes(for: $1) }
        }
        let chartMaximum = max(60, dailyMinutes.max() ?? 0)

        return (-6...0).enumerated().map { index, offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            let minutes = dailyMinutes[index]
            return CFActivityDay(
                label: date.formatted(.dateTime.weekday(.abbreviated)),
                value: min(1, CGFloat(minutes) / CGFloat(chartMaximum)),
                durationMinutes: minutes
            )
        }
    }

    private var recentSessions: [CFSessionSummary] {
        records.prefix(5).map { record in
            let resultTitle = record.result == .success ? "Focus Session" : "Abandoned Session"
            let dateText = sessionDateText(record.date)
            let detail = "\(dateText) · \(formattedDuration(durationMinutes(for: record))) session"
            let points = record.fitPoints > 0 ? "+\(record.fitPoints)" : "\(record.fitPoints)"
            return CFSessionSummary(
                icon: record.result == .success ? .focus : .myCat,
                title: resultTitle,
                detail: detail,
                pointsText: "\(points) Fit Points",
                tone: record.result == .success ? .success : .danger
            )
        }
    }

    private func durationMinutes(for record: TrainingSessionRecord) -> Int {
        record.focusMinutes
    }

    private func sessionDateText(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }

        if calendar.component(.year, from: date) == calendar.component(.year, from: .now) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }

        return date.formatted(.dateTime.year().month(.abbreviated).day())
    }

    private func formattedDuration(_ minutes: Int) -> String {
        let safeMinutes = max(0, minutes)
        let hours = safeMinutes / 60
        let remainingMinutes = safeMinutes % 60

        if hours == 0 {
            return "\(safeMinutes)m"
        }
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }
}

private struct CFMetricCard: View {
    var label: String
    var value: String
    var footnote: String?
    var status: String?
    var tone: CFStatusTone

    init(label: String, value: String, footnote: String? = nil, status: String? = nil, tone: CFStatusTone = .neutral) {
        self.label = label
        self.value = value
        self.footnote = footnote
        self.status = status
        self.tone = tone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(CFFont.caption)
                .tracking(1.1)
                .foregroundStyle(CFColor.textSecondary)

            CFAnimatedNumber(
                value: value,
                font: .system(size: 27, weight: .black, design: .rounded)
            )

            if let footnote {
                Text(footnote)
                    .font(CFFont.caption)
                    .foregroundStyle(tone == .success ? CFColor.accentSuccess : CFColor.textSecondary)
            } else if let status {
                CFMetricStatusLabel(icon: .heart, text: status, tone: tone)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 96)
        .padding(.horizontal, CFSpacing.md)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .stroke(CFColor.borderSubtle, lineWidth: 0.8)
        }
        .cfShadow(CFCloudLayer.cardShadow)
    }
}

private struct CFMetricStatusLabel: View {
    var icon: CFIcon
    var text: String
    var tone: CFStatusTone

    var body: some View {
        HStack(spacing: CFSpacing.xs) {
            icon.image
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(tone.iconColor)

            Text(text.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(CFColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CFWeeklyActivityChart: View {
    var days: [CFActivityDay]

    var body: some View {
        HStack(alignment: .bottom, spacing: CFSpacing.sm) {
            ForEach(days) { day in
                VStack(spacing: CFSpacing.sm) {
                    CFAnimatedNumber(
                        value: day.durationText,
                        font: CFFont.caption,
                        color: day.durationMinutes > 0 ? CFColor.textPrimary : CFColor.textTertiary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 16)

                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(CFColor.surfaceSoft)
                            .frame(width: 34, height: 112)

                        Capsule()
                            .fill(day.value > 0 ? CFColor.surfaceSelected : CFColor.surfaceSoft)
                            .frame(width: 34, height: max(16, 112 * day.value))
                    }

                    Text(day.label)
                        .font(CFFont.caption)
                        .foregroundStyle(CFColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.largeCard, style: .continuous)
                .stroke(CFColor.borderSubtle, lineWidth: 0.8)
        }
        .cfShadow(CFCloudLayer.cardShadow)
    }
}

private struct CFSessionRow: View {
    var session: CFSessionSummary

    var body: some View {
        HStack(spacing: CFSpacing.lg) {
            ZStack {
                Circle()
                    .fill(CFColor.surfaceSoft)
                    .frame(width: 40, height: 40)

                session.icon.image
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(session.tone == .danger ? CFColor.textTertiary : CFColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: CFSpacing.xs) {
                Text(session.title)
                    .font(CFFont.cardTitle)
                    .foregroundStyle(CFColor.textPrimary)

                Text(session.detail)
                    .font(CFFont.bodySmall)
                    .foregroundStyle(CFColor.textSecondary)
            }

            Spacer()

            Text(session.pointsText)
                .font(CFFont.cardTitle)
                .foregroundStyle(session.tone == .danger ? CFColor.accentDanger : CFColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .background(CFColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CFRadius.card, style: .continuous)
                .stroke(CFColor.borderSubtle, lineWidth: 0.8)
        }
        .cfShadow(CFCloudLayer.cardShadow)
    }
}

private struct CFActivityDay: Identifiable {
    let id = UUID()
    var label: String
    var value: CGFloat
    var durationMinutes: Int

    var durationText: String {
        let hours = durationMinutes / 60
        let remainingMinutes = durationMinutes % 60
        if hours == 0 { return "\(durationMinutes)m" }
        if remainingMinutes == 0 { return "\(hours)h" }
        return "\(hours)h \(remainingMinutes)m"
    }
}

private struct CFSessionSummary: Identifiable {
    let id = UUID()
    var icon: CFIcon
    var title: String
    var detail: String
    var pointsText: String
    var tone: CFStatusTone
}

#Preview("Stats") {
    StatsView()
}
