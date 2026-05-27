import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.createdAt, order: .forward) private var categories: [BudgetCategory]
    @Query private var allSpends: [SpendEntry]

    @State private var showingAdd = false
    @State private var editingCategory: BudgetCategory?

    private let currency = Locale.current.currency?.identifier ?? "MXN"

    // MARK: - Totals

    private var totalMonthlyBudget: Double {
        categories.reduce(0) { $0 + $1.monthlyLimit }
    }

    private var totalSpentThisMonth: Double {
        thisMonthSpends.reduce(0) { $0 + $1.amount }
    }

    private var thisMonthSpends: [SpendEntry] {
        let cal = Calendar.current
        let now = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)
        return allSpends.filter {
            cal.component(.month, from: $0.date) == month &&
            cal.component(.year,  from: $0.date) == year
        }
    }

    private func spentThisMonth(for category: BudgetCategory) -> Double {
        thisMonthSpends
            .filter { $0.category?.id == category.id }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    emptyState
                } else {
                    categoryList
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus").fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddBudgetCategoryView()
            }
            .sheet(item: $editingCategory) { cat in
                AddBudgetCategoryView(editing: cat)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appMuted)
                Text("No Budget Categories")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                Text("Tap + to create your first category.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
            }
        }
    }

    // MARK: - List

    private var categoryList: some View {
        List {
            // Summary card
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MONTHLY BUDGET")
                        .font(.system(size: 10, weight: .regular))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(totalMonthlyBudget, format: .currency(code: currency))
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(totalSpentThisMonth, format: .currency(code: currency))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                        Text("spent this month")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        let remaining = totalMonthlyBudget - totalSpentThisMonth
                        if remaining >= 0 {
                            Text(remaining, format: .currency(code: currency))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                            Text("left")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        } else {
                            Text((-remaining), format: .currency(code: currency))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "E07070"))
                            Text("over budget")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 38)
                .listRowBackground(Color(hex: "433D3D"))
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            // Categories
            Section {
                ForEach(categories) { cat in
                    Button { editingCategory = cat } label: {
                        BudgetCategoryRow(
                            category: cat,
                            spent:    spentThisMonth(for: cat),
                            currency: currency
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            modelContext.delete(cat)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .themedRow()
                }
            } header: {
                ThemedSectionHeader(title: "Categories")
            }
        }
        .listStyle(.insetGrouped)
        .themedBackground()
    }
}

// MARK: - Category Row

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    let spent: Double
    let currency: String

    private var remaining: Double { category.monthlyLimit - spent }
    private var progress: Double {
        guard category.monthlyLimit > 0 else { return 0 }
        return min(spent / category.monthlyLimit, 1.0)
    }
    private var isOver: Bool { spent > category.monthlyLimit }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name + limit
            HStack {
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Text(category.monthlyLimit, format: .currency(code: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBackground)
                        .frame(height: 5)
                    Capsule()
                        .fill(isOver ? Color.appNegative : Color.appPositive)
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 5)

            // Spent / remaining labels
            HStack {
                Text(spent, format: .currency(code: currency))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isOver ? Color.appNegative : Color.appMuted)
                Text("spent")
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)
                Spacer()
                if isOver {
                    Text((-remaining), format: .currency(code: currency))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appNegative)
                    Text("over")
                        .font(.caption)
                        .foregroundStyle(Color.appNegative)
                } else {
                    Text(remaining, format: .currency(code: currency))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appPositive)
                    Text("left")
                        .font(.caption)
                        .foregroundStyle(Color.appMuted)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
