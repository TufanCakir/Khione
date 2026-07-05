//
//  SubscriptionCatalog.swift
//  Khione
//
//  Created by Tufan Cakir on 05.07.26.
//

import Foundation

struct SubscriptionCatalog: Decodable {
    let subscriptionGroupID: String
    let plans: [SubscriptionPlan]
    let oneTimePurchases: [OneTimePurchase]

    var paidProductIDs: [String] {
        plans.compactMap(\.productID) + oneTimePurchases.map(\.productID)
    }

    enum CodingKeys: String, CodingKey {
        case subscriptionGroupID = "subscription_group_id"
        case plans
        case oneTimePurchases = "one_time_purchases"
    }

    func plan(id: String?) -> SubscriptionPlan {
        plans.first { $0.id == id }
            ?? plans.first { $0.id == "standard" }
            ?? .fallbackStandard
    }

    static func activePlan(
        defaults: UserDefaults = .standard,
        catalog: SubscriptionCatalog = Bundle.main.loadSubscriptionCatalog()
    ) -> SubscriptionPlan {
        catalog.plan(
            id: defaults.string(forKey: DefaultsKey.activeSubscriptionPlanID)
        )
    }
}

enum DefaultsKey {
    static let activeSubscriptionPlanID = "active_subscription_plan_id"
}

struct SubscriptionPlan: Identifiable, Decodable {
    let id: String
    let kind: SubscriptionProductKind
    let productID: String?
    let title: LocalizedPlanText
    let subtitle: LocalizedPlanText
    let badge: LocalizedPlanText?
    let limits: SubscriptionLimits
    let features: LocalizedPlanList

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case productID = "product_id"
        case title
        case subtitle
        case badge
        case limits
        case features
    }
}

extension SubscriptionPlan {
    static let fallbackStandard = SubscriptionPlan(
        id: "standard",
        kind: .free,
        productID: nil,
        title: LocalizedPlanText(de: "Standard", en: "Standard"),
        subtitle: LocalizedPlanText(de: "Kostenlos", en: "Free"),
        badge: nil,
        limits: SubscriptionLimits(
            dailyChatLimit: 25,
            historyMessages: 0,
            canSendImages: false,
            canUseImageMode: false,
            canUseVoiceInput: false,
            canUseReplyStyles: false
        ),
        features: LocalizedPlanList(de: [], en: [])
    )
}

struct OneTimePurchase: Identifiable, Decodable {
    let id: String
    let kind: SubscriptionProductKind
    let productID: String
    let unlocksPlanID: String
    let title: LocalizedPlanText
    let subtitle: LocalizedPlanText
    let features: LocalizedPlanList

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case productID = "product_id"
        case unlocksPlanID = "unlocks_plan_id"
        case title
        case subtitle
        case features
    }
}

enum SubscriptionProductKind: String, Decodable {
    case free
    case autoRenewable = "auto_renewable"
    case nonConsumable = "non_consumable"
}

struct SubscriptionLimits: Decodable {
    let dailyChatLimit: Int?
    let historyMessages: Int
    let canSendImages: Bool
    let canUseImageMode: Bool
    let canUseVoiceInput: Bool
    let canUseReplyStyles: Bool

    enum CodingKeys: String, CodingKey {
        case dailyChatLimit = "daily_chat_limit"
        case historyMessages = "history_messages"
        case canSendImages = "can_send_images"
        case canUseImageMode = "can_use_image_mode"
        case canUseVoiceInput = "can_use_voice_input"
        case canUseReplyStyles = "can_use_reply_styles"
    }
}

struct LocalizedPlanText: Decodable {
    let de: String
    let en: String

    func value(language: String) -> String {
        language == "de" ? de : en
    }
}

struct LocalizedPlanList: Decodable {
    let de: [String]
    let en: [String]

    func value(language: String) -> [String] {
        language == "de" ? de : en
    }
}

extension SubscriptionCatalog {
    static let fallback = SubscriptionCatalog(
        subscriptionGroupID: "group.khione.membership",
        plans: [],
        oneTimePurchases: []
    )
}

extension Bundle {
    func loadSubscriptionCatalog() -> SubscriptionCatalog {
        if let cached = SubscriptionCatalogCache.value {
            return cached
        }

        guard
            let url = url(
                forResource: "subscription_plans",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(
                SubscriptionCatalog.self,
                from: data
            )
        else {
            return .fallback
        }

        SubscriptionCatalogCache.value = catalog
        return catalog
    }
}

private enum SubscriptionCatalogCache {
    static var value: SubscriptionCatalog?
}
