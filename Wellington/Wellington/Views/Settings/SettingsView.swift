import SwiftUI

struct SettingsView: View {
    @Environment(HealthKitService.self) private var healthKitService

    @AppStorage(AppConstants.UserDefaultsKeys.autoSaveToiCloud) private var autoSaveToiCloud = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            iCloudSection
            tipJarSection
            healthKitSection
            aboutSection
        }
        .navigationTitle("settings_title" as LocalizedStringKey)
    }

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        Section {
            Toggle("settings_auto_save_icloud" as LocalizedStringKey, isOn: $autoSaveToiCloud)
        } header: {
            Text("settings_section_icloud" as LocalizedStringKey)
        } footer: {
            Text("settings_icloud_footer" as LocalizedStringKey)
        }
    }

    // MARK: - Tip Jar Section

    private var tipJarSection: some View {
        Section {
            NavigationLink {
                TipJarView()
            } label: {
                Label("settings_tip_jar" as LocalizedStringKey, systemImage: "heart.fill")
            }
        } header: {
            Text("settings_section_tip_jar" as LocalizedStringKey)
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        Section {
            Button {
                requestHealthKitPermissions()
            } label: {
                Label("settings_request_permissions" as LocalizedStringKey, systemImage: "heart.text.square")
            }
        } header: {
            Text("settings_section_healthkit" as LocalizedStringKey)
        } footer: {
            Text("settings_healthkit_footer" as LocalizedStringKey)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings_version" as LocalizedStringKey)
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("settings_developer" as LocalizedStringKey)
                Spacer()
                Text("Wellington Team")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("settings_section_about" as LocalizedStringKey)
        }
    }

    // MARK: - Actions

    private func requestHealthKitPermissions() {
        Task {
            try? await healthKitService.requestAuthorization(
                for: HealthDataCategory.allCases
            )
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(HealthKitService())
    }
}
