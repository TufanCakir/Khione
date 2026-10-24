//
//  SubscriptionManager.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    private(set) var activePlanID = "free"
    private(set) var isRefreshing = false

    private let catalog: SubscriptionCatalog
    private let defaults: UserDefaults

    init(
        catalog: SubscriptionCatalog? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.catalog = catalog ?? Bundle.main.loadSubscriptionCatalog()
        self.defaults = defaults
    }

    var activePlan: SubscriptionPlan {
        catalog.plan(id: activePlanID)
    }

    func monitorTransactions() async {
        await refreshEntitlements()

        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }

            if case .verified(let transaction) = result {
                await transaction.finish()
            }

            await refreshEntitlements()
        }
    }

    func refreshEntitlements() async {
        isRefreshing = true
        defer { isRefreshing = false }

        var entitledProductIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate,
                expirationDate <= Date()
            {
                continue
            }

            entitledProductIDs.insert(transaction.productID)
        }

        // SubscriptionStoreView and Transaction.currentEntitlements can update at
        // slightly different times after a purchase. Reading the subscription-group
        // status as well makes the unlock deterministic, including during grace period.
        let products =
            (try? await Product.products(
                for: catalog.subscriptionProductIDs
            )) ?? []

        for product in products {
            guard let subscription = product.subscription,
                let statuses = try? await subscription.status
            else { continue }

            for status in statuses
            where status.state == .subscribed
                || status.state == .inGracePeriod
            {
                guard case .verified(let transaction) = status.transaction
                else {
                    continue
                }
                entitledProductIDs.insert(transaction.productID)
            }
        }

        setActivePlanID(catalog.planID(for: entitledProductIDs))
    }

    private func setActivePlanID(_ planID: String) {
        activePlanID = planID
        defaults.set(planID, forKey: DefaultsKey.activeSubscriptionPlanID)
    }
}
