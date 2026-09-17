import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    private let productIDs =
        Bundle.main.loadSubscriptionCatalog().paidProductIDs

    var body: some View {
        StoreView(ids: productIDs)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)
            .productViewStyle(.regular)
            .navigationTitle("Plans & Purchases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            SubscriptionView()
        }
    }
}
