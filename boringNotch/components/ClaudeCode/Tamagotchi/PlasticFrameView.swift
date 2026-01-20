//
//  PlasticFrameView.swift
//  boringNotch
//
//  Translucent plastic frame with 3D ridges and decorative buttons
//  for retro toy aesthetic around Tamagotchi content
//

import SwiftUI

struct PlasticFrameView<Content: View>: View {
    let content: Content
    let frameColor: Color  // Base cyan/teal
    let cornerRadius: CGFloat
    let frameWidth: CGFloat  // Total frame thickness

    // Navigation state for project switching
    let sessionCount: Int
    let currentSessionIndex: Int
    let onLeftButton: (() -> Void)?
    let onRightButton: (() -> Void)?

    init(
        frameColor: Color = Color(red: 0.0, green: 0.75, blue: 0.85),
        cornerRadius: CGFloat = 16,
        frameWidth: CGFloat = 12,
        sessionCount: Int = 0,
        currentSessionIndex: Int = 0,
        onLeftButton: (() -> Void)? = nil,
        onRightButton: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.frameColor = frameColor
        self.cornerRadius = cornerRadius
        self.frameWidth = frameWidth
        self.sessionCount = sessionCount
        self.currentSessionIndex = currentSessionIndex
        self.onLeftButton = onLeftButton
        self.onRightButton = onRightButton
    }

    // Height of the bottom buttons row (for padding calculation)
    private var buttonsRowHeight: CGFloat { 24 }

    var body: some View {
        // VStack with content and buttons row integrated
        VStack(spacing: 0) {
            // Main content area
            content
                .padding(.top, frameWidth)
                .padding(.horizontal, frameWidth)
                .padding(.bottom, 4)  // Small padding before buttons

            // Buttons row at bottom (part of layout, not overlay)
            buttonsRow
        }
        .background(
            ZStack {
                // Base plastic color (outer)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(plasticGradient(opacity: 0.7))

                // Middle ridge highlight
                RoundedRectangle(cornerRadius: cornerRadius - 4)
                    .stroke(frameColor.opacity(0.9), lineWidth: 3)
                    .padding(3)

                // Inner ridge (lighter)
                RoundedRectangle(cornerRadius: cornerRadius - 6)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), frameColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .padding(6)

                // Glossy highlight overlay
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
        )
    }

    // Plastic gradient for 3D depth effect
    private func plasticGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                frameColor.opacity(opacity * 0.8),
                frameColor.opacity(opacity),
                frameColor.opacity(opacity * 0.9),
                frameColor.opacity(opacity * 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Navigation buttons row
    private var buttonsRow: some View {
        HStack(spacing: 10) {
            // Left: Previous project button
            navigationButton(
                icon: "chevron.left",
                enabled: currentSessionIndex > 0,
                action: onLeftButton
            )

            // Middle: Project indicator dots
            projectIndicatorDots

            // Right: Next project button
            navigationButton(
                icon: "chevron.right",
                enabled: currentSessionIndex < sessionCount - 1,
                action: onRightButton
            )
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius
            )
            .fill(plasticGradient(opacity: 0.6))
        )
    }

    // Navigation button with chevron icon
    @ViewBuilder
    private func navigationButton(icon: String, enabled: Bool, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: enabled
                            ? [Color.yellow, Color(red: 0.9, green: 0.8, blue: 0.0)]
                            : [Color.yellow.opacity(0.4), Color(red: 0.9, green: 0.8, blue: 0.0).opacity(0.4)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 14, height: 14)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(enabled ? Color.black.opacity(0.7) : Color.black.opacity(0.3))
                )
                .overlay(
                    Circle()
                        .stroke(Color.yellow.opacity(enabled ? 0.5 : 0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(enabled ? 0.3 : 0.15), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 28)  // Larger hit area
        .contentShape(Rectangle())      // Ensure entire area is tappable
        .disabled(!enabled || action == nil)
    }

    // Project indicator dots showing total count and current position
    private var projectIndicatorDots: some View {
        HStack(spacing: 4) {
            if sessionCount > 0 {
                ForEach(0..<sessionCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentSessionIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 5, height: 5)
                }
            } else {
                // Fallback: single decorative dot when no sessions
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PlasticFrameView(
        frameColor: Color(red: 0.0, green: 0.75, blue: 0.85),
        cornerRadius: 14,
        frameWidth: 10
    ) {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 72, height: 72)

            Spacer()

            VStack {
                Text("Stats Panel")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 200)
        }
        .padding(8)
        .background(Color.black)
    }
    .padding()
}
