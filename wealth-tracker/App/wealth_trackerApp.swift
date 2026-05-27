import SwiftUI
import SwiftData

@main
struct wealth_trackerApp: App {

    init() {
        // Navigation bar
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor          = UIColor(Color.appBackground)
        nav.shadowColor              = .clear
        nav.titleTextAttributes      = [.foregroundColor: UIColor(Color.appPrimary)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appPrimary)]
        UINavigationBar.appearance().standardAppearance   = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance    = nav
        UINavigationBar.appearance().tintColor            = UIColor(Color.appAccent)

        // Tab bar
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Color.appBackground)
        tab.shadowColor     = .clear
        let item = UITabBarItemAppearance()
        item.normal.iconColor           = UIColor(Color.appPrimary).withAlphaComponent(0.3)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.appPrimary).withAlphaComponent(0.3)]
        item.selected.iconColor           = UIColor(Color.appPrimary)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.appPrimary)]
        tab.stackedLayoutAppearance       = item
        tab.inlineLayoutAppearance        = item
        tab.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance   = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        // List / Form table background
        UITableView.appearance().backgroundColor = UIColor(Color.appBackground)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AccountModel.self,
            SubscriptionModel.self,
            InstallmentPlanModel.self,
            StockPosition.self,
            BudgetCategory.self,
            SpendEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
