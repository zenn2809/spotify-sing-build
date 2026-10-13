import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var mixer = AutoMixEngine()
    @State private var firstURL: URL?
    @State private var secondURL: URL?
    @State private var choosingFirst = false
    @State private var choosingSecond = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Local audio") {
                    Button(firstURL?.lastPathComponent ?? "Choose first track") {
                        choosingFirst = true
                    }
                    Button(secondURL?.lastPathComponent ?? "Choose next track") {
                        choosingSecond = true
                    }
                }

                Section("AutoMix") {
                    Text(mixer.status)
                    Button(mixer.isPlaying ? "Stop" : "Start AutoMix") {
                        if mixer.isPlaying {
                            mixer.stop()
                        } else {
                            start()
                        }
                    }
                    .disabled(!mixer.isPlaying && (firstURL == nil || secondURL == nil))
                }

                Section("How it works") {
                    Text("The app plays the first local file, starts the second six seconds before the end, and applies the SGAutoMixCore equal-power gain curve.")
                        .font(.footnote)
                }
            }
            .navigationTitle("AutoMix Sample")
        }
        .fileImporter(isPresented: $choosingFirst, allowedContentTypes: [.audio]) { result in
            select(result, first: true)
        }
        .fileImporter(isPresented: $choosingSecond, allowedContentTypes: [.audio]) { result in
            select(result, first: false)
        }
        .alert("Cannot start AutoMix", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func select(_ result: Result<URL, Error>, first: Bool) {
        guard case let .success(url) = result else { return }
        if first {
            firstURL = url
        } else {
            secondURL = url
        }
    }

    private func start() {
        guard let firstURL, let secondURL else { return }
        do {
            try mixer.start(outgoingURL: firstURL, incomingURL: secondURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
