import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }

            SpendView()
                .tabItem {
                    Label("Spend", systemImage: "cart")
                }
        }
        .tint(Color.appPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [AccountModel.self, InstallmentPlanModel.self,
                  SubscriptionModel.self, StockPosition.self,
                  BudgetCategory.self, SpendEntry.self],
            inMemory: true
        )
}
