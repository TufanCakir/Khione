import SwiftUI

struct NoInternetView: View {

    var body: some View {
        VStack(spacing: 28) {

            // MARK: - Icon
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            // MARK: - Text
            VStack(spacing: 8) {
                Text("Keine Internetverbindung")
                    .font(.title3.weight(.semibold))

                Text("Khione benötigt eine aktive Internetverbindung.\nBitte verbinde dich mit WLAN oder mobilen Daten.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // MARK: - Optional Retry Button
            Button {
                // optional: erneute Prüfung triggern
            } label: {
                Label("Erneut versuchen", systemImage: "arrow.clockwise")
                    .font(.footnote.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

        }
        .padding(32)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NoInternetView()
    }
    .preferredColorScheme(.dark)
}
