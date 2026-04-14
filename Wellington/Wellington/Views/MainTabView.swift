import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ExportView()
            }
            .tabItem {
                Label("tab_export" as LocalizedStringKey, systemImage: "square.and.arrow.up")
            }

            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("tab_schedule" as LocalizedStringKey, systemImage: "clock.arrow.2.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("tab_settings" as LocalizedStringKey, systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainTabView()
}
