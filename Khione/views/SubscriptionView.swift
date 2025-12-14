//
//  SubscriptionView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {

    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    private let text = Bundle.main.loadSubscriptionLocalization()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                Text(text.title)
                    .font(.largeTitle.bold())

                Text(text.subtitle)
                    .foregroundColor(.secondary)

                ForEach(subscription.plans) { plan in
                    subscriptionCard(plan)
                }

                Button(text.restore) {
                    Task {
                        await subscription.syncWithStoreKit()
                        dismiss()
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func subscriptionCard(_ plan: SubscriptionPlan) -> some View {
        VStack(spacing: 12) {

            Text(plan.name)
                .font(.title2.bold())

            if let tier = SubscriptionTier(rawValue: plan.id) {
                Text(subscription.price(for: tier))
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .foregroundColor(.secondary)
            }

            ForEach(plan.features, id: \.self) {
                Text("• \($0)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(text.subscribe) {
                Task {
                    if let tier = SubscriptionTier(rawValue: plan.id),
                       let productID = tier.productID,
                       let product = storeKit.products.first(where: { $0.id == productID }) {

                        try? await storeKit.purchase(product)
                        await subscription.syncWithStoreKit()
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

}
