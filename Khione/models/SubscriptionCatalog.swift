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

    var subscriptionProductIDs: [String] {
        plans.flatMap(\.productIDs)
    }

    enum CodingKeys: String, CodingKey {
        case subscriptionGroupID = "subscription_group_id"
        case plans
    }

    func plan(id: String?) -> SubscriptionPlan {
        plans.first { $0.id == id }
            ?? plans.first { $0.id == "free" }
            ?? .fallbackFree
    }

    func planID(for entitledProductIDs: Set<String>) -> String {
        plans.reversed().first { plan in
            !entitledProductIDs.isDisjoint(with: plan.productIDs)
        }?.id ?? "free"
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
    let productIDs: [String]
    let title: LocalizedPlanText
    let subtitle: LocalizedPlanText
    let badge: LocalizedPlanText?
    let limits: SubscriptionLimits
    let features: LocalizedPlanList

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case productIDs = "product_ids"
        case title
        case subtitle
        case badge
        case limits
        case features
    }
}

extension SubscriptionPlan {
    static let fallbackFree = SubscriptionPlan(
        id: "free",
        kind: .free,
        productIDs: [],
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

enum SubscriptionProductKind: String, Decodable {
    case free
    case autoRenewable = "auto_renewable"
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
        plans: []
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
