//
//  AccountView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

struct AccountView: View {

    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var subscription: SubscriptionManager

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
            themeManager.backgroundColor.ignoresSafeArea()

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
    }

    @ViewBuilder
    private var profileSection: some View {
        Section {
            VStack(spacing: 12) {

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )

                TextField(text.profile_name_placeholder, text: $username)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)

                Text(text.profile_local)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var languageSection: some View {
        Section(text.language_section) {
            Picker(text.language_picker, selection: $language) {
                Text(text.language_de).tag("de")
                Text(text.language_en).tag("en")
            }
            .pickerStyle(.segmented)
            .onChange(of: language) {
                subscription.reloadPlans()
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        Section(text.subscription_section) {

            HStack {
                Label(text.current_plan, systemImage: "crown")
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
                        : text.manage_subscription,
                    systemImage: "eurosign.circle"
                )
            }

            if subscription.tier != .free {
                Label(text.active_subscription, systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
        }
    }

    @ViewBuilder
    private var appSection: some View {
        Section(text.app_section) {
            NavigationLink {
                AppearanceView()
            } label: {
                Label(text.appearance, systemImage: "moon")
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section(text.about_section) {
            Label("Khione", systemImage: "sparkles")
            Label(text.version, systemImage: "number")
            Label(text.built_with, systemImage: "applelogo")

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

