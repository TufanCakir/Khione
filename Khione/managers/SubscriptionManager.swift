//
//  SubscriptionManager.swift
//  Khione
//

import SwiftUI
import StoreKit
internal import Combine

@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Published
    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var plan: SubscriptionPlan
    @Published private(set) var plans: [SubscriptionPlan] = []
    @Published private(set) var remainingMessagesToday: Int = 0

    // MARK: - Dependencies
    private let storeKit: StoreKitManager
    private let allModes = KhioneModeRegistry.all

    // MARK: - Persistence
    private let remainingKey = "remainingMessagesToday"
    private let lastConsumeKey = "lastMessageConsumeDate"
    private let initializedKey = "freeTierInitialized"

    @AppStorage("khione_language")
    private var language: String = "en"

    // MARK: - Init
    init(storeKit: StoreKitManager) {
        self.storeKit = storeKit

        let lang = UserDefaults.standard.string(forKey: "khione_language") ?? "en"
        let loadedPlans = Bundle.main.loadPlans(language: lang)

        self.plans = loadedPlans
        self.plan = loadedPlans.first { $0.id == "free" }!

        // 🔑 Restore persisted state
        self.remainingMessagesToday = storedRemainingMessages

        Task { await syncWithStoreKit() }
    }
    // MARK: - Pricing
    func price(for tier: SubscriptionTier) -> String {
        guard let productID = tier.productID else { return "—" }
        return storeKit.product(for: productID)?.displayPrice ?? "—"
    }


    // MARK: - StoreKit Sync
    func syncWithStoreKit() async {
        await storeKit.refreshEntitlements()
        applyTier(storeKit.activeTier)
    }

    private func applyTier(_ newTier: SubscriptionTier) {
        tier = newTier
        reloadPlans()
        initializeFreeIfNeeded()
        refillMessagesIfNeeded()
    }

    // MARK: - Plans
    func reloadPlans() {
        let loaded = Bundle.main.loadPlans(language: language)
        plans = loaded
        plan = loaded.first { $0.id == tier.rawValue }
            ?? loaded.first { $0.id == "free" }!
    }

    // MARK: - Messaging Logic
    var canSendMessage: Bool {
        tier != .free || remainingMessagesToday > 0
    }

    func consumeMessageIfNeeded() {
        guard tier == .free else { return }

        refillMessagesIfNeeded()
        guard remainingMessagesToday > 0 else { return }

        remainingMessagesToday -= 1
        storedRemainingMessages = remainingMessagesToday
        lastConsumeDate = Date()
    }

    var dailyMessageLimit: Int {
        plan.dailyMessageLimit
    }

    // MARK: - Refill System
    private let refillInterval: TimeInterval = 2 * 60 * 60

    private func initializeFreeIfNeeded() {
        guard tier == .free else { return }

        if !isInitialized {
            remainingMessagesToday = dailyMessageLimit
            storedRemainingMessages = remainingMessagesToday
            lastConsumeDate = Date()
            isInitialized = true
        }
    }

    private func refillMessagesIfNeeded() {
        guard tier == .free else { return }

        let elapsed = Date().timeIntervalSince(lastConsumeDate)
        guard elapsed >= refillInterval else { return }

        let refillCount = Int(elapsed / refillInterval)
        guard refillCount > 0 else { return }

        remainingMessagesToday = min(
            remainingMessagesToday + refillCount,
            dailyMessageLimit
        )

        storedRemainingMessages = remainingMessagesToday
        lastConsumeDate = lastConsumeDate.addingTimeInterval(
            TimeInterval(refillCount) * refillInterval
        )
    }

    var nextRefillDate: Date {
        lastConsumeDate.addingTimeInterval(refillInterval)
    }

    // MARK: - Persistence Helpers
    private var storedRemainingMessages: Int {
        get { UserDefaults.standard.integer(forKey: remainingKey) }
        set { UserDefaults.standard.set(newValue, forKey: remainingKey) }
    }

    private var lastConsumeDate: Date {
        get { UserDefaults.standard.object(forKey: lastConsumeKey) as? Date ?? .distantPast }
        set { UserDefaults.standard.set(newValue, forKey: lastConsumeKey) }
    }

    private var isInitialized: Bool {
        get { UserDefaults.standard.bool(forKey: initializedKey) }
        set { UserDefaults.standard.set(newValue, forKey: initializedKey) }
    }

    // MARK: - Vision
    var canUseVision: Bool {
        allowedModes().contains { $0.id == "image" }
    }

    func allowedModes() -> [KhioneMode] {
        switch plan.allowedModes {
        case .all:
            return allModes
        case .list(let ids):
            return allModes.filter { ids.contains($0.id) }
        }
    }
    // MARK: - StoreKit Proxies (UI-safe)

    // SubscriptionManager.swift
    var activeProduct: Product? {
        guard let id = tier.productID else { return nil }
        return storeKit.product(for: id)
    }

    func product(for tier: SubscriptionTier) -> Product? {
        guard let id = tier.productID else { return nil }
        return storeKit.product(for: id)
    }
}
