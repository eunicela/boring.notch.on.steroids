//
//  TamagotchiStatsPanel.swift
//  boringNotch
//
//  Stats panel showing model, session, and conversation list with context bars
//

import SwiftUI

struct TamagotchiStatsPanel: View {
    let state: ClaudeCodeState?
    let session: ClaudeSession?
    let conversations: [ConversationInfo]

    // Grid layout: 2 columns for conversation list
    private let maxConversationsPerColumn = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Model + Branch
            modelBranchRow

            // Session name
            sessionRow

            // Conversation list (flows into 2 columns)
            conversationGrid
        }
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .foregroundColor(.white.opacity(0.9))
    }

    // MARK: - Header Rows

    private var modelBranchRow: some View {
        HStack(spacing: 6) {
            Text(modelDisplayName)
                .foregroundColor(modelColor)
            if let branch = state?.gitBranch, !branch.isEmpty {
                Text("•")
                    .foregroundColor(.white.opacity(0.4))
                HStack(spacing: 2) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 7))
                    Text(branchDisplayName(branch))
                }
                .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
    }

    private var sessionRow: some View {
        HStack(spacing: 4) {
            Text("Sess:")
                .foregroundColor(.white.opacity(0.6))
            Text(sessionDisplayName)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            Spacer()
        }
    }

    // MARK: - Conversation Grid

    private var conversationGrid: some View {
        let leftColumn = Array(conversations.prefix(maxConversationsPerColumn))
        let rightColumn = Array(conversations.dropFirst(maxConversationsPerColumn).prefix(maxConversationsPerColumn))

        return HStack(alignment: .top, spacing: 12) {
            // Left column
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(leftColumn.enumerated()), id: \.element.id) { index, conv in
                    conversationRow(conv, index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right column (if overflow)
            if !rightColumn.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(rightColumn.enumerated()), id: \.element.id) { index, conv in
                        conversationRow(conv, index: index + maxConversationsPerColumn)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func conversationRow(_ conv: ConversationInfo, index: Int) -> some View {
        HStack(spacing: 4) {
            // Tab name (shortened title from first message)
            Text(conv.displayTitle)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)

            // Context progress bar
            PixelProgressBar(
                progress: conv.contextPercentage / 100.0,
                fillColor: contextColor(for: conv.contextPercentage),
                backgroundColor: Color.gray.opacity(0.3),
                height: 6,
                pixelSize: 2
            )
            .frame(width: 28)

            // Percentage
            Text(String(format: "%2.0f%%", conv.contextPercentage))
                .foregroundColor(contextColor(for: conv.contextPercentage))
                .frame(width: 26, alignment: .trailing)

            // Status indicator: waiting for permission, running tool, or active
            if conv.isWaitingForPermission {
                Text("?")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                    .frame(minWidth: 14, alignment: .trailing)
            } else if let toolAbbr = conv.toolAbbreviation {
                Text(toolAbbr)
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
                    .frame(minWidth: 14, alignment: .trailing)
            } else if conv.isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: 4)
                    .frame(width: 14)
            } else {
                Spacer()
                    .frame(width: 14)
            }
        }
    }

    // MARK: - Computed Values

    private var modelDisplayName: String {
        guard let model = state?.model else { return "-" }
        if model.contains("opus") { return "Opus" }
        if model.contains("sonnet") { return "Sonnet" }
        if model.contains("haiku") { return "Haiku" }
        return String(model.prefix(8))
    }

    private var modelColor: Color {
        guard let model = state?.model else { return .gray }
        if model.contains("opus") { return .orange }
        if model.contains("sonnet") { return .purple }
        if model.contains("haiku") { return .cyan }
        return .white
    }

    private var sessionDisplayName: String {
        guard let session = session else { return "-" }
        let name = session.displayName
        if name.count > 20 {
            return String(name.prefix(20)) + "…"
        }
        return name
    }

    private func branchDisplayName(_ branch: String) -> String {
        if branch.count > 12 {
            return String(branch.prefix(12)) + "…"
        }
        return branch
    }

    private func contextColor(for percentage: Double) -> Color {
        if percentage > 90 { return .red }
        if percentage > 75 { return .orange }
        if percentage > 50 { return .yellow }
        return .green
    }
}

// MARK: - Preview

#Preview {
    TamagotchiStatsPanel(
        state: nil,
        session: nil,
        conversations: []
    )
    .padding()
    .background(Color.black)
}
