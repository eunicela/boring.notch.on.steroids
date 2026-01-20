//
//  TamagotchiScreen.swift
//  boringNotch
//
//  Pixel-art container with retro LCD screen aesthetic
//

import SwiftUI

struct TamagotchiScreen: View {
    let mood: ClaudeMood
    let size: CGSize

    init(mood: ClaudeMood, size: CGSize = CGSize(width: 80, height: 80)) {
        self.mood = mood
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer casing (plastic frame)
            RoundedRectangle(cornerRadius: 6)
                .fill(ClaudePixelPalette.screenBorder)
                .frame(width: size.width + 12, height: size.height + 12)

            // Inner border
            RoundedRectangle(cornerRadius: 4)
                .fill(ClaudePixelPalette.screenInnerBorder)
                .frame(width: size.width + 6, height: size.height + 6)

            // LCD screen background
            ZStack {
                // Base screen color with LCD tint
                Rectangle()
                    .fill(screenBackgroundColor)
                    .frame(width: size.width, height: size.height)

                // Character
                ClaudePixelCharacter(mood: mood, scale: characterScale)

                // Scanline overlay for authenticity
                ScanlineOverlay(lineSpacing: 2, opacity: 0.05)
                    .frame(width: size.width, height: size.height)
                    .clipShape(Rectangle())
            }
            .clipShape(Rectangle())
        }
    }

    private var screenBackgroundColor: Color {
        // Slightly different tint based on mood
        switch mood {
        case .critical:
            return Color(red: 0.82, green: 0.75, blue: 0.72) // Reddish tint
        case .sleeping:
            return Color(red: 0.65, green: 0.70, blue: 0.68) // Darker, dimmed
        case .celebrating:
            return Color(red: 0.78, green: 0.85, blue: 0.75) // Brighter green
        default:
            return ClaudePixelPalette.screenBackground
        }
    }

    private var characterScale: CGFloat {
        // Scale character to fit screen
        let baseSize: CGFloat = 60 // Character base size
        let availableSize = min(size.width, size.height) - 10
        return availableSize / baseSize
    }
}

// MARK: - Compact Version for Smaller Displays

struct TamagotchiScreenCompact: View {
    let mood: ClaudeMood

    var body: some View {
        TamagotchiScreen(mood: mood, size: CGSize(width: 60, height: 60))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        TamagotchiScreen(mood: .idle)
        TamagotchiScreen(mood: .working)
        TamagotchiScreen(mood: .sleeping)
    }
    .padding()
    .background(Color.black)
}
