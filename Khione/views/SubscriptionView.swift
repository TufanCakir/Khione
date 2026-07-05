//
//  SubscriptionView.swift
//  Khione
//
//  Created by Tufan Cakir on 05.07.26.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("language") private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private let catalog = Bundle.main.loadSubscriptionCatalog()

    private var isGerman: Bool { language == "de" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                planGrid
                storeSection
                note
            }
            .padding(20)
        }
        .navigationTitle(isGerman ? "Abo & Käufe" : "Plans & Purchases")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isGerman ? "Fertig" : "Done") {
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                isGerman
                    ? "Wähle, wie du Khione nutzt."
                    : "Choose how you use Khione."
            )
            .font(.title2.weight(.semibold))

            Text(
                isGerman
                    ? "Limits und Funktionen kommen aus JSON. Preise und Käufe werden später über den Store geladen."
                    : "Limits and features come from JSON. Prices and purchases load from the store later."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var planGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 250), spacing: 12)],
            spacing: 12
        ) {
            ForEach(catalog.plans) { plan in
                SubscriptionPlanCard(plan: plan, language: language)
            }

            ForEach(catalog.oneTimePurchases) { purchase in
                OneTimePurchaseCard(purchase: purchase, language: language)
            }
        }
    }

    @ViewBuilder
    private var storeSection: some View {
        if !catalog.paidProductIDs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(isGerman ? "Kaufen" : "Purchase")
                    .font(.headline)

                StoreView(ids: catalog.paidProductIDs)
                    .storeButton(.visible, for: .restorePurchases)
                    .storeButton(.hidden, for: .cancellation)
                    .productViewStyle(.compact)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link(
                isGerman ? "Nutzungsbedingungen" : "Terms of Use",
                destination: URL(
                    string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                )!
            )

            Text(
                isGerman
                    ? "Hinweis: Product-IDs müssen in App Store Connect oder einer StoreKit-Testkonfiguration exakt gleich angelegt werden."
                    : "Note: Product IDs must match App Store Connect or a StoreKit test configuration exactly."
            )
            .foregroundStyle(.secondary)
        }
        .font(.footnote)
    }
}

private struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title.value(language: language))
                        .font(.headline)
                    Text(plan.subtitle.value(language: language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let badge = plan.badge {
                    Text(badge.value(language: language))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            limits

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features.value(language: language), id: \.self) {
                    feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var limits: some View {
        HStack(spacing: 8) {
            LimitPill(text: chatLimitText)
            LimitPill(
                text: plan.limits.canSendImages
                    ? imageAllowedText : imageBlockedText
            )
        }
    }

    private var chatLimitText: String {
        if let limit = plan.limits.dailyChatLimit {
            return language == "de" ? "\(limit)/Tag" : "\(limit)/day"
        }

        return language == "de" ? "Unbegrenzt" : "Unlimited"
    }

    private var imageAllowedText: String {
        language == "de" ? "Bilder" : "Images"
    }

    private var imageBlockedText: String {
        language == "de" ? "Keine Bilder" : "No images"
    }
}

private struct OneTimePurchaseCard: View {
    let purchase: OneTimePurchase
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.title.value(language: language))
                        .font(.headline)
                    Text(purchase.subtitle.value(language: language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "infinity.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(purchase.features.value(language: language), id: \.self)
                { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct LimitPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: Capsule())
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            SubscriptionView()
        }
    }
}
