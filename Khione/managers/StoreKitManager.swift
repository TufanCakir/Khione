//
//  StoreKitManager.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {

    @Published var products: [Product] = []
    @Published var activeTier: SubscriptionTier = .free

    private let productIDs: [String] = [
        "khione.pro.monthly",
        "khione.vision.monthly"
    ]

    init() {
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }


    
    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("❌ Failed to load products:", error)
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

    // MARK: - Entitlements
    func refreshEntitlements() async {
        activeTier = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case "khione.pro.monthly":
                activeTier = .pro
            case "khione.vision.monthly":
                activeTier = .vision
            default:
                break
            }
        }
    }

    // MARK: - Helpers
    func product(for tier: SubscriptionTier) -> Product? {
        guard let id = tier.productID else { return nil }
        return products.first { $0.id == id }
    }
}
