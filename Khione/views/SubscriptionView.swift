//
//  SubscriptionView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    private let text = Bundle.main.loadSubscriptionLocalization()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                header

                plansCarousel

                restoreButton
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Header
private extension SubscriptionView {

    var header: some View {
        VStack(spacing: 8) {
            Text(text.title)
                .font(.largeTitle.bold())

            Text(text.subtitle)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Plans
private extension SubscriptionView {

    var plansCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(subscription.plans) { plan in
                    subscriptionCard(plan)
                        .frame(width: 260)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func subscriptionCard(_ plan: SubscriptionPlan) -> some View {
        let tier = SubscriptionTier(rawValue: plan.id)
        let isActive = tier == subscription.tier

        VStack(spacing: 14) {

            // Title
            Text(plan.name)
                .font(.title2.bold())

            // Price
            Text(priceText(for: tier))
                .foregroundColor(.secondary)

            // Features
            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.features, id: \.self) {
                    Text("• \($0)")
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Action
            if isActive {
                Label(text.active, systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .padding(.top, 6)
            } else {
                subscribeButton(for: tier)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isActive ? Color.accentColor : .clear, lineWidth: 2)
        )
    }
}

// MARK: - Buttons
private extension SubscriptionView {

    func subscribeButton(for tier: SubscriptionTier?) -> some View {
        Button(text.subscribe) {
            Task {
                await purchase(tier)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(tier?.productID == nil)
    }

    var restoreButton: some View {
        Button(text.restore) {
            Task {
                await subscription.syncWithStoreKit()
                dismiss()
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }
}

// MARK: - Helpers
private extension SubscriptionView {

    func priceText(for tier: SubscriptionTier?) -> String {
        guard let tier else { return "—" }
        return subscription.price(for: tier)
    }

    func purchase(_ tier: SubscriptionTier?) async {
        guard
            let tier,
            let productID = tier.productID,
            let product = storeKit.product(for: productID)
        else { return }

        do {
            try await storeKit.purchase(product)
            await subscription.syncWithStoreKit()
            dismiss()
        } catch {
            print("❌ Purchase failed:", error)
        }
    }
}


#Preview {
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)
    
    SubscriptionView()
        .environmentObject(storeKit)
        .environmentObject(subscription)
} 
