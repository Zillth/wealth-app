import SwiftUI
import SwiftData

struct SpendView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpendEntry.date, order: .reverse) private var allSpends: [SpendEntry]

    @State private var referenceDate = Date()
    @State private var selectedDate  = Date()
    @State private var showingAdd    = false
    @State private var editingSpend: SpendEntry?

    private let cal      = Calendar.current
    private let currency = Locale.current.currency?.identifier ?? "MXN"

    // MARK: - Week helpers

    private var weekInterval: DateInterval? {
        cal.dateInterval(of: .weekOfYear, for: referenceDate)
    }

    private var weekDays: [Date] {
        guard let start = weekInterval?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var weekSpends: [SpendEntry] {
        guard let interval = weekInterval else { return [] }
        return allSpends.filter { interval.contains($0.date) }
    }

    private var spendDayKeys: Set<String> {
        Set(weekSpends.map { dayKey($0.date) })
    }

    private func dayKey(_ date: Date) -> String {
        "\(cal.startOfDay(for: date).timeIntervalSince1970)"
    }

    private var isCurrentWeek: Bool {
        cal.isDate(referenceDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Navigation

    private func previousWeek() {
        referenceDate = cal.date(byAdding: .weekOfYear, value: -1, to: referenceDate) ?? referenceDate
    }

    private func nextWeek() {
        referenceDate = cal.date(byAdding: .weekOfYear, value: 1, to: referenceDate) ?? referenceDate
    }

    private func jumpToToday() {
        referenceDate = Date()
        selectedDate  = Date()
    }

    // MARK: - Week title

    private var weekTitle: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let sameMonth  = cal.component(.month, from: first) == cal.component(.month, from: last)
        let sameYear   = cal.component(.year,  from: last)  == cal.component(.year,  from: Date())
        let startFmt   = DateFormatter(); startFmt.dateFormat = "MMM d"
        let endFmt     = DateFormatter(); endFmt.dateFormat   = sameMonth ? "d" : "MMM d"
        let yearSuffix = sameYear ? "" : ", \(cal.component(.year, from: last))"
        return "\(startFmt.string(from: first)) – \(endFmt.string(from: last))\(yearSuffix)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                calendarHeader   // outside List — no gesture conflicts
                spendList
            }
            .navigationTitle("Spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingAdd) {
            AddSpendView(for: selectedDate)
        }
        .sheet(item: $editingSpend) { spend in
            AddSpendView(for: spend.date, editing: spend)
        }
    }

    // MARK: - Calendar header (plain VStack, NOT inside a List row)

    private var calendarHeader: some View {
        VStack(spacing: 18) {
            HStack {
                Button { previousWeek() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(weekTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appPrimary)
                    if !isCurrentWeek {
                        Button("Today") { jumpToToday() }
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appPrimary.opacity(0.45))
                    }
                }

                Spacer()

                Button { nextWeek() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }

            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    DayCell(
                        date:      day,
                        isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                        isToday:    cal.isDateInToday(day),
                        hasSpends:  spendDayKeys.contains(dayKey(day))
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = day
                        showingAdd   = true
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { v in
                        guard abs(v.translation.width) > abs(v.translation.height) else { return }
                        if v.translation.width < 0 { nextWeek() } else { previousWeek() }
                    }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.appSurface)
    }

    // MARK: - Spend list

    private var spendList: some View {
        List {
            Section {
                if weekSpends.isEmpty {
                    HStack {
                        Spacer()
                        Text("No spends this week")
                            .font(.subheadline)
                            .foregroundStyle(Color.appMuted)
                            .padding(.vertical, 18)
                        Spacer()
                    }
                    .themedRow()
                } else {
                    ForEach(weekSpends) { spend in
                        Button { editingSpend = spend } label: {
                            SpendEntryRow(spend: spend, currency: currency)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                spend.account?.reverseSpend(spend.amount)
                                modelContext.delete(spend)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .themedRow()
                    }
                }
            } header: {
                ThemedSectionHeader(title: weekTitle)
            }
        }
        .listStyle(.insetGrouped)
        .themedBackground()
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasSpends: Bool

    private static let letterFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEEE"; return f
    }()
    private static let numberFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()

    var body: some View {
        VStack(spacing: 6) {
            Text(Self.letterFmt.string(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? Color.appPrimary : Color.appMuted.opacity(0.6))

            ZStack {
                if isSelected { Circle().fill(Color.appPrimary) }
                else if isToday { Circle().strokeBorder(Color.appPrimary.opacity(0.45), lineWidth: 1.5) }
                Text(Self.numberFmt.string(from: date))
                    .font(.system(size: 14, weight: (isSelected || isToday) ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : Color.appPrimary)
            }
            .frame(width: 32, height: 32)

            Circle()
                .fill(hasSpends ? Color.appPrimary.opacity(0.35) : .clear)
                .frame(width: 4, height: 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Spend Entry Row

struct SpendEntryRow: View {
    let spend: SpendEntry
    let currency: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(spend.category?.name ?? "Uncategorized")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                HStack(spacing: 4) {
                    if let accName = spend.account?.name {
                        Text(accName).font(.caption).foregroundStyle(Color.appMuted)
                        Text("·").font(.caption).foregroundStyle(Color.appMuted)
                    }
                    Text(spend.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .font(.caption).foregroundStyle(Color.appMuted)
                }
                if !spend.note.isEmpty {
                    Text(spend.note).font(.caption)
                        .foregroundStyle(Color.appMuted.opacity(0.7)).lineLimit(1)
                }
            }
            Spacer()
            Text(spend.amount, format: .currency(code: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appNegative)
        }
        .padding(.vertical, 4)
    }
}
