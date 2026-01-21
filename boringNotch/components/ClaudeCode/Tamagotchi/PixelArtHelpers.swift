//
//  PixelArtHelpers.swift
//  boringNotch
//
//  Pixel art utilities for Tamagotchi-style rendering
//

import SwiftUI

// MARK: - Pixel Grid Helper

/// A helper view for drawing pixel-perfect shapes on a grid
struct PixelGrid: View {
    let columns: Int
    let rows: Int
    let pixelSize: CGFloat
    let pixels: [[Color?]]

    init(columns: Int, rows: Int, pixelSize: CGFloat = 2, pixels: [[Color?]]) {
        self.columns = columns
        self.rows = rows
        self.pixelSize = pixelSize
        self.pixels = pixels
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { col in
                        if row < pixels.count && col < pixels[row].count,
                           let color = pixels[row][col] {
                            Rectangle()
                                .fill(color)
                                .frame(width: pixelSize, height: pixelSize)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: pixelSize, height: pixelSize)
                        }
                    }
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - Scanline Overlay

/// CRT/LCD screen effect with horizontal scanlines
struct ScanlineOverlay: View {
    let lineSpacing: CGFloat
    let opacity: Double

    init(lineSpacing: CGFloat = 2, opacity: Double = 0.1) {
        self.lineSpacing = lineSpacing
        self.opacity = opacity
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: lineSpacing) {
                ForEach(0..<Int(geometry.size.height / (1 + lineSpacing)), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(opacity))
                        .frame(height: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Pixel Particles

/// Animated pixel particle for effects like Zzz, sparkles, sweat drops
struct PixelParticle: View {
    enum ParticleType {
        case zzz
        case sparkle
        case sweat
        case exclamation
        case heart
        case thought
    }

    let type: ParticleType
    let pixelSize: CGFloat

    init(type: ParticleType, pixelSize: CGFloat = 2) {
        self.type = type
        self.pixelSize = pixelSize
    }

    var body: some View {
        switch type {
        case .zzz:
            zzzParticle
        case .sparkle:
            sparkleParticle
        case .sweat:
            sweatParticle
        case .exclamation:
            exclamationParticle
        case .heart:
            heartParticle
        case .thought:
            thoughtParticle
        }
    }

    private var zzzParticle: some View {
        VStack(alignment: .leading, spacing: pixelSize) {
            // Z shape
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.8))
                        .frame(width: pixelSize, height: pixelSize)
                }
            }
            HStack(spacing: 0) {
                Rectangle().fill(Color.clear).frame(width: pixelSize, height: pixelSize)
                Rectangle().fill(Color.white.opacity(0.8)).frame(width: pixelSize, height: pixelSize)
            }
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.8))
                        .frame(width: pixelSize, height: pixelSize)
                }
            }
        }
        .drawingGroup()
    }

    private var sparkleParticle: some View {
        ZStack {
            // Plus shape sparkle
            Rectangle()
                .fill(Color.yellow)
                .frame(width: pixelSize, height: pixelSize * 3)
            Rectangle()
                .fill(Color.yellow)
                .frame(width: pixelSize * 3, height: pixelSize)
        }
        .drawingGroup()
    }

    private var sweatParticle: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.cyan.opacity(0.8))
                .frame(width: pixelSize, height: pixelSize)
            Rectangle()
                .fill(Color.cyan.opacity(0.8))
                .frame(width: pixelSize, height: pixelSize)
            HStack(spacing: 0) {
                Rectangle().fill(Color.cyan.opacity(0.8)).frame(width: pixelSize, height: pixelSize)
                Rectangle().fill(Color.cyan.opacity(0.8)).frame(width: pixelSize, height: pixelSize)
            }
            Rectangle()
                .fill(Color.cyan.opacity(0.8))
                .frame(width: pixelSize, height: pixelSize)
        }
        .drawingGroup()
    }

    private var exclamationParticle: some View {
        VStack(spacing: pixelSize) {
            Rectangle()
                .fill(Color.orange)
                .frame(width: pixelSize * 2, height: pixelSize * 4)
            Rectangle()
                .fill(Color.orange)
                .frame(width: pixelSize * 2, height: pixelSize * 2)
        }
        .drawingGroup()
    }

    private var heartParticle: some View {
        VStack(spacing: 0) {
            HStack(spacing: pixelSize * 2) {
                Rectangle().fill(Color.red).frame(width: pixelSize * 2, height: pixelSize * 2)
                Rectangle().fill(Color.red).frame(width: pixelSize * 2, height: pixelSize * 2)
            }
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(Color.red).frame(width: pixelSize * 2, height: pixelSize * 2)
                }
            }
            Rectangle().fill(Color.red).frame(width: pixelSize * 2, height: pixelSize * 2)
        }
        .drawingGroup()
    }

    private var thoughtParticle: some View {
        VStack(spacing: pixelSize) {
            // Small thought bubbles
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: pixelSize * 2, height: pixelSize * 2)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: pixelSize * 3, height: pixelSize * 3)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: pixelSize * 4, height: pixelSize * 4)
        }
    }
}

// MARK: - Animated Particle Container

/// Container that animates particles floating upward
struct FloatingParticles: View {
    let particleType: PixelParticle.ParticleType
    let count: Int

    @State private var offsets: [CGFloat] = []
    @State private var opacities: [Double] = []

    init(type: PixelParticle.ParticleType, count: Int = 3) {
        self.particleType = type
        self.count = count
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                PixelParticle(type: particleType)
                    .offset(x: CGFloat(index * 6), y: index < offsets.count ? offsets[index] : 0)
                    .opacity(index < opacities.count ? opacities[index] : 0.8)
                    .scaleEffect(0.6 + CGFloat(index) * 0.15)
            }
        }
        .onAppear {
            offsets = Array(repeating: 0, count: count)
            opacities = Array(repeating: 0.8, count: count)
            startAnimation()
        }
        .onDisappear {
            // Stop all repeating animations to prevent memory leaks
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                offsets = Array(repeating: 0, count: count)
                opacities = Array(repeating: 0.8, count: count)
            }
        }
    }

    private func startAnimation() {
        for i in 0..<count {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.3)
            ) {
                if i < offsets.count {
                    offsets[i] = -8
                }
                if i < opacities.count {
                    opacities[i] = 0.4
                }
            }
        }
    }
}

// MARK: - Pixel Color Palette

/// Color palette for the Claude Tamagotchi character
struct ClaudePixelPalette {
    // Main body color - terracotta/salmon
    static let bodyColor = Color(red: 0.78, green: 0.53, blue: 0.46)
    // Darker shade for nose/mouth area
    static let darkBodyColor = Color(red: 0.55, green: 0.35, blue: 0.30)
    // Eye color
    static let eyeColor = Color.black
    // Highlight color for shine effects
    static let highlightColor = Color(red: 0.88, green: 0.65, blue: 0.58)
    // Shadow color
    static let shadowColor = Color(red: 0.45, green: 0.28, blue: 0.22)

    // Screen colors
    static let screenBackground = Color(red: 0.75, green: 0.82, blue: 0.72) // Greenish LCD tint
    static let screenBorder = Color(red: 0.25, green: 0.25, blue: 0.28)
    static let screenInnerBorder = Color(red: 0.35, green: 0.35, blue: 0.38)
}

// MARK: - Pixel Text Helper

/// Renders text in a retro pixel-style font
struct PixelText: View {
    let text: String
    let size: CGFloat
    let color: Color

    init(_ text: String, size: CGFloat = 8, color: Color = .white) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .foregroundColor(color)
    }
}

// MARK: - Pixel Progress Bar

/// A pixel-art style progress bar
struct PixelProgressBar: View {
    let progress: Double
    let fillColor: Color
    let backgroundColor: Color
    let height: CGFloat
    let pixelSize: CGFloat

    init(
        progress: Double,
        fillColor: Color = .green,
        backgroundColor: Color = Color.gray.opacity(0.3),
        height: CGFloat = 8,
        pixelSize: CGFloat = 2
    ) {
        self.progress = min(max(progress, 0), 1)
        self.fillColor = fillColor
        self.backgroundColor = backgroundColor
        self.height = height
        self.pixelSize = pixelSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)

                // Fill with pixel segments
                HStack(spacing: 1) {
                    let totalSegments = Int(geometry.size.width / (pixelSize + 1))
                    let filledSegments = Int(Double(totalSegments) * progress)

                    ForEach(0..<filledSegments, id: \.self) { _ in
                        Rectangle()
                            .fill(fillColor)
                            .frame(width: pixelSize, height: height - 2)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .frame(height: height)
        .drawingGroup()
    }
}
