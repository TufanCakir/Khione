//
//  SubscriptionView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    private let catalog = Bundle.main.loadSubscriptionCatalog()

    var body: some View {
        SubscriptionStoreView(productIDs: catalog.subscriptionProductIDs) {
            KhioneProMarketingHeader()
        }
        .subscriptionStoreControlStyle(.pagedProminentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .redeemCode)
        .storeButton(.hidden, for: .cancellation)
        .tint(.blue)
        .containerBackground(for: .subscriptionStoreFullHeight) {
            KhioneProBackground()
        }
        .navigationTitle("Khione Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await subscriptionManager.refreshEntitlements()
        }
        .onDisappear {
            Task {
                await subscriptionManager.refreshEntitlements()
            }
        }
    }
}

private struct KhioneProMarketingHeader: View {
    var body: some View {
        VStack(spacing: 22) {
            KhioneProHero()
            KhioneProCategoryStrip()
            KhioneProValueCard()
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

private struct KhioneProHero: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "snowflake")
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text("Choose your Khione Pro")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(
                "Three clear plans for everyday questions, creative work, and demanding projects."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }
}

private struct KhioneProCategoryStrip: View {
    private let categories: [KhioneProCategory] = [
        KhioneProCategory(
            title: "Chat",
            detail: "Write and understand",
            systemImage: "bubble.left.and.bubble.right.fill"
        ),
        KhioneProCategory(
            title: "Vision",
            detail: "Work with images",
            systemImage: "viewfinder"
        ),
        KhioneProCategory(
            title: "Create",
            detail: "Turn ideas into results",
            systemImage: "sparkles"
        ),
    ]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    KhioneProCategoryCard(category: category)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 2, for: .scrollContent)
        .accessibilityLabel("Khione Pro feature categories")
    }
}

private struct KhioneProCategoryCard: View {
    let category: KhioneProCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.headline)
                Text(category.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 145, alignment: .leading)
        .frame(minHeight: 116, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

private struct KhioneProValueCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Included with Khione Pro")
                .font(.headline)

            KhioneProBenefit(
                title: "Private by design",
                systemImage: "lock.shield.fill"
            )
            KhioneProBenefit(
                title: "Voice, styles, and longer conversations",
                systemImage: "waveform"
            )
            KhioneProBenefit(
                title: "New capabilities added continuously",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
    }
}

private struct KhioneProBenefit: View {
    let title: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .font(.subheadline)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
        }
    }
}

private struct KhioneProBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.18),
                Color.indigo.opacity(0.08),
                Color.clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(Color(.systemBackground))
    }
}

private struct KhioneProCategory: Identifiable {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let systemImage: String

    var id: String { systemImage }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            SubscriptionView()
        }
    }
}
