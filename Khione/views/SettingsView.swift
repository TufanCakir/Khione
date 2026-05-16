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
            languageSection
            themeSection
            accessibilitySection
            aboutSection
        }
        .navigationTitle(settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.locale, Locale(identifier: language))
    }
}

extension SettingsView {

    fileprivate var settingsTitle: String {
        language == "de" ? "Einstellungen" : "Settings"
    }

    fileprivate var themeTitle: String {
        language == "de" ? "Design" : "Theme"
    }

    fileprivate var accessibilityTitle: String {
        language == "de" ? "Bedienungshilfen" : "Accessibility"
    }

    fileprivate var shouldReduceMotion: Bool {
        reduceMotion || reduceAnimations
    }

    fileprivate var profileSection: some View {
        Section(text.title) {
            HStack(spacing: 14) {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(initials)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                TextField(text.profileNamePlaceholder, text: $username)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel(profileNameLabel)
            }
            .padding(.vertical, 4)
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
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: theme.icon)
                            .font(.title3)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(
                                theme.id == themeManager.selectedTheme.id
                                    ? themeManager.accentColor : .secondary
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.name)
                                .foregroundStyle(.primary)

                            Text(themeDescription(theme))
                                .font(.caption)
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

            Label(Bundle.main.appVersionString, systemImage: "number")
            Label(text.builtWith, systemImage: "applelogo")
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

            Toggle(isOn: $largeChatText) {
                Label(largeChatTextTitle, systemImage: "textformat.size")
            }
            .accessibilityHint(largeChatTextHint)

            Toggle(isOn: $reduceAnimations) {
                Label(reduceAnimationsTitle, systemImage: "figure.walk.motion")
            }
            .accessibilityHint(reduceAnimationsHint)

            Toggle(isOn: $alwaysShowSendButton) {
                Label(alwaysShowSendButtonTitle, systemImage: "arrow.up.circle")
            }
            .accessibilityHint(alwaysShowSendButtonHint)
        }
    }

    fileprivate func themeDescription(_ theme: AppTheme) -> String {
        switch theme.preferredScheme {
        case "system":
            return language == "de" ? "Folgt dem System" : "Follows system"
        case "light":
            return language == "de" ? "Heller Modus" : "Light mode"
        case "dark":
            return language == "de" ? "Dunkler Modus" : "Dark mode"
        default:
            return language == "de" ? "Standard" : "Default"
        }
    }

    fileprivate var profileNameLabel: String {
        language == "de" ? "Profilname" : "Profile name"
    }

    fileprivate var languageHint: String {
        language == "de"
            ? "Ändert die Sprache der App."
            : "Changes the app language."
    }

    fileprivate var themeHint: String {
        language == "de"
            ? "Ändert das Erscheinungsbild der App."
            : "Changes the app appearance."
    }

    fileprivate func themeAccessibilityValue(_ theme: AppTheme) -> String {
        guard theme.id == themeManager.selectedTheme.id else {
            return themeDescription(theme)
        }

        let selected = language == "de" ? "Ausgewählt" : "Selected"
        return "\(selected), \(themeDescription(theme))"
    }

    fileprivate var compactModeTitle: String {
        language == "de" ? "Kompakter Modus" : "Compact mode"
    }

    fileprivate var compactModeHint: String {
        language == "de"
            ? "Verringert Abstände im Chat."
            : "Reduces spacing in the chat."
    }

    fileprivate var largeChatTextTitle: String {
        language == "de" ? "Größere Chat-Schrift" : "Larger chat text"
    }

    fileprivate var largeChatTextHint: String {
        language == "de"
            ? "Vergrößert Nachrichten und Eingabe im Chat."
            : "Increases message and input text in chat."
    }

    fileprivate var reduceAnimationsTitle: String {
        language == "de" ? "Animationen reduzieren" : "Reduce animations"
    }

    fileprivate var reduceAnimationsHint: String {
        language == "de"
            ? "Reduziert Bewegungen zusätzlich zur Systemeinstellung."
            : "Reduces motion in addition to the system setting."
    }

    fileprivate var alwaysShowSendButtonTitle: String {
        language == "de"
            ? "Sendebutton immer anzeigen" : "Always show send button"
    }

    fileprivate var alwaysShowSendButtonHint: String {
        language == "de"
            ? "Zeigt den Sendebutton auch bei leerer Eingabe deaktiviert an."
            : "Shows the send button disabled even when the input is empty."
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            SettingsView()
        }
    }
}
