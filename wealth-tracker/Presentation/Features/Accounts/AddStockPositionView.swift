import SwiftUI
import SwiftData

struct AddStockPositionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: AccountModel
    var editingPosition: StockPosition? = nil

    @State private var ticker: String
    @State private var shares: String
    @State private var avgCost: String
    @State private var showingSymbolSearch = false
    @State private var showingDeleteConfirmation = false

    init(account: AccountModel, editingPosition: StockPosition? = nil) {
        self.account = account
        self.editingPosition = editingPosition
        _ticker  = State(initialValue: editingPosition?.ticker ?? "")
        _shares  = State(initialValue: editingPosition.map { fmt($0.shares) } ?? "")
        _avgCost = State(initialValue: editingPosition.map { fmt($0.avgCost) } ?? "")
    }

    private var isEditing: Bool { editingPosition != nil }
    private var isValid: Bool { !ticker.isEmpty && !shares.isEmpty && !avgCost.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingSymbolSearch = true
                    } label: {
                        HStack {
                            Text(ticker.isEmpty ? "Search symbol…" : ticker)
                                .foregroundStyle(ticker.isEmpty ? Color.appMuted : Color.appPrimary)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    .themedRow()
                    CurrencyTextField(label: "Avg cost per share", text: $avgCost)
                        .themedRow()
                    TextField("Quantity (shares)", text: $shares)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Color.appPrimary)
                        .themedRow()
                } header: {
                    ThemedSectionHeader(title: "Position")
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Position")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .themedRow()
                    }
                }
            }
            .themedBackground()
            .navigationTitle(isEditing ? "Edit Position" : "Add Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.appMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSymbolSearch) {
                SymbolSearchView(selectedSymbol: $ticker)
            }
            .confirmationDialog(
                "Delete this position?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let position = editingPosition {
                        modelContext.delete(position)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let newTicker     = ticker.uppercased()
        let parsedShares  = parse(shares)
        let parsedAvgCost = parse(avgCost)

        if let position = editingPosition {
            let tickerChanged = newTicker != position.ticker
            position.ticker  = newTicker
            position.shares  = parsedShares
            position.avgCost = parsedAvgCost
            if tickerChanged { position.currentPrice = 0 }
        } else {
            let position = StockPosition(ticker: newTicker, shares: parsedShares, avgCost: parsedAvgCost)
            account.positions.append(position)
        }
        dismiss()
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
    }
}

private func fmt(_ v: Double) -> String {
    v == 0 ? "" : String(format: "%g", v)
}
