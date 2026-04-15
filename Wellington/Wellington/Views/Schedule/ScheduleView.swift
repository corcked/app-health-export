import SwiftUI

struct ScheduleView: View {
    @Environment(BackgroundExportService.self) private var backgroundExportService

    @AppStorage(AppConstants.UserDefaultsKeys.backgroundExportEnabled) private var backgroundExportEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.backgroundExportSchedule) private var scheduleRawValue = ExportSchedule.weekly.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.preferredExportHour) private var preferredExportHour = 6

    @State private var exportLogs: [ExportLog] = []
    @State private var logsPage = 0
    private let logsPerPage = 20

    private var selectedSchedule: Binding<ExportSchedule> {
        Binding(
            get: { ExportSchedule(rawValue: scheduleRawValue) ?? .weekly },
            set: { scheduleRawValue = $0.rawValue }
        )
    }

    private var preferredTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = preferredExportHour
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                preferredExportHour = Calendar.current.component(.hour, from: newDate)
            }
        )
    }

    private var visibleLogs: [ExportLog] {
        let end = min((logsPage + 1) * logsPerPage, exportLogs.count)
        guard end > 0 else { return [] }
        return Array(exportLogs[0..<end])
    }

    private var hasMoreLogs: Bool {
        (logsPage + 1) * logsPerPage < exportLogs.count
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

                    DatePicker(
                        "schedule_preferred_time" as LocalizedStringKey,
                        selection: preferredTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("schedule_section_frequency" as LocalizedStringKey)
                } footer: {
                    Text("schedule_time_footer" as LocalizedStringKey)
                }
            }

            // Export logs
            if !exportLogs.isEmpty {
                Section {
                    ForEach(visibleLogs) { log in
                        HStack {
                            Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(log.success ? .green : .red)
                                .font(.caption)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.date, style: .date)
                                    .font(.subheadline)
                                + Text("  ")
                                + Text(log.date, style: .time)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if log.success {
                                    Text("\(log.recordCount) records · \(log.format.uppercased())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let error = log.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }

                    if hasMoreLogs {
                        Button("schedule_load_more" as LocalizedStringKey) {
                            logsPage += 1
                        }
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("schedule_section_logs" as LocalizedStringKey)
                } footer: {
                    Text("schedule_logs_footer \(exportLogs.count)")
                }
            }
        }
        .navigationTitle("schedule_title" as LocalizedStringKey)
        .onAppear {
            exportLogs = ExportLog.loadAll()
            backgroundExportService.requestNotificationPermission()
        }
        .onChange(of: backgroundExportEnabled) { _, isEnabled in
            if isEnabled {
                backgroundExportService.requestNotificationPermission()
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
        .onChange(of: preferredExportHour) { _, _ in
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
