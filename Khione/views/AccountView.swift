//
//  AccountView.swift
//  Khione
//

import SwiftUI

struct AccountView: View {

    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var subscription: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Storage
    @AppStorage("khione_username") private var username = ""
    @AppStorage("khione_language")
    private var language: String =
        Locale.current.language.languageCode?.identifier ?? "en"

    // MARK: - Links
    private let tosURL = URL(string: "https://khione-tos.netlify.app/")!
    private let privacyURL = URL(string: "https://khione-privacy.netlify.app/")!

    // MARK: - Localization
    private var text: AccountLocalization {
        Bundle.main.loadAccountLocalization(language: language)
    }

    // MARK: - Helpers
    private var initials: String {
        let parts = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")

        let letters = parts.prefix(2).compactMap(\.first)
        return letters.isEmpty
            ? "?"
            : letters.map { String($0).uppercased() }.joined()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()

            List {
                profileSection
                subscriptionSection
                languageSection
                appSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(text.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: language))
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    UIApplication.shared.dismissKeyboard()
                }
            }
        }
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
                    .accessibilityHidden(true)

                TextField(text.profileNamePlaceholder, text: $username)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .submitLabel(.done)

                Text(text.profileLocal)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
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
}

private extension AccountView {

    var subscriptionSection: some View {
        Section(text.subscriptionSection) {

            HStack {
                Label(text.currentPlan, systemImage: "crown")
                Spacer()

                Text(subscription.tier.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            subscription.tier == .free
                            ? Color.secondary.opacity(0.15)
                            : Color.accentColor.opacity(0.15)
                        )
                    )
            }

            NavigationLink {
                SubscriptionView()
            } label: {
                Label(
                    subscription.tier == .free
                        ? text.upgrade
                        : text.manageSubscription,
                    systemImage: "eurosign.circle"
                )
            }

            if subscription.tier != .free {
                Label(text.activeSubscription, systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

private extension AccountView {

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
            Label("Khione", systemImage: "sparkles")
            Label(text.version, systemImage: "number")
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


#Preview {
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)

    NavigationStack {
        AccountView()
            .environmentObject(ThemeManager())
            .environmentObject(subscription)
    }
}

