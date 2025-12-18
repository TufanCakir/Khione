//
//  StoreKitManager.swift
//  Khione
//

import StoreKit
internal import Combine

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeTier: SubscriptionTier = .free

    // MARK: - Product IDs
    private let productIDs: [String] = [
        "khione.pro.monthly",
        "khione.vision.monthly",
        "khione.infinity.monthly"
    ]

    private var transactionTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        Task { await start() }
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Startup
    private func start() async {
        await loadProducts()
        await refreshEntitlements()
        startObservingTransactions()
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("❌ StoreKit loadProducts:", error)
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

    // MARK: - Observe Transactions
    private func startObservingTransactions() {
        transactionTask = Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    // MARK: - Entitlements
    func refreshEntitlements() async {
        var detectedTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case "khione.infinity.monthly":
                detectedTier = .infinity
            case "khione.vision.monthly":
                if detectedTier != .infinity { detectedTier = .vision }
            case "khione.pro.monthly":
                if detectedTier == .free { detectedTier = .pro }
            default:
                break
            }
        }

        activeTier = detectedTier
    }

    // MARK: - Products
    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    var activeProduct: Product? {
        guard let id = activeTier.productID else { return nil }
        return product(for: id)
    }
}

