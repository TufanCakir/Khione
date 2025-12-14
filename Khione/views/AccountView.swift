//
//  AccountView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

struct AccountView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var subscription: SubscriptionManager
    @AppStorage("khione_username") private var username: String = ""
    private let tosURL = URL(string: "https://khione-tos.netlify.app/")!
    private let privacyURL = URL(string: "https://khione-privacy.netlify.app/")!
    @AppStorage("khione_language") private var language: String = Locale.current.language.languageCode?.identifier ?? "en"
    private var text: AccountLocalization {
        Bundle.main.loadAccountLocalization(language: language)
    }


    private var initials: String {
        let parts = username.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0).uppercased() }.joined()
    }


    var body: some View {
        NavigationStack {
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
        }
        .environment(\.locale, Locale(identifier: language))
        }
    }


// MARK: - Sections
private extension AccountView {
    
    // 👤 PROFIL
    var profileSection: some View {
        Section {
            VStack(spacing: 12) {
                
                // Avatar
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(initials.isEmpty ? "?" : initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                // Name Input
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
    
    // 🌍 SPRACHE
    var languageSection: some View {
        Section(text.language_section) {
            Picker(text.language_picker, selection: $language) {
                Text(text.language_de).tag("de")
                Text(text.language_en).tag("en")
            }
            .pickerStyle(.segmented)
            .onChange(of: language) {
                subscription.loadPlans()   // ✅ Abo-Pläne neu laden
            }
        }
    }

    
    // 💳 ABO
    var subscriptionSection: some View {
        Section(text.subscription_section) {
            HStack {
                Label(text.current_plan, systemImage: "crown")
                Spacer()
                Text(subscription.tier.displayName)
                    .foregroundColor(.secondary)
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
    
    // ⚙️ APP
    var appSection: some View {
        Section(text.app_section) {
            NavigationLink {
                AppearanceView()
            } label: {
                Label(text.appearance, systemImage: "moon")
            }
        }
    }
    
    // ℹ️ ÜBER
    var aboutSection: some View {
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




// MARK: - Preview
#Preview {
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)

    AccountView()
        .environmentObject(themeManagerPreview)
        .environmentObject(subscription)
}

// MARK: - Preview Helper
private let themeManagerPreview: ThemeManager = {
    let tm = ThemeManager()
    return tm
}()
