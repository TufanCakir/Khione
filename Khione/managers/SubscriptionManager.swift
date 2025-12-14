//
//  SubscriptionManager.swift
//  Khione
//

import Foundation
import StoreKit
import Combine
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var remainingMessagesToday: Int = 0
    @Published private(set) var plans: [SubscriptionPlan] = []

    @AppStorage("khione_language") private var language: String = "en"

    // MARK: - Refill System
    private let refillInterval: TimeInterval = 2 * 60 * 60 // 2 Stunden
    private let lastConsumeKey = "lastMessageConsumeDate"

    // MARK: - Dependencies
    private let storeKit: StoreKitManager
    // MARK: - Init
    init(storeKit: StoreKitManager) {
        self.storeKit = storeKit
        loadPlans()

        Task {
            await syncWithStoreKit()
        }
    }

    // MARK: - Plan Loading
    func loadPlans() {
        plans = Bundle.main.loadPlans(language: language)
    }


    // MARK: - Persistence
    private var lastConsumeDate: Date {
        get {
            UserDefaults.standard.object(forKey: lastConsumeKey) as? Date ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastConsumeKey)
        }
    }

    // MARK: - StoreKit Sync
    func syncWithStoreKit() async {
        tier = storeKit.activeTier

        if tier == .free {
            if remainingMessagesToday == 0 {
                remainingMessagesToday = dailyMessageLimit
            }
            refillMessagesIfNeeded()
        }
    }

    // MARK: - Refill Logic
    func refillMessagesIfNeeded() {
        guard tier == .free else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastConsumeDate)
        let refillCount = Int(elapsed / refillInterval)

        guard refillCount > 0 else { return }

        remainingMessagesToday = min(
            remainingMessagesToday + refillCount,
            dailyMessageLimit
        )

        lastConsumeDate = now
    }

    // MARK: - Consume Message
    func consumeMessageIfNeeded() {
        guard tier == .free else { return }

        refillMessagesIfNeeded()

        if remainingMessagesToday > 0 {
            remainingMessagesToday -= 1
            lastConsumeDate = Date()
        }
    }

    // MARK: - Limits
    var dailyMessageLimit: Int {
        plans.first { $0.id == tier }?.dailyMessageLimit ?? 0
    }

    // MARK: - Feature Flags
    var canUseProgrammingMode: Bool { tier != .free }
    var canUseUnlimitedChat: Bool { tier != .free }
    var canUseVision: Bool { tier == .vision }

    var canSendMessage: Bool {
        canUseUnlimitedChat || remainingMessagesToday > 0
    }

    // MARK: - Pricing
    func price(for tier: SubscriptionTier) -> String {
        storeKit.product(for: tier)?.displayPrice ?? "—"
    }

    // MARK: - UX Helper (optional, sehr empfohlen)
    var nextRefillIn: TimeInterval {
        let elapsed = Date().timeIntervalSince(lastConsumeDate)
        return max(refillInterval - elapsed, 0)
    }
} 
