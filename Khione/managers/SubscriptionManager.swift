//
//  SubscriptionManager.swift
//  Khione
//

import Foundation
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

    // MARK: - Language (State only, NOT used in init)
    @AppStorage("khione_language") private var language: String = "en"

    // MARK: - Init
    init(storeKit: StoreKitManager) {
        self.storeKit = storeKit

        // ✅ SAFE: AppStorage NICHT verwenden
        let initialLanguage =
            UserDefaults.standard.string(forKey: "khione_language") ?? "en"

        let loadedPlans = Bundle.main.loadPlans(language: initialLanguage)
        self.plans = loadedPlans
        self.plan = loadedPlans.first { $0.id == "free" }!

        Task { await syncWithStoreKit() }
    }

    // MARK: - Reload when language changes
    func reloadPlans() {
        let loadedPlans = Bundle.main.loadPlans(language: language)
        plans = loadedPlans

        if let active = loadedPlans.first(where: { $0.id == tier.rawValue }) {
            plan = active
        } else if let free = loadedPlans.first(where: { $0.id == "free" }) {
            plan = free
        }
    }

    // MARK: - StoreKit
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

    // MARK: - Allowed Modes
    func allowedModes() -> [KhioneMode] {
        switch plan.allowedModes {
        case .all:
            return allModes
        case .list(let ids):
            return allModes.filter { ids.contains($0.id) }
        }
    }

    // MARK: - Vision
    var canUseVision: Bool {
        allowedModes().contains { $0.id == "image" }
    }

    // MARK: - Messaging
    var canSendMessage: Bool {
        tier != .free || remainingMessagesToday > 0
    }

    func consumeMessageIfNeeded() {
        guard tier == .free else { return }
        refillMessagesIfNeeded()
        guard remainingMessagesToday > 0 else { return }

        remainingMessagesToday -= 1
        lastConsumeDate = Date()
    }

    var dailyMessageLimit: Int {
        plan.dailyMessageLimit
    }

    // MARK: - Pricing
    func price(for tier: SubscriptionTier) -> String {
        guard let productID = tier.productID else { return "—" }
        return storeKit.product(for: productID)?.displayPrice ?? "—"
    }

    // MARK: - Refill System
    private let refillInterval: TimeInterval = 2 * 60 * 60
    private let lastConsumeKey = "lastMessageConsumeDate"
    private let initializedKey = "freeTierInitialized"

    private func initializeFreeIfNeeded() {
        guard tier == .free, !isInitialized else { return }
        remainingMessagesToday = dailyMessageLimit
        lastConsumeDate = Date()
        isInitialized = true
    }

    private func refillMessagesIfNeeded() {
        guard tier == .free else { return }

        let elapsed = Date().timeIntervalSince(lastConsumeDate)
        let refillCount = Int(elapsed / refillInterval)
        guard refillCount > 0 else { return }

        remainingMessagesToday = min(
            remainingMessagesToday + refillCount,
            dailyMessageLimit
        )

        lastConsumeDate = lastConsumeDate.addingTimeInterval(
            TimeInterval(refillCount) * refillInterval
        )
    }

    var nextRefillDate: Date {
        lastConsumeDate.addingTimeInterval(refillInterval)
    }

    private var lastConsumeDate: Date {
        get { UserDefaults.standard.object(forKey: lastConsumeKey) as? Date ?? .distantPast }
        set { UserDefaults.standard.set(newValue, forKey: lastConsumeKey) }
    }

    private var isInitialized: Bool {
        get { UserDefaults.standard.bool(forKey: initializedKey) }
        set { UserDefaults.standard.set(newValue, forKey: initializedKey) }
    }
}
