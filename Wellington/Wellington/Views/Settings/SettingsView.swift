import SwiftUI

struct SettingsView: View {
    @Environment(HealthKitService.self) private var healthKitService

    @AppStorage(AppConstants.UserDefaultsKeys.autoSaveToiCloud) private var autoSaveToiCloud = false
    @State private var showFolderPicker = false
    @State private var savedFolderName: String?

    private let fileStorageService = FileStorageService()

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            exportFolderSection
            tipJarSection
            healthKitSection
            aboutSection
        }
        .navigationTitle("settings_title" as LocalizedStringKey)
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { url in
                try? fileStorageService.saveExportFolderBookmark(for: url)
                savedFolderName = fileStorageService.savedFolderName
            }
        }
        .onAppear {
            savedFolderName = fileStorageService.savedFolderName
        }
    }

    // MARK: - Export Folder Section

    private var exportFolderSection: some View {
        Section {
            Button {
                showFolderPicker = true
            } label: {
                HStack {
                    Label("settings_choose_folder" as LocalizedStringKey, systemImage: "folder")
                    Spacer()
                    if let savedFolderName {
                        Text(savedFolderName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("settings_no_folder" as LocalizedStringKey)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .tint(.primary)

            if savedFolderName != nil {
                Button(role: .destructive) {
                    fileStorageService.clearExportFolderBookmark()
                    savedFolderName = nil
                } label: {
                    Label("settings_clear_folder" as LocalizedStringKey, systemImage: "folder.badge.minus")
                }
            }

            Toggle("settings_auto_save_icloud" as LocalizedStringKey, isOn: $autoSaveToiCloud)
        } header: {
            Text("settings_section_export" as LocalizedStringKey)
        } footer: {
            Text("settings_export_footer" as LocalizedStringKey)
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
