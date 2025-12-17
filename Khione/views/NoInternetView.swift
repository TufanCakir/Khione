import SwiftUI

struct NoInternetView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {

            icon

            textSection

            retryButton
        }
        .padding(32)
        .frame(maxWidth: 420)
        .background(cardBackground)
        .padding()
        .transition(.opacity)
    }

    // MARK: - Icon
    private var icon: some View {
        Image(systemName: "wifi.slash")
            .font(.system(size: 46, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
            .accessibilityHidden(true)
    }

    // MARK: - Text
    private var textSection: some View {
        VStack(spacing: 8) {
            Text("Keine Internetverbindung")
                .font(.title3.weight(.semibold))

            Text("""
            Khione benötigt eine aktive Internetverbindung.
            Bitte verbinde dich mit WLAN oder mobilen Daten.
            """)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Retry (UX-only)
    private var retryButton: some View {
        Button {
            // NetworkStatus wird automatisch aktualisiert
        } label: {
            Label("Erneut versuchen", systemImage: "arrow.clockwise")
        }
        .font(.footnote.weight(.medium))
        .buttonStyle(.bordered)
        .tint(.secondary)
        .disabled(true)
        .opacity(0.6)
    }

    // MARK: - Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 20,
                y: 8
            )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NoInternetView()
    }
    .preferredColorScheme(.dark)
}
