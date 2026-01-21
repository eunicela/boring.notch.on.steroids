//
//  ClaudePixelCharacter.swift
//  boringNotch
//
//  Pixel art Claude character with mood states and animations
//

import SwiftUI
import Combine

// MARK: - Character Mood States

enum ClaudeMood {
    case sleeping      // SessionStatus.idle for 8s+
    case idle          // SessionStatus.waitingForInput
    case working       // SessionStatus.working with active tools
    case thinking      // SessionStatus.working without active tools (generating)
    case waiting       // SessionStatus.waitingForApproval
    case tired         // contextPercentage > 75%
    case critical      // contextPercentage > 90%
    case celebrating   // Tool just completed

    /// Determine mood from SessionStatus (preferred method)
    /// This is the state machine approach - clean and predictable
    static func from(
        status: SessionStatus,
        hasActiveTools: Bool,
        contextPercentage: Double,
        isSleeping: Bool,
        isCelebrating: Bool
    ) -> ClaudeMood {
        // Celebration takes highest priority (temporary state)
        if isCelebrating {
            return .celebrating
        }

        // Context warnings override operational state (health indicator)
        if contextPercentage > 90 {
            return .critical
        }
        if contextPercentage > 75 {
            return .tired
        }

        // Map SessionStatus to visual mood
        switch status {
        case .waitingForApproval:
            return .waiting

        case .working:
            // Distinguish between tool execution and thinking
            return hasActiveTools ? .working : .thinking

        case .waitingForInput:
            return .idle

        case .idle:
            return isSleeping ? .sleeping : .idle
        }
    }

    /// Legacy method - determine mood from boolean flags
    /// Kept for backward compatibility during migration
    static func from(
        isActive: Bool,
        isThinking: Bool,
        hasActiveTools: Bool,
        needsPermission: Bool,
        contextPercentage: Double,
        isIdle: Bool,
        isCelebrating: Bool
    ) -> ClaudeMood {
        if isCelebrating {
            return .celebrating
        }
        if needsPermission {
            return .waiting
        }
        if contextPercentage > 90 {
            return .critical
        }
        if contextPercentage > 75 {
            return .tired
        }
        if isActive && hasActiveTools {
            return .working
        }
        if isThinking && !hasActiveTools {
            return .thinking
        }
        if isIdle {
            return .sleeping
        }
        if !isActive {
            return .idle
        }
        return .idle
    }
}

// MARK: - Claude Pixel Character View

struct ClaudePixelCharacter: View {
    let mood: ClaudeMood
    let scale: CGFloat

    @State private var isBlinking = false
    @State private var bounceOffset: CGFloat = 0
    @State private var armRotation: Double = 0
    @State private var breathScale: CGFloat = 1.0
    @State private var eyeOffset: CGFloat = 0
    @State private var celebrateOffset: CGFloat = 0
    @State private var sweatVisible = false
    @State private var footTap = false
    @State private var popOutOffset: CGFloat = 0  // For peek-a-boo animation

    // Timer publisher without autoconnect - manually managed to prevent memory leaks
    private let blinkTimer = Timer.publish(every: 3.0, on: .main, in: .common)
    @State private var blinkTimerCancellable: Cancellable?

    init(mood: ClaudeMood, scale: CGFloat = 1.0) {
        self.mood = mood
        self.scale = scale
    }

    var body: some View {
        ZStack {
            characterBody
            decorations
        }
        .scaleEffect(scale)
        .onReceive(blinkTimer) { _ in
            if mood != .sleeping {
                triggerBlink()
            }
        }
        .onChange(of: mood) { _, newMood in
            updateAnimations(for: newMood)
        }
        .onAppear {
            updateAnimations(for: mood)
            // Connect the timer only when view appears
            blinkTimerCancellable = blinkTimer.connect()
        }
        .onDisappear {
            // Cancel the timer to prevent memory leaks
            blinkTimerCancellable?.cancel()
            blinkTimerCancellable = nil

            // Stop all repeating animations to prevent memory leaks
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                bounceOffset = 0
                armRotation = 0
                breathScale = 1.0
                eyeOffset = 0
                celebrateOffset = 0
                sweatVisible = false
                footTap = false
                popOutOffset = 0
            }
        }
    }

    // MARK: - Character Body

    private var characterBody: some View {
        ZStack {
            // Main body with arms
            VStack(spacing: 0) {
                // Body with side arms
                HStack(spacing: 0) {
                    // Left arm
                    arm(isLeft: true)

                    // Main body
                    mainBody

                    // Right arm
                    arm(isLeft: false)
                }

                // Feet
                feet
            }
            .offset(y: bounceOffset + celebrateOffset + popOutOffset)
            .scaleEffect(breathScale)
        }
    }

    private var mainBody: some View {
        ZStack {
            // Body rectangle
            Rectangle()
                .fill(ClaudePixelPalette.bodyColor)
                .frame(width: 40, height: 32)

            // Face
            VStack(spacing: 4) {
                // Eyes
                eyes

                // Nose/mouth
                mouth
            }
        }
    }

    private var eyes: some View {
        HStack(spacing: 8) {
            eye(isLeft: true)
            eye(isLeft: false)
        }
        .offset(y: eyeLookOffset)
    }

    private func eye(isLeft: Bool) -> some View {
        Rectangle()
            .fill(ClaudePixelPalette.eyeColor)
            .frame(width: 6, height: eyeHeight)
            .offset(x: eyeOffset * (isLeft ? -1 : 1))
    }

    private var eyeHeight: CGFloat {
        switch mood {
        case .sleeping:
            return 1 // Closed eyes - thin line
        case .tired, .critical:
            return 2 // Droopy/half-closed
        default:
            return isBlinking ? 1 : 4
        }
    }

    private var eyeLookOffset: CGFloat {
        switch mood {
        case .thinking:
            return -2 // Looking up
        default:
            return 0
        }
    }

    private var mouth: some View {
        Group {
            switch mood {
            case .sleeping:
                // Peaceful sleeping mouth - small line
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 6, height: 2)
            case .working, .celebrating:
                // Happy/determined mouth
                happyMouth
            case .waiting, .critical:
                // Worried/anxious mouth
                worriedMouth
            case .tired:
                // Tired frown
                tiredMouth
            default:
                // Neutral mouth
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 8, height: 3)
            }
        }
    }

    private var happyMouth: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ClaudePixelPalette.darkBodyColor)
                .frame(width: 10, height: 2)
            HStack(spacing: 4) {
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 2, height: 2)
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 2, height: 2)
            }
        }
    }

    private var worriedMouth: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 2, height: 2)
                Rectangle()
                    .fill(ClaudePixelPalette.darkBodyColor)
                    .frame(width: 2, height: 2)
            }
            Rectangle()
                .fill(ClaudePixelPalette.darkBodyColor)
                .frame(width: 8, height: 2)
        }
    }

    private var tiredMouth: some View {
        Rectangle()
            .fill(ClaudePixelPalette.darkBodyColor)
            .frame(width: 6, height: 2)
            .offset(y: 1)
    }

    private func arm(isLeft: Bool) -> some View {
        Rectangle()
            .fill(ClaudePixelPalette.bodyColor)
            .frame(width: 6, height: 12)
            .offset(y: 4)
            .rotationEffect(
                .degrees(isLeft ? -armRotation : armRotation),
                anchor: isLeft ? .topTrailing : .topLeading
            )
    }

    private var feet: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(ClaudePixelPalette.bodyColor)
                    .frame(width: 6, height: 6)
                    .offset(y: footOffset(for: index))
            }
        }
    }

    private func footOffset(for index: Int) -> CGFloat {
        guard mood == .waiting && footTap else { return 0 }
        // Make one foot tap
        return index == 1 ? -2 : 0
    }

    // MARK: - Decorations (Particles, Effects)

    private var decorations: some View {
        ZStack {
            // Sleeping Zzz
            if mood == .sleeping {
                FloatingParticles(type: .zzz, count: 3)
                    .offset(x: 30, y: -20)
            }

            // Thinking bubble
            if mood == .thinking {
                PixelParticle(type: .thought)
                    .offset(x: 28, y: -25)
            }

            // Waiting exclamation
            if mood == .waiting {
                PixelParticle(type: .exclamation)
                    .offset(x: 0, y: -30)
            }

            // Critical sweat
            if mood == .critical && sweatVisible {
                PixelParticle(type: .sweat)
                    .offset(x: -22, y: -8)
            }

            // Celebrating sparkles
            if mood == .celebrating {
                HStack(spacing: 20) {
                    PixelParticle(type: .sparkle)
                        .offset(y: -25)
                    PixelParticle(type: .sparkle)
                        .offset(y: -20)
                }
            }
        }
    }

    // MARK: - Animation Logic

    private func triggerBlink() {
        withAnimation(.easeInOut(duration: 0.1)) {
            isBlinking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = false
            }
        }
    }

    private func updateAnimations(for mood: ClaudeMood) {
        // Stop all animations first by resetting values without animation
        // This is critical to prevent memory leaks from orphaned repeatForever animations
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            bounceOffset = 0
            armRotation = 0
            breathScale = 1.0
            eyeOffset = 0
            celebrateOffset = 0
            sweatVisible = false
            footTap = false
            popOutOffset = 0
        }

        switch mood {
        case .sleeping:
            startBreathingAnimation()

        case .idle:
            startIdleAnimation()

        case .working:
            startWorkingAnimation()

        case .thinking:
            startThinkingAnimation()

        case .waiting:
            startWaitingAnimation()

        case .tired:
            startTiredAnimation()

        case .critical:
            startCriticalAnimation()

        case .celebrating:
            startCelebratingAnimation()
        }
    }

    private func startBreathingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            breathScale = 1.03
        }
    }

    private func startIdleAnimation() {
        // Subtle sway
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            bounceOffset = 1
        }
    }

    private func startWorkingAnimation() {
        // Bouncing
        withAnimation(
            Animation.easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -3
        }

        // Arm waving
        withAnimation(
            Animation.easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
        ) {
            armRotation = 15
        }
    }

    private func startThinkingAnimation() {
        // Eyes looking up handled by eyeLookOffset

        // Subtle head tilt simulation
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            eyeOffset = 1
        }
    }

    private func startWaitingAnimation() {
        // Anxious bounce
        withAnimation(
            Animation.easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -1
        }

        // Foot tapping
        withAnimation(
            Animation.easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
        ) {
            footTap = true
        }
    }

    private func startTiredAnimation() {
        // Slow, heavy breathing
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            breathScale = 1.02
        }

        // Slight droop
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            bounceOffset = 2
        }
    }

    private func startCriticalAnimation() {
        // Faster anxious bounce
        withAnimation(
            Animation.easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -2
        }

        // Show sweat
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            sweatVisible = true
        }
    }

    private func startCelebratingAnimation() {
        // Simple celebration: just show sparkles (handled by decorations)
        // and a subtle happy bounce - no pop-up since overlay handles that
        withAnimation(
            Animation.easeInOut(duration: 0.3)
                .repeatCount(4, autoreverses: true)
        ) {
            bounceOffset = -2  // Subtle happy bounce
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 30) {
            VStack {
                ClaudePixelCharacter(mood: .idle)
                Text("Idle").font(.caption)
            }
            VStack {
                ClaudePixelCharacter(mood: .working)
                Text("Working").font(.caption)
            }
            VStack {
                ClaudePixelCharacter(mood: .thinking)
                Text("Thinking").font(.caption)
            }
        }

        HStack(spacing: 30) {
            VStack {
                ClaudePixelCharacter(mood: .sleeping)
                Text("Sleeping").font(.caption)
            }
            VStack {
                ClaudePixelCharacter(mood: .waiting)
                Text("Waiting").font(.caption)
            }
            VStack {
                ClaudePixelCharacter(mood: .celebrating)
                Text("Celebrating").font(.caption)
            }
        }

        HStack(spacing: 30) {
            VStack {
                ClaudePixelCharacter(mood: .tired)
                Text("Tired").font(.caption)
            }
            VStack {
                ClaudePixelCharacter(mood: .critical)
                Text("Critical").font(.caption)
            }
        }
    }
    .padding()
    .background(Color.black)
}
