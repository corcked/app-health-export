import SwiftUI
import BackgroundTasks

@main
struct WellingtonApp: App {
    @State private var healthKitService = HealthKitService()
    @State private var storeKitService = StoreKitService()
    @State private var exportService: ExportService
    @State private var backgroundExportService = BackgroundExportService()

    init() {
        let hk = HealthKitService()
        let fileStorage = FileStorageService()
        _healthKitService = State(initialValue: hk)
        _exportService = State(initialValue: ExportService(
            healthKitService: hk,
            fileStorageService: fileStorage
        ))

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppConstants.backgroundExportTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            Task {
                await BackgroundExportService.shared.handleBackgroundExport(task: processingTask)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitService)
                .environment(exportService)
                .environment(storeKitService)
                .environment(backgroundExportService)
        }
    }
}

struct ContentView: View {
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
