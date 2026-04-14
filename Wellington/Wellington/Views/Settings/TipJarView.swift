import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(StoreKitService.self) private var storeKitService

    @State private var isPurchasing: Bool = false
    @State private var showThankYou: Bool = false
    @State private var purchaseError: String?

    var body: some View {
        List {
            headerSection
            productsSection
        }
        .navigationTitle("tip_jar_title" as LocalizedStringKey)
        .task { await storeKitService.loadProducts() }
        .overlay {
            if showThankYou {
                thankYouOverlay
            }
        }
        .alert(
            "tip_jar_error_title" as LocalizedStringKey,
            isPresented: .init(
                get: { purchaseError != nil },
                set: { if !$0 { purchaseError = nil } }
            )
        ) {
            Button("ok" as LocalizedStringKey, role: .cancel) {
                purchaseError = nil
            }
        } message: {
            if let purchaseError {
                Text(purchaseError)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.brown)

                Text("tip_jar_message" as LocalizedStringKey)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Products

    private var productsSection: some View {
        Section {
            ForEach(storeKitService.tipProducts) { product in
                tipRow(product: product)
            }
        } header: {
            Text("tip_jar_section_tips" as LocalizedStringKey)
        }
    }

    private func tipRow(product: Product) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                purchase(product)
            } label: {
                Text(product.displayPrice)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Thank You Overlay

    private var thankYouOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.pink)

            Text("tip_jar_thank_you" as LocalizedStringKey)
                .font(.title2.bold())

            Text("tip_jar_thank_you_message" as LocalizedStringKey)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation {
                showThankYou = false
            }
        }
    }

    // MARK: - Actions

    private func purchase(_ product: Product) {
        isPurchasing = true
        Task {
            await storeKitService.purchase(product)

            switch storeKitService.purchaseState {
            case .purchased:
                withAnimation {
                    showThankYou = true
                }
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    showThankYou = false
                }
                storeKitService.resetPurchaseState()
            case .failed(let message):
                purchaseError = message
                storeKitService.resetPurchaseState()
            default:
                break
            }

            isPurchasing = false
        }
    }
}

#Preview {
    NavigationStack {
        TipJarView()
            .environment(StoreKitService())
    }
}
