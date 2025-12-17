import AppIntents

enum KhioneModeIntent: String, AppEnum {
    case chat, tutor, writer, decision, polite, strict, accessibility

    static var typeDisplayRepresentation =
        TypeDisplayRepresentation(name: "Khione Mode")

    static var caseDisplayRepresentations: [KhioneModeIntent: DisplayRepresentation] = [
        .chat: "Chat",
        .tutor: "Tutor",
        .writer: "Writer",
        .decision: "Decision",
        .polite: "Polite",
        .strict: "Strict",
        .accessibility: "Accessibility"
    ]
}

struct OpenKhioneIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Khione"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult { .result() }
}

struct OpenKhioneModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Khione Mode"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Mode")
    var mode: KhioneModeIntent

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(mode.rawValue, forKey: "khione_start_mode")
        return .result()
    }
}
