import SwiftUI
import SwiftData

@main
struct wealth_trackerApp: App {

    init() {
        // Navigation bar — cream background, dark-olive text & tint
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

        // List / Form table background
        UITableView.appearance().backgroundColor = UIColor(Color.appBackground)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AccountModel.self,
            SubscriptionModel.self,
            InstallmentPlanModel.self,
            StockPosition.self,
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
