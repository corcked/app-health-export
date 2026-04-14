import SwiftUI

struct OnboardingView: View {
    @Environment(HealthKitService.self) private var healthKitService

    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @State private var isRequestingAuthorization = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            headerSection

            featuresSection

            Spacer()

            getStartedButton

            Spacer()
                .frame(height: 16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red.gradient)

            Text("onboarding_welcome_title" as LocalizedStringKey)
                .font(.largeTitle.bold())

            Text("onboarding_welcome_subtitle" as LocalizedStringKey)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(
                icon: "square.and.arrow.up",
                color: .blue,
                title: "onboarding_feature_export_title" as LocalizedStringKey,
                description: "onboarding_feature_export_description" as LocalizedStringKey
            )

            featureRow(
                icon: "clock.arrow.2.circlepath",
                color: .orange,
                title: "onboarding_feature_schedule_title" as LocalizedStringKey,
                description: "onboarding_feature_schedule_description" as LocalizedStringKey
            )

            featureRow(
                icon: "doc.text",
                color: .green,
                title: "onboarding_feature_formats_title" as LocalizedStringKey,
                description: "onboarding_feature_formats_description" as LocalizedStringKey
            )

            featureRow(
                icon: "icloud.and.arrow.up",
                color: .purple,
                title: "onboarding_feature_icloud_title" as LocalizedStringKey,
                description: "onboarding_feature_icloud_description" as LocalizedStringKey
            )
        }
        .padding()
    }

    private func featureRow(
        icon: String,
        color: Color,
        title: LocalizedStringKey,
        description: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button {
            getStarted()
        } label: {
            HStack {
                if isRequestingAuthorization {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 4)
                }
                Text("onboarding_get_started" as LocalizedStringKey)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isRequestingAuthorization)
    }

    // MARK: - Actions

    private func getStarted() {
        isRequestingAuthorization = true
        Task {
            do {
                try await healthKitService.requestAuthorization(
                    for: HealthDataCategory.allCases
                )
            } catch {
                // User denied or HealthKit unavailable — still let them proceed
            }
            hasCompletedOnboarding = true
            isRequestingAuthorization = false
        }
    }
}

#Preview {
    OnboardingView()
        .environment(HealthKitService())
}
