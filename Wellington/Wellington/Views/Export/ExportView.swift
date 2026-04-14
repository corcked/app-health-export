import SwiftUI

struct ExportView: View {
    @Environment(ExportService.self) private var exportService
    @Environment(HealthKitService.self) private var healthKitService

    @State private var selectedCategories: Set<HealthDataCategory> = []
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: DateRangeMode = .last30Days
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var exportResult: ExportResult?
    @State private var showShareSheet: Bool = false
    @State private var errorMessage: String?

    private var canExport: Bool {
        !selectedCategories.isEmpty && !exportService.isExporting
    }

    var body: some View {
        Form {
            dateRangeSection
            formatSection
            categoriesSection
            exportSection
        }
        .navigationTitle("tab_export" as LocalizedStringKey)
        .sheet(item: $exportResult) { result in
            ExportProgressView(
                exportResult: result,
                onShare: {
                    showShareSheet = true
                },
                onDismiss: {
                    exportResult = nil
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let result = exportResult {
                ShareSheetView(items: [result.fileURL])
            }
        }
        .alert(
            "error" as LocalizedStringKey,
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("ok" as LocalizedStringKey, role: .cancel) {
                errorMessage = nil
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: selectedCategories) {
            // Persist selected categories for background export
            let rawValues = selectedCategories.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: AppConstants.UserDefaultsKeys.selectedCategories)
        }
        .onChange(of: selectedFormat) {
            UserDefaults.standard.set(selectedFormat.rawValue, forKey: AppConstants.UserDefaultsKeys.exportFormat)
        }
        .onChange(of: selectedDateRange) {
            UserDefaults.standard.set(selectedDateRange.rawValue, forKey: AppConstants.UserDefaultsKeys.exportDateRangeMode)
        }
        .onAppear {
            loadSavedPreferences()
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section {
            Picker("export_date_range" as LocalizedStringKey, selection: $selectedDateRange) {
                ForEach(DateRangeMode.allCases) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }

            if selectedDateRange == .custom {
                DatePicker(
                    "export_start_date" as LocalizedStringKey,
                    selection: $customStartDate,
                    in: ...customEndDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "export_end_date" as LocalizedStringKey,
                    selection: $customEndDate,
                    in: customStartDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("export_date_range" as LocalizedStringKey)
        }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        Section {
            Picker("export_format" as LocalizedStringKey, selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName)
                        .tag(format)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("export_format" as LocalizedStringKey)
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        Section {
            NavigationLink {
                CategoryListView(selectedCategories: $selectedCategories)
            } label: {
                HStack {
                    Text("export_categories_title" as LocalizedStringKey)
                    Spacer()
                    Text("\(selectedCategories.count)")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("export_categories_title" as LocalizedStringKey)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                performExport()
            } label: {
                HStack {
                    Spacer()
                    if exportService.isExporting {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("export_exporting" as LocalizedStringKey)
                    } else {
                        Text("export_button" as LocalizedStringKey)
                            .font(.headline)
                    }
                    Spacer()
                }
            }
            .disabled(!canExport)
        }
    }

    // MARK: - Actions

    private func performExport() {
        let dateRange = DateRange.from(
            mode: selectedDateRange,
            customStart: selectedDateRange == .custom ? customStartDate : nil,
            customEnd: selectedDateRange == .custom ? customEndDate : nil
        )

        Task {
            do {
                // Request authorization for selected categories first
                try await healthKitService.requestAuthorization(
                    for: Array(selectedCategories)
                )

                let result = try await exportService.export(
                    categories: Array(selectedCategories),
                    format: selectedFormat,
                    dateRange: dateRange
                )
                exportResult = result
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadSavedPreferences() {
        if let rawValues = UserDefaults.standard.stringArray(forKey: AppConstants.UserDefaultsKeys.selectedCategories) {
            selectedCategories = Set(rawValues.compactMap { HealthDataCategory(rawValue: $0) })
        }
        if let formatRaw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.exportFormat),
           let format = ExportFormat(rawValue: formatRaw) {
            selectedFormat = format
        }
        if let rangeRaw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.exportDateRangeMode),
           let range = DateRangeMode(rawValue: rangeRaw) {
            selectedDateRange = range
        }
    }
}

// MARK: - ExportResult + Identifiable

extension ExportResult: @retroactive Identifiable {
    var id: URL { fileURL }
}

#Preview {
    NavigationStack {
        ExportView()
            .environment(ExportService(
                healthKitService: HealthKitService(),
                fileStorageService: FileStorageService()
            ))
            .environment(HealthKitService())
    }
}
