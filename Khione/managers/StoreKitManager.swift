//
//  StoreKitManager.swift
//  Khione
//

internal import Combine
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTier: SubscriptionTier = .free

    // MARK: - Product IDs (order = importance)
    private let productIDs: [String] = [
        "khione.pro.monthly",
        "khione.vision.monthly",
        "khione.infinity.monthly",
    ]

    private var transactionTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        Task { await bootstrap() }
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Bootstrap
    private func bootstrap() async {
        await loadProducts()
        await refreshEntitlements()
        observeTransactions()
    }

    // MARK: - Products
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)

            // 🔥 deterministic order for UI
            products = fetched.sorted {
                productIDs.firstIndex(of: $0.id)! < productIDs.firstIndex(
                    of: $1.id
                )!
            }
        } catch {
            print("❌ StoreKit loadProducts failed:", error)
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var activeProduct: Product? {
        guard let id = activeTier.productID else { return nil }
        return product(for: id)
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

    // MARK: - Restore (Apple expects this)
    func restorePurchases() async {
        await refreshEntitlements()
    }

    // MARK: - Observe Transactions
    private func observeTransactions() {
        transactionTask?.cancel()

        transactionTask = Task {
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    // MARK: - Entitlements
    func refreshEntitlements() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if let tier = SubscriptionTier(productID: transaction.productID) {
                if tier.rank > highestTier.rank {
                    highestTier = tier
                }
            }
        }

        activeTier = highestTier
    }
}
