import AVFAudio
import Combine
import Foundation
import QuartzCore

enum AutoMixEngineError: LocalizedError {
    case invalidDuration
    case incompatibleSampleRates
    case noTransitionPlan

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "The first audio file has no usable duration."
        case .incompatibleSampleRates:
            return "Choose files with the same sample rate for this sample app."
        case .noTransitionPlan:
            return "The selected first track is too short for the current AutoMix settings."
        }
    }
}

/// Demonstrates a local-file adapter for SGAutoMixCore. It has no Spotify hooks.
final class AutoMixEngine: ObservableObject {
    @Published private(set) var status = "Choose two local audio files"
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let outgoingPlayer = AVAudioPlayerNode()
    private let incomingPlayer = AVAudioPlayerNode()
    private var outgoingFile: AVAudioFile?
    private var incomingFile: AVAudioFile?
    private var plan = SGAutoMixPlan()
    private var timer: Timer?
    private var startedAt = 0.0
    private var incomingStarted = false
    private var securityScopedURLs: [URL] = []

    init() {
        engine.attach(outgoingPlayer)
        engine.attach(incomingPlayer)
        let mixer = engine.mainMixerNode
        engine.connect(outgoingPlayer, to: mixer, format: nil)
        engine.connect(incomingPlayer, to: mixer, format: nil)
    }

    deinit {
        stop()
    }

    func start(outgoingURL: URL, incomingURL: URL) throws {
        stop()

        // File Importer may return security-scoped URLs. Keep each scope open
        // for the full playback session, then release it in stop().
        for url in [outgoingURL, incomingURL] where url.startAccessingSecurityScopedResource() {
            securityScopedURLs.append(url)
        }

        let first: AVAudioFile
        let second: AVAudioFile
        do {
            first = try AVAudioFile(forReading: outgoingURL)
            second = try AVAudioFile(forReading: incomingURL)
        } catch {
            releaseSecurityScopes()
            throw error
        }
        guard first.fileFormat.sampleRate > 0 else {
            releaseSecurityScopes()
            throw AutoMixEngineError.invalidDuration
        }
        guard first.fileFormat.sampleRate == second.fileFormat.sampleRate else {
            releaseSecurityScopes()
            throw AutoMixEngineError.incompatibleSampleRates
        }

        let duration = Double(first.length) / first.fileFormat.sampleRate
        var configuration = SGAutoMixConfigurationDefault()
        var newPlan = SGAutoMixPlan()
        guard SGAutoMixBuildPlan(configuration, duration, true, 1, &newPlan) else {
            releaseSecurityScopes()
            throw AutoMixEngineError.noTransitionPlan
        }
        configuration.enabled = true

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            releaseSecurityScopes()
            throw error
        }

        outgoingFile = first
        incomingFile = second
        plan = newPlan
        outgoingPlayer.volume = 1
        incomingPlayer.volume = 0
        outgoingPlayer.scheduleFile(first, at: nil)
        incomingPlayer.scheduleFile(second, at: nil)

        engine.prepare()
        try engine.start()
        startedAt = CACurrentMediaTime()
        incomingStarted = false
        outgoingPlayer.play()
        isPlaying = true
        status = "Playing first track"

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateMix()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        outgoingPlayer.stop()
        incomingPlayer.stop()
        engine.stop()
        SGAutoMixCancel(&plan)
        outgoingFile = nil
        incomingFile = nil
        releaseSecurityScopes()
        incomingStarted = false
        isPlaying = false
        status = "Stopped"
    }

    private func updateMix() {
        guard isPlaying else { return }
        let elapsed = CACurrentMediaTime() - startedAt
        var activePlan = plan
        let gains = SGAutoMixGainsForPosition(&activePlan, elapsed)

        if elapsed >= plan.startSeconds && !incomingStarted {
            incomingStarted = true
            incomingPlayer.play()
            status = "Crossfading"
        }
        outgoingPlayer.volume = gains.outgoing
        incomingPlayer.volume = gains.incoming

        if elapsed >= plan.endSeconds {
            outgoingPlayer.stop()
            outgoingPlayer.volume = 0
            incomingPlayer.volume = 1
            timer?.invalidate()
            timer = nil
            status = "Playing second track"
        }
    }

    private func releaseSecurityScopes() {
        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedURLs.removeAll()
    }
}
