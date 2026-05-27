import SwiftUI

struct SymbolSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String

    @State private var query = ""
    @State private var results: [SymbolResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(Color.appMuted)
                        Text("Searching…")
                            .foregroundStyle(Color.appMuted)
                    }
                    .themedRow()
                } else if !query.isEmpty && query.count >= 2 && results.isEmpty {
                    Text("No results for \"\(query)\"")
                        .foregroundStyle(Color.appMuted)
                        .themedRow()
                } else if query.count < 2 {
                    Label("Type at least 2 characters to search", systemImage: "magnifyingglass")
                        .foregroundStyle(Color.appMuted)
                        .font(.subheadline)
                        .themedRow()
                }

                ForEach(results) { result in
                    Button {
                        selectedSymbol = result.symbol
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 6) {
                                Text(result.symbol)
                                    .font(.headline)
                                    .foregroundStyle(Color.appPrimary)
                                typeChip(result.quoteType)
                            }
                            Text(result.name)
                                .font(.subheadline)
                                .foregroundStyle(Color.appMuted)
                        }
                        .padding(.vertical, 2)
                    }
                    .themedRow()
                }
            }
            .listStyle(.insetGrouped)
            .themedBackground()
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Company name or ticker…"
            )
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                results = []
                guard newValue.count >= 2 else {
                    isSearching = false
                    return
                }
                isSearching = true
                searchTask = Task {
                    do {
                        try await Task.sleep(for: .milliseconds(400))
                        let fetched = try await SymbolSearchService.search(query: newValue)
                        results = fetched
                    } catch {
                        if !Task.isCancelled { results = [] }
                    }
                    isSearching = false
                }
            }
            .navigationTitle("Select Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.appMuted)
                }
            }
        }
    }

    private func typeChip(_ type: String) -> some View {
        Text(type)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(chipColor(type).opacity(0.15))
            .foregroundStyle(chipColor(type))
            .clipShape(Capsule())
    }

    private func chipColor(_ type: String) -> Color {
        switch type {
        case "ETP":   return Color(hex: "B06020")   // warm amber
        case "Fund":  return Color(hex: "6A5A8E")   // muted purple
        case "ADR":   return Color(hex: "3A7070")   // muted teal
        default:      return Color.appPrimary        // dark olive
        }
    }
}
