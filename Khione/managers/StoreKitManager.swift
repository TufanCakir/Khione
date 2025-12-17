//
//  StoreKitManager.swift
//  Khione
//

import StoreKit
internal import Combine

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTier: SubscriptionTier = .free

    // MARK: - Product IDs
    private let productIDs: [String] = [
        "khione.pro.monthly",
        "khione.vision.monthly",
        "khione.infinity.monthly"
    ]

    // MARK: - Init
    init() {
        Task {
            await start()
        }
    }

    // MARK: - Startup Flow (🔑 klar & deterministisch)
    private func start() async {
        await loadProducts()
        await refreshEntitlements()
        observeTransactions()
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
        else {
            return
        }

        await transaction.finish()
        await refreshEntitlements()
    }

    // MARK: - Observe Transactions (läuft im Hintergrund)
    private func observeTransactions() {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }

                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    // MARK: - Entitlements (Single Source of Truth)
    func refreshEntitlements() async {
        var detectedTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case "khione.infinity.monthly":
                detectedTier = .infinity
            case "khione.vision.monthly":
                if detectedTier != .infinity {
                    detectedTier = .vision
                }
            case "khione.pro.monthly":
                if detectedTier == .free {
                    detectedTier = .pro
                }
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
