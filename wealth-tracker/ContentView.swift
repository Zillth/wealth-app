import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        AccountListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AccountModel.self, InstallmentPlanModel.self], inMemory: true)
}
