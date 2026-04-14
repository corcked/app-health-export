import SwiftUI

struct ScheduleView: View {
    @Environment(BackgroundExportService.self) private var backgroundExportService

    @AppStorage(AppConstants.UserDefaultsKeys.backgroundExportEnabled) private var backgroundExportEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.backgroundExportSchedule) private var scheduleRawValue = ExportSchedule.weekly.rawValue

    private var selectedSchedule: Binding<ExportSchedule> {
        Binding(
            get: { ExportSchedule(rawValue: scheduleRawValue) ?? .weekly },
            set: { scheduleRawValue = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("schedule_enable" as LocalizedStringKey, isOn: $backgroundExportEnabled)
            } footer: {
                Text("schedule_enable_footer" as LocalizedStringKey)
            }

            if backgroundExportEnabled {
                Section {
                    Picker("schedule_frequency" as LocalizedStringKey, selection: selectedSchedule) {
                        ForEach(ExportSchedule.allCases) { schedule in
                            Text(schedule.displayName)
                                .tag(schedule)
                        }
                    }
                } header: {
                    Text("schedule_section_frequency" as LocalizedStringKey)
                }

                Section {
                    Label {
                        Text("schedule_info" as LocalizedStringKey)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("schedule_info_footer" as LocalizedStringKey)
                }
            }
        }
        .navigationTitle("schedule_title" as LocalizedStringKey)
        .onChange(of: backgroundExportEnabled) { _, isEnabled in
            if isEnabled {
                backgroundExportService.scheduleBackgroundExport()
            } else {
                backgroundExportService.cancelBackgroundExport()
            }
        }
        .onChange(of: scheduleRawValue) { _, _ in
            if backgroundExportEnabled {
                backgroundExportService.scheduleBackgroundExport()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
            .environment(BackgroundExportService())
    }
}
