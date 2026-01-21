//
//  CelebrationOverlayView.swift
//  boringNotch
//
//  Overlay view for peek-a-boo celebration animation
//  Appears below the notch when a tool completes
//  The notch hangs DOWN from the top of the screen, so the character pops DOWN from the bottom edge
//

import SwiftUI

struct CelebrationOverlayView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var manager = ClaudeCodeManager.shared

    // Animation states
    @State private var popOutOffset: CGFloat = -60  // Start fully hidden inside notch
    @State private var armRotation: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var isVisible = false

    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                // Position the character at center-bottom of the notch
                // The character pops DOWN from below the bottom edge of the notch
                // When closed: position just below the closed notch height
                // When open: position near the bottom of the open notch
                let yPosition: CGFloat = vm.notchState == .open
                    ? geometry.size.height - 10
                    : vm.effectiveClosedNotchHeight + 15

                celebratingCharacter
                    .rotationEffect(.degrees(180))  // Upside down - feet first!
                    .offset(y: popOutOffset + bounceOffset)
                    .frame(width: 72, height: 80)
                    // Center horizontally, Y based on notch state
                    .position(x: geometry.size.width / 2, y: yPosition)
            }
        }
        .onChange(of: manager.isCelebrating) { _, celebrating in
            if celebrating {
                startCelebration()
            } else {
                endCelebration()
            }
        }
        .allowsHitTesting(false)  // Don't interfere with interactions
    }

    private var celebratingCharacter: some View {
        ZStack {
            // Character body
            VStack(spacing: 0) {
                // Body with arms
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

            // Sparkles
            HStack(spacing: 20) {
                sparkle
                    .offset(y: -25)
                sparkle
                    .offset(y: -20)
            }
        }
        .scaleEffect(0.95)  // Slightly smaller when popping out
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
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(ClaudePixelPalette.eyeColor)
                        .frame(width: 6, height: 4)
                    Rectangle()
                        .fill(ClaudePixelPalette.eyeColor)
                        .frame(width: 6, height: 4)
                }

                // Happy mouth
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
        }
    }

    private func arm(isLeft: Bool) -> some View {
        Rectangle()
            .fill(ClaudePixelPalette.bodyColor)
            .frame(width: 6, height: 12)
            .offset(y: 4)
            .rotationEffect(
                .degrees(isLeft ? -armRotation : armRotation),
                anchor: isLeft ? .bottomTrailing : .bottomLeading  // Bottom anchors for upside-down
            )
    }

    private var feet: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(ClaudePixelPalette.bodyColor)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var sparkle: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 2, height: 6)
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 6, height: 2)
        }
    }

    // MARK: - Animation

    private func startCelebration() {
        isVisible = true
        popOutOffset = -60  // Start fully hidden inside notch
        armRotation = 0
        bounceOffset = 0

        // Phase 1: Pop DOWN quickly (spring animation) - only half body emerges (upside down)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            popOutOffset = -10  // Only ~30px visible = half body peek-a-boo
        }

        // Phase 2: Enthusiastic arm waving - continues through retraction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(
                Animation.easeInOut(duration: 0.12)
                    .repeatForever(autoreverses: true)
            ) {
                armRotation = 45
            }
        }

        // Phase 3: Small bounce while waving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(
                Animation.easeInOut(duration: 0.2)
                    .repeatCount(3, autoreverses: true)
            ) {
                bounceOffset = 5  // Bounce down (positive Y)
            }
        }

        // Phase 4: Retract back UP into the notch while still waving
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeIn(duration: 0.35)) {
                popOutOffset = -60  // Go back up into notch
                bounceOffset = 0
            }
        }
    }

    private func endCelebration() {
        // Stop all repeating animations first to prevent memory leaks
        // Using Transaction with nil animation stops any running repeatForever animations
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            armRotation = 0
            bounceOffset = 0
        }

        // Quick fade out if still visible
        withAnimation(.easeOut(duration: 0.1)) {
            isVisible = false
        }
        // Reset state
        popOutOffset = -60
    }
}

#Preview {
    let vm = BoringViewModel()
    return ZStack {
        Color.gray.opacity(0.3)

        // Simulate notch hanging down from top
        VStack {
            // Notch content area
            VStack {
                Text("Notch Area")
                    .foregroundColor(.white)
                Spacer()
                Text("Bottom edge - character pops out here")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 640, height: 220)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                CelebrationOverlayView()
                    .environmentObject(vm)
            )

            Spacer()
        }
    }
    .frame(width: 700, height: 400)
}
