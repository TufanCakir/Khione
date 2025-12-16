//
//  StoreKitManager.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

internal import Combine
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTier: SubscriptionTier = .free

    // MARK: - Product IDs
    private let productIDs: [String] = [
        "khione.pro.monthly",
        "khione.vision.monthly",
        "khione.infinity.monthly",
    ]

    // MARK: - Init
    init() {
        Task {
            await loadProducts()
            await observeTransactions()
            await refreshEntitlements()
        }
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("❌ StoreKit: Failed to load products:", error)
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        guard
            case .success(let verification) = result,
            case .verified(let transaction) = verification
        else { return }

        await transaction.finish()
        await refreshEntitlements()
    }

    // MARK: - Observe Transactions (🔥 WICHTIG)
    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            await transaction.finish()
            await refreshEntitlements()
        }
    }

    // MARK: - Entitlements (Single Source of Truth)
    func refreshEntitlements() async {
        var detectedTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case "khione.pro.monthly":
                detectedTier = .pro
            case "khione.vision.monthly":
                detectedTier = .vision
            case "khione.infinity.monthly":
                detectedTier = .infinity
            default:
                break
            }
        }

        activeTier = detectedTier
    }

    // MARK: - Helpers
    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }
}
