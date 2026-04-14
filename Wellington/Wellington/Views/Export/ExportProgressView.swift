import SwiftUI

struct ExportProgressView: View {
    let exportResult: ExportResult?
    var onShare: () -> Void
    var onDismiss: () -> Void

    @AppStorage(AppConstants.UserDefaultsKeys.autoSaveToiCloud) private var autoSaveToiCloud = false

    private var fileSize: String? {
        guard let url = exportResult?.fileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let result = exportResult {
                    completedContent(result)
                } else {
                    exportingContent
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done" as LocalizedStringKey) {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Exporting State

    private var exportingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("export_progress_exporting" as LocalizedStringKey)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Completed State

    private func completedContent(_ result: ExportResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("export_progress_complete" as LocalizedStringKey)
                .font(.title2.bold())

            VStack(spacing: 8) {
                detailRow(
                    label: "export_progress_records" as LocalizedStringKey,
                    value: "\(result.recordCount)"
                )

                if let fileSize {
                    detailRow(
                        label: "export_progress_file_size" as LocalizedStringKey,
                        value: fileSize
                    )
                }

                detailRow(
                    label: "export_progress_format" as LocalizedStringKey,
                    value: result.format.displayName
                )

                detailRow(
                    label: "export_progress_date" as LocalizedStringKey,
                    value: result.exportDate.dateTimeString
                )
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 12) {
                Button {
                    onShare()
                } label: {
                    Label("export_progress_share" as LocalizedStringKey, systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !autoSaveToiCloud {
                    Button {
                        saveToiCloud()
                    } label: {
                        Label("export_progress_save_icloud" as LocalizedStringKey, systemImage: "icloud.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Detail Row

    private func detailRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    // MARK: - Actions

    private func saveToiCloud() {
        // iCloud save logic will be integrated with FileStorageService
    }
}

#Preview("Completed") {
    ExportProgressView(
        exportResult: ExportResult(
            fileURL: URL(fileURLWithPath: "/tmp/export.csv"),
            format: .csv,
            recordCount: 1_234,
            categories: [.steps, .heartRate],
            dateRange: DateRange.from(mode: .last30Days)
        ),
        onShare: {},
        onDismiss: {}
    )
}

#Preview("Exporting") {
    ExportProgressView(
        exportResult: nil,
        onShare: {},
        onDismiss: {}
    )
}
