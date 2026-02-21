//
//  AppShortcuts.swift
//  Khione
//
//  Created by Tufan Cakir on 21.02.26.
//

import AppIntents

struct AppShortcuts: AppShortcutsProvider {

    static var shortcutTileColor: ShortcutTileColor { .purple }

    @AppShortcutsBuilder static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenIntent(),
            phrases: [
                "Open ${applicationName}",
                "Start ${applicationName}",
                "Launch ${applicationName}",
            ],
            shortTitle: "Open Khione",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenModeIntent(mode: .chat),
            phrases: [
                "Open ${applicationName} chat",
                "Chat with ${applicationName}",
            ],
            shortTitle: "Khione Chat",
            systemImageName: "message"
        )

        AppShortcut(
            intent: OpenModeIntent(mode: .accessibility),
            phrases: [
                "Open ${applicationName} accessibility",
                "Use ${applicationName} with accessibility",
            ],
            shortTitle: "Khione Accessibility",
            systemImageName: "figure.roll"
        )
    }
}

// MARK: - Mode Enum

enum ModeIntent: String, AppEnum {
    case chat
    case accessibility

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Khione Mode")
    }

    static var caseDisplayRepresentations: [ModeIntent: DisplayRepresentation] {
        [
            .chat: "Chat",
            .accessibility: "Accessibility",
        ]
    }
}

// MARK: - Open App Intent

struct OpenIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Khione"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Open Mode Intent

struct OpenModeIntent: AppIntent {

    static var title: LocalizedStringResource =
        "Open Khione in a specific mode"

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Mode")
    var mode: ModeIntent

    init() {
        self.mode = .chat
    }

    init(mode: ModeIntent) {
        self.mode = mode
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(
            mode.rawValue,
            forKey: "start_mode"
        )
        return .result()
    }
}
