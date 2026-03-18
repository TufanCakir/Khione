//
//  AccountView.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct AccountView: View {

    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager

    // MARK: - Storage
    @AppStorage("username") private var username = ""
    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    // MARK: - Localization
    private var text: AccountLocalization {
        Bundle.main.loadAccountLocalization(language: language)
    }

    // MARK: - Computed
    private var initials: String {
        let letters =
            username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        return letters.isEmpty
            ? "Name" : letters.map { String($0).uppercased() }.joined()
    }

    // MARK: - Body
    var body: some View {
        Form {
            profileSection
            languageSection
            appSection
            aboutSection
        }
        .environment(\.locale, Locale(identifier: language))
        .scrollDismissesKeyboard(.interactively)
    }
}

extension AccountView {
    private var profileSection: some View {
        Section {
            VStack(spacing: 12) {

                Circle()
                    .fill(.tint)
                    .frame(width: 100, height: 100)
                    .overlay {
                        Text(initials)
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                HStack(spacing: 10) {
                    Image(systemName: "person")
                        .foregroundStyle(.secondary)

                    TextField(text.profileNamePlaceholder, text: $username)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                Text(text.profileLocal)
            }
        }
    }

    private var languageSection: some View {
        Section(text.languageSection) {
            Picker(text.languagePicker, selection: $language) {
                Text(text.languageDE).tag("de")
                Text(text.languageEN).tag("en")
            }
        }
    }

    private var appSection: some View {
        Section(text.appSection) {
            NavigationLink {
                AppearanceView()
            } label: {
                Label(text.appearance, systemImage: "moon")
            }
        }
    }

    private var aboutSection: some View {
        Section(text.aboutSection) {
            NavigationLink {
                InfoView()
            } label: {
                Label("Khione", systemImage: "snowflake")
            }

            Label(Bundle.main.appVersionString, systemImage: "number")

            Label(text.builtWith, systemImage: "applelogo")
        }
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            AccountView()
        }
    }
}
