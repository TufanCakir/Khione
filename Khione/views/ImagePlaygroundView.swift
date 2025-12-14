import SwiftUI
import ImagePlayground

@available(iOS 18.0, *)
struct ImagePlaygroundLauncher: View {

    @State private var showPlayground = false
    @State private var showUnavailableAlert = false
    @State private var isPressed = false

    var body: some View {

        Button {
            openImagePlayground()
        } label: {

            VStack(alignment: .leading, spacing: 18) {

                // MARK: - Top Row
                HStack {
                    Image(systemName: "snowflake")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // MARK: - Title
                Text("Khione Image Playground")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Erstelle frostige Bilder mit Apple Intelligence – sicher und vollständig auf deinem Gerät.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: - CTA
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Bild generieren")
                        .fontWeight(.semibold)
                }
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.top, 6)

                Divider()
                    .background(.white.opacity(0.25))

                // MARK: - Privacy
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                    Text("Verarbeitung erfolgt vollständig lokal auf dem Gerät.")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(22)
            .frame(maxWidth: .infinity)

            // MARK: - Ice Gradient Background
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.75, blue: 0.95),
                                Color(red: 0.35, green: 0.55, blue: 0.85),
                                Color(red: 0.15, green: 0.30, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // MARK: - Frost Glass Overlay
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .opacity(0.25)
            }

            // MARK: - Border
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }

            // MARK: - Interaction
            .scaleEffect(isPressed ? 0.97 : 1)
            .shadow(
                color: .black.opacity(isPressed ? 0.08 : 0.18),
                radius: isPressed ? 6 : 18,
                y: isPressed ? 2 : 10
            )
            .animation(.easeOut(duration: 0.18), value: isPressed)
        }
        .buttonStyle(.plain)
        .padding()
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )

        // MARK: - Apple Image Playground Sheet
        .imagePlaygroundSheet(
            isPresented: $showPlayground,
            onCompletion: { result in
                handleCompletion(result)
                showPlayground = false
            }
        )

        // MARK: - Fallback Alert
        .alert(
            "Image Playground nicht verfügbar",
            isPresented: $showUnavailableAlert
        ) {
            Button("OK") {}
        } message: {
            Text("Dieses Feature ist nur auf unterstützten Geräten mit Apple Intelligence verfügbar.")
        }
    }

    // MARK: - Logic

    private func openImagePlayground() {
        #if targetEnvironment(simulator)
        showUnavailableAlert = true
        #else
        showPlayground = true
        #endif
    }

    private func handleCompletion(_ result: Any?) {
        guard let result else {
            print("ℹ️ Image Playground abgebrochen")
            return
        }

        print("✅ Khione Image Playground Ergebnis erhalten:", result)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ImagePlaygroundLauncher()
    }
    .preferredColorScheme(.dark)
}
