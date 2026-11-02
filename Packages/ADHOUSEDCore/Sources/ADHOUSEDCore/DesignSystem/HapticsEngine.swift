import Foundation
#if canImport(CoreHaptics)
import CoreHaptics
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class HapticsEngine {
    public static let shared = HapticsEngine()

    #if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    #endif

    private init() {
        prepareEngineIfSupported()
    }

    private func prepareEngineIfSupported() {
        #if canImport(CoreHaptics)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            engine = nil
        }
        #endif
    }

    /// Dopamine-rewarding two-stage mechanical latch + warm bloom on chore completion.
    public func playCompletionCelebration() {
        guard ADHOUSEDPreferences.shared.hapticsEnabled else { return }
        #if canImport(CoreHaptics)
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine {
            let click = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.92),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                ],
                relativeTime: 0
            )
            let bloom = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                ],
                relativeTime: 0.06,
                duration: 0.16
            )
            let finishPop = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65)
                ],
                relativeTime: 0.22
            )
            if let pattern = try? CHHapticPattern(events: [click, bloom, finishPop], parameters: []),
               let player = try? engine.makePlayer(with: pattern) {
                try? engine.start()
                try? player.start(atTime: CHHapticTimeImmediate)
                return
            }
        }
        #endif
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    public func playMechanicalTap() {
        guard ADHOUSEDPreferences.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
        #endif
    }

    public func playSprintStart() {
        guard ADHOUSEDPreferences.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }

    public func playUndoRewind() {
        guard ADHOUSEDPreferences.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
