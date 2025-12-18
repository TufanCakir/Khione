//
//  SubscriptionView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let text = Bundle.main.loadSubscriptionLocalization()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                header
                plansCarousel
                restoreButton

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .disabled(isPurchasing)
    }
}

extension SubscriptionView {

    fileprivate var header: some View {
        VStack(spacing: 8) {
            Text(text.title)
                .font(.largeTitle.bold())

            Text(text.subtitle)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

extension SubscriptionView {

    fileprivate var plansCarousel: some View {
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
    fileprivate func subscriptionCard(_ plan: SubscriptionPlan) -> some View {
        let tier = SubscriptionTier(rawValue: plan.id) ?? .free
        let isActive = tier == subscription.tier
        let product = subscription.product(for: tier)

        VStack(spacing: 14) {

            Text(plan.name)
                .font(.title2.bold())

            if let product {
                VStack(spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline)

                    if let period = product.subscription?.subscriptionPeriod {
                        Text(period.displayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Free")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.features, id: \.self) {
                    Text("• \($0)")
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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

extension SubscriptionView {

    fileprivate func subscribeButton(for tier: SubscriptionTier) -> some View {
        Button(text.subscribe) {
            Task { await purchase(tier) }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isPurchasing || tier.productID == nil)
    }

    fileprivate var restoreButton: some View {
        Button(text.restore) {
            Task {
                await subscription.syncWithStoreKit()
                dismiss()
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }

    fileprivate func purchase(_ tier: SubscriptionTier) async {
        guard
            let productID = tier.productID,
            let product = storeKit.product(for: productID)
        else { return }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            try await storeKit.purchase(product)
            await subscription.syncWithStoreKit()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
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
