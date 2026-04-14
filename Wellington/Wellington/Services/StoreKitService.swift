import Foundation
import StoreKit
import Observation
import os

@Observable
final class StoreKitService {
    private let logger = Logger(subsystem: "com.wellington", category: "StoreKit")

    private(set) var tipProducts: [Product] = []
    private(set) var isLoading = false
    private(set) var purchaseState: PurchaseState = .idle

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)

        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.purchasing, .purchasing), (.purchased, .purchased):
                return true
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    func loadProducts() async {
        guard tipProducts.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: AppConstants.StoreKit.allProductIDs)
            tipProducts = products.sorted { $0.price < $1.price }
            logger.info("Loaded \(products.count) tip products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            tipProducts = []
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseState = .purchased
                logger.info("Purchase completed: \(product.id)")

            case .userCancelled:
                purchaseState = .idle
                logger.info("Purchase cancelled by user")

            case .pending:
                purchaseState = .idle
                logger.info("Purchase pending")

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            logger.error("Purchase failed: \(error.localizedDescription)")
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
