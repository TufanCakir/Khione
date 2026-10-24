//
//  SettingsView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("username") private var username = ""
    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"
    @AppStorage("accessibilityCompactMode") private var compactMode = true
    @AppStorage("accessibilityLargeChatText") private var largeChatText = false
    @AppStorage("accessibilityReduceAnimations")
    private var reduceAnimations = false
    @AppStorage("accessibilityAlwaysShowSendButton")
    private var alwaysShowSendButton = false

    private var text: AccountLocalization {
        Bundle.main.loadAccountLocalization(language: language)
    }

    private var initials: String {
        let letters =
            username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        return letters.isEmpty
            ? "KH"
            : letters.map { String($0).uppercased() }.joined()
    }

    var body: some View {
        Form {
            profileSection
            purchaseSection
            languageSection
            themeSection
            accessibilitySection
            aboutSection
        }
        .navigationTitle(settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }
}

extension SettingsView {

    fileprivate var settingsTitle: LocalizedStringResource { "Settings" }

    fileprivate var themeTitle: LocalizedStringResource { "Theme" }

    fileprivate var accessibilityTitle: LocalizedStringResource {
        "Accessibility"
    }

    fileprivate var shouldReduceMotion: Bool {
        reduceMotion || reduceAnimations
    }

    fileprivate var profileSection: some View {
        Section(text.title) {
            HStack(spacing: 12) {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Text(initials)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                TextField(text.profileNamePlaceholder, text: $username)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel(profileNameLabel)
            }
            .padding(.vertical, 2)
        }
    }

    fileprivate var languageSection: some View {
        Section(text.languageSection) {
            Picker(text.languagePicker, selection: $language) {
                Label(text.languageDE, systemImage: "character.book.closed")
                    .tag("de")
                Label(text.languageEN, systemImage: "textformat.abc")
                    .tag("en")
            }
            .pickerStyle(.palette)
            .controlSize(.regular)
            .accessibilityHint(languageHint)
        }
    }

    fileprivate var themeSection: some View {
        Section(themeTitle) {
            ForEach(themeManager.themes) { theme in
                Button {
                    withAnimation(
                        shouldReduceMotion ? nil : .easeInOut(duration: 0.2)
                    ) {
                        themeManager.selectTheme(theme)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: theme.icon)
                            .font(.body.weight(.semibold))
                            .frame(width: 26, height: 26)
                            .foregroundStyle(
                                theme.id == themeManager.selectedTheme.id
                                    ? themeManager.accentColor : .secondary
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.name)
                                .foregroundStyle(.primary)

                            Text(themeDescription(theme))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if theme.id == themeManager.selectedTheme.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(themeManager.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(theme.name)
                .accessibilityValue(themeAccessibilityValue(theme))
                .accessibilityHint(themeHint)
                .padding(.vertical, 1)
            }
        }
    }

    fileprivate var aboutSection: some View {
        Section(text.aboutSection) {
            NavigationLink {
                InfoView()
            } label: {
                Label("Khione", systemImage: "snowflake")
            }

            Link(
                destination: URL(
                    string:
                        "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                )!
            ) {
                Text("Terms of Use")
            }

            Label(Bundle.main.appVersionString, systemImage: "number")
        }
    }

    fileprivate var accessibilitySection: some View {
        Section(accessibilityTitle) {
            Toggle(isOn: $compactMode) {
                Label(
                    compactModeTitle,
                    systemImage: "rectangle.compress.vertical"
                )
            }
            .accessibilityHint(compactModeHint)
            .font(.body)

            Toggle(isOn: $largeChatText) {
                Label(largeChatTextTitle, systemImage: "textformat.size")
            }
            .accessibilityHint(largeChatTextHint)
            .font(.body)

            Toggle(isOn: $reduceAnimations) {
                Label(reduceAnimationsTitle, systemImage: "figure.walk.motion")
            }
            .accessibilityHint(reduceAnimationsHint)
            .font(.body)

            Toggle(isOn: $alwaysShowSendButton) {
                Label(alwaysShowSendButtonTitle, systemImage: "arrow.up.circle")
            }
            .accessibilityHint(alwaysShowSendButtonHint)
            .font(.body)
        }
    }

    fileprivate var purchaseSection: some View {
        Section("Plans") {
            NavigationLink {
                SubscriptionView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                        .frame(width: 26, height: 26)
                        .foregroundStyle(themeManager.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Khione Pro")
                        Text("Choose the plan that fits your work")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    fileprivate func themeDescription(
        _ theme: AppTheme
    ) -> LocalizedStringResource {
        switch theme.preferredScheme {
        case "system":
            return "Follows system"
        case "light":
            return "Light mode"
        case "dark":
            return "Dark mode"
        default:
            return "Default"
        }
    }

    fileprivate var profileNameLabel: LocalizedStringResource {
        "Profile name"
    }

    fileprivate var languageHint: LocalizedStringResource {
        "Changes the app language."
    }

    fileprivate var themeHint: LocalizedStringResource {
        "Changes the app appearance."
    }

    fileprivate func themeAccessibilityValue(_ theme: AppTheme) -> String {
        let locale = Locale(identifier: language)
        let description: String

        switch theme.preferredScheme {
        case "system":
            description = String(localized: "Follows system", locale: locale)
        case "light":
            description = String(localized: "Light mode", locale: locale)
        case "dark":
            description = String(localized: "Dark mode", locale: locale)
        default:
            description = String(localized: "Default", locale: locale)
        }

        guard theme.id == themeManager.selectedTheme.id else {
            return description
        }

        return String(
            localized: "Selected, \(description)",
            locale: locale,
            comment: "Accessibility value for the currently selected theme."
        )
    }

    fileprivate var compactModeTitle: LocalizedStringResource {
        "Compact mode"
    }

    fileprivate var compactModeHint: LocalizedStringResource {
        "Reduces spacing in the chat."
    }

    fileprivate var largeChatTextTitle: LocalizedStringResource {
        "Larger chat text"
    }

    fileprivate var largeChatTextHint: LocalizedStringResource {
        "Increases message and input text in chat."
    }

    fileprivate var reduceAnimationsTitle: LocalizedStringResource {
        "Reduce animations"
    }

    fileprivate var reduceAnimationsHint: LocalizedStringResource {
        "Reduces motion in addition to the system setting."
    }

    fileprivate var alwaysShowSendButtonTitle: LocalizedStringResource {
        "Always show send button"
    }

    fileprivate var alwaysShowSendButtonHint: LocalizedStringResource {
        "Shows the send button disabled even when the input is empty."
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            SettingsView()
        }
    }
}
