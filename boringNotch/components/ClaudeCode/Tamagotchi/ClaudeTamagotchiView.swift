//
//  ClaudeTamagotchiView.swift
//  boringNotch
//
//  Main Tamagotchi-style layout with pixel-art Claude character and condensed stats
//

import SwiftUI

struct ClaudeTamagotchiView: View {
    @ObservedObject var manager = ClaudeCodeManager.shared

    @State private var lastToolCompletionTime: Date?
    @State private var isCelebrating = false
    @State private var idleTimer: Timer?
    @State private var isIdle = false

    private let idleThreshold: TimeInterval = 8.0

    var body: some View {
        PlasticFrameView(
            frameColor: Color(red: 0.0, green: 0.75, blue: 0.85),  // Cyan
            cornerRadius: 14,
            frameWidth: 10,
            sessionCount: manager.availableSessions.count,
            currentSessionIndex: currentSessionIndex,
            onLeftButton: { selectPreviousSession() },
            onRightButton: { selectNextSession() }
        ) {
            HStack(spacing: 0) {
                // Left: Tamagotchi screen with character
                TamagotchiScreen(mood: currentMood, size: screenSize)

                Spacer()

                // Right: Expanded stats panel
                TamagotchiStatsPanel(
                    state: manager.state,
                    session: manager.selectedSession,
                    conversations: manager.conversations
                )
                .frame(maxWidth: 480)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black)  // Content background for contrast
        }
        .onChange(of: manager.state.recentTools.first?.id) { oldValue, newValue in
            // Detect tool completion for celebration
            if oldValue != nil && newValue != nil && oldValue != newValue {
                triggerCelebration()
            }
        }
        .onChange(of: manager.state.isActive) { _, isActive in
            if isActive {
                resetIdleTimer()
            }
        }
        .onAppear {
            startIdleTracking()
        }
        .onDisappear {
            idleTimer?.invalidate()
        }
    }

    // MARK: - Mood Calculation

    private var currentMood: ClaudeMood {
        ClaudeMood.from(
            isActive: manager.state.isActive,
            isThinking: manager.state.isThinking,
            hasActiveTools: manager.state.hasActiveTools,
            needsPermission: manager.state.needsPermission,
            contextPercentage: manager.state.tokenUsage.contextPercentage,
            isIdle: isIdle && !manager.state.isActive,
            isCelebrating: isCelebrating
        )
    }

    private var screenSize: CGSize {
        // Adjust based on available space
        CGSize(width: 72, height: 72)
    }

    // MARK: - Session Navigation

    private var currentSessionIndex: Int {
        guard let selected = manager.selectedSession else { return 0 }
        return manager.availableSessions.firstIndex(where: { $0.id == selected.id }) ?? 0
    }

    private func selectPreviousSession() {
        let index = currentSessionIndex
        guard index > 0 else { return }
        manager.selectSession(manager.availableSessions[index - 1])
    }

    private func selectNextSession() {
        let index = currentSessionIndex
        guard index < manager.availableSessions.count - 1 else { return }
        manager.selectSession(manager.availableSessions[index + 1])
    }

    // MARK: - Celebration Animation

    private func triggerCelebration() {
        guard !isCelebrating else { return }

        isCelebrating = true
        lastToolCompletionTime = Date()

        // End celebration after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCelebrating = false
        }
    }

    // MARK: - Idle Tracking

    private func startIdleTracking() {
        resetIdleTimer()
    }

    private func resetIdleTimer() {
        isIdle = false
        idleTimer?.invalidate()

        idleTimer = Timer.scheduledTimer(withTimeInterval: idleThreshold, repeats: false) { _ in
            if !manager.state.isActive {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isIdle = true
                }
            }
        }
    }
}

// MARK: - Compact Version

struct ClaudeTamagotchiViewCompact: View {
    @ObservedObject var manager = ClaudeCodeManager.shared

    @State private var isIdle = false

    var body: some View {
        TamagotchiScreenCompact(mood: currentMood)
            .onChange(of: manager.state.isActive) { _, isActive in
                if !isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        if !manager.state.isActive {
                            isIdle = true
                        }
                    }
                } else {
                    isIdle = false
                }
            }
    }

    private var currentMood: ClaudeMood {
        ClaudeMood.from(
            isActive: manager.state.isActive,
            isThinking: manager.state.isThinking,
            hasActiveTools: manager.state.hasActiveTools,
            needsPermission: manager.state.needsPermission,
            contextPercentage: manager.state.tokenUsage.contextPercentage,
            isIdle: isIdle,
            isCelebrating: false
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ClaudeTamagotchiView()
            .frame(width: 640, height: 120) // Full notch width with plastic frame

        ClaudeTamagotchiViewCompact()
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
