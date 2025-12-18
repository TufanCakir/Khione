//
//  AccountView.swift
//  Khione
//

import SwiftUI
import StoreKit

struct AccountView: View {

    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var subscription: SubscriptionManager

    // MARK: - Storage
    @AppStorage("khione_username") private var username = ""
    @AppStorage("khione_language")
    private var language = Locale.current.language.languageCode?.identifier ?? "en"

    // MARK: - Links
    private let tosURL = URL(string: "https://khione-tos.netlify.app/")!
    private let privacyURL = URL(string: "https://khione-privacy.netlify.app/")!

    // MARK: - Localization
    private var text: AccountLocalization {
        Bundle.main.loadAccountLocalization(language: language)
    }

    // MARK: - Computed
    private var initials: String {
        let letters = username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        return letters.isEmpty ? "?" : letters.map { String($0).uppercased() }.joined()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()

            List {
                profileSection
                subscriptionSection
                languageSection
                appSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(text.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: language))
    }
}

private extension AccountView {

    var profileSection: some View {
        Section {
            VStack(spacing: 14) {

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                    .accessibilityLabel("User avatar")

                TextField(text.profileNamePlaceholder, text: $username)
                    .submitLabel(.done)


                Text(text.profileLocal)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
    }
}

private extension AccountView {

    var subscriptionSection: some View {
        Section(text.subscriptionSection) {
            VStack(spacing: 16) {

                headerRow
                Divider().opacity(0.4)
                infoRow
                subscriptionAction
                activeBadge
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.vertical, 6)
        }
    }

    var headerRow: some View {
        HStack {
            Label(text.currentPlan, systemImage: "crown")
                .font(.subheadline.weight(.medium))
            Spacer()
            planBadge
        }
    }

    var infoRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.secondary)

            Text(text.subscriptionInfo)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    var subscriptionAction: some View {
        NavigationLink {
            ViewFactory.view(for: .subscription)
        } label: {
            Label(
                subscription.tier == .free ? text.upgrade : text.manageSubscription,
                systemImage: "eurosign.circle.fill"
            )
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    var activeBadge: some View {
        if subscription.tier != .free {
            Label(text.activeSubscription, systemImage: "checkmark.seal.fill")
                .font(.footnote.weight(.medium))
                .foregroundColor(.green)
        }
    }
}

private extension AccountView {

    @ViewBuilder
    var planBadge: some View {
        switch subscription.tier {
        case .free:
            VStack(alignment: .trailing, spacing: 2) {
                Text("Free").badgeStyle()
                Label("Upgrade available", systemImage: "arrow.up.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        default:
            if let product = subscription.activeProduct {
                priceBadge(product)
            }
        }
    }

    func priceBadge(_ product: Product) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(product.displayPrice)
                .font(.caption.bold())

            if let period = product.subscription?.subscriptionPeriod {
                Text(period.displayText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.accentColor.opacity(0.18)))
    }
}

private extension AccountView {

    var languageSection: some View {
        Section(text.languageSection) {
            Picker(text.languagePicker, selection: $language) {
                Text(text.languageDE).tag("de")
                Text(text.languageEN).tag("en")
            }
            .pickerStyle(.segmented)
            .onChange(of: language) { _, _ in
                subscription.reloadPlans()
            }
        }
    }

    var appSection: some View {
        Section(text.appSection) {
            NavigationLink {
                AppearanceView()
            } label: {
                Label(text.appearance, systemImage: "moon")
            }
        }
    }

    var aboutSection: some View {
        Section(text.aboutSection) {
            NavigationLink {
                KhioneInfoView()
            } label: {
                Label("Khione", systemImage: "snowflake")
            }

            
            Label(Bundle.main.appVersionString, systemImage: "number")
                .foregroundColor(.secondary)
            Label(text.builtWith, systemImage: "applelogo")

            Link(destination: tosURL) {
                Label(text.tos, systemImage: "doc.text")
            }

            Link(destination: privacyURL) {
                Label(text.privacy, systemImage: "hand.raised")
            }
        }
    }
}

private extension View {
    func badgeStyle() -> some View {
        self
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.secondary.opacity(0.15)))
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
extension Bundle {
    var appVersionString: String {
        let version =
            infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"

        let build =
            infoDictionary?["CFBundleVersion"] as? String ?? ""

        if build.isEmpty {
            return "Version \(version)"
        } else {
            return "Version \(version) (\(build))"
        }
    }
}


#Preview {
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)

    NavigationStack {
        AccountView()
            .environmentObject(ThemeManager())
            .environmentObject(subscription)
    }
}

