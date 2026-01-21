//
//  ClaudeCodeModels.swift
//  boringNotch
//
//  Created for Claude Code Notch integration
//

import Foundation

// MARK: - Session Discovery

/// Represents an active Claude Code session (IDE or terminal)
/// IDE sessions come from ~/.claude/ide/*.lock files
/// Terminal sessions are detected from recent JSONL activity in ~/.claude/projects/
struct ClaudeSession: Identifiable, Equatable {
    // Use workspace path as unique ID since multiple sessions can share the same PID (Cursor)
    var id: String { workspaceFolders.first ?? "\(pid)" }

    let pid: Int
    let workspaceFolders: [String]
    let ideName: String
    let transport: String?
    let runningInWindows: Bool?

    /// True if this is a terminal session (detected from JSONL activity, no lock file)
    let isTerminalSession: Bool

    /// For terminal sessions: the project directory key (e.g., "-Users-foo-bar")
    let terminalProjectKey: String?

    /// Derived from workspace path for project JSONL lookup
    var projectKey: String? {
        // Terminal sessions already have the project key
        if let terminalKey = terminalProjectKey {
            return terminalKey
        }
        guard let workspace = workspaceFolders.first else { return nil }
        // Convert /Users/foo/bar.baz to -Users-foo-bar-baz
        // Claude Code keeps the leading dash, so we only trim trailing dashes
        return workspace
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
    }

    /// Display name for UI (last folder component)
    var displayName: String {
        guard let workspace = workspaceFolders.first else { return "Unknown" }
        return URL(fileURLWithPath: workspace).lastPathComponent
    }

    /// Create an IDE session from lock file data
    init(pid: Int, workspaceFolders: [String], ideName: String, transport: String?, runningInWindows: Bool?) {
        self.pid = pid
        self.workspaceFolders = workspaceFolders
        self.ideName = ideName
        self.transport = transport
        self.runningInWindows = runningInWindows
        self.isTerminalSession = false
        self.terminalProjectKey = nil
    }

    /// Create a terminal session from project directory activity
    static func terminalSession(projectKey: String, workspacePath: String) -> ClaudeSession {
        ClaudeSession(
            pid: 0,  // No PID for terminal sessions
            workspaceFolders: [workspacePath],
            ideName: "Terminal",
            transport: nil,
            runningInWindows: nil,
            isTerminalSession: true,
            terminalProjectKey: projectKey
        )
    }

    /// Internal initializer for terminal sessions
    private init(pid: Int, workspaceFolders: [String], ideName: String, transport: String?, runningInWindows: Bool?, isTerminalSession: Bool, terminalProjectKey: String?) {
        self.pid = pid
        self.workspaceFolders = workspaceFolders
        self.ideName = ideName
        self.transport = transport
        self.runningInWindows = runningInWindows
        self.isTerminalSession = isTerminalSession
        self.terminalProjectKey = terminalProjectKey
    }
}

/// Codable wrapper for decoding IDE lock files
struct ClaudeSessionLockFile: Codable {
    let pid: Int
    let workspaceFolders: [String]
    let ideName: String
    let transport: String?
    let runningInWindows: Bool?

    func toSession() -> ClaudeSession {
        ClaudeSession(pid: pid, workspaceFolders: workspaceFolders, ideName: ideName, transport: transport, runningInWindows: runningInWindows)
    }
}

// MARK: - Conversation Info

/// Represents an individual conversation/tab within a project session
struct ConversationInfo: Identifiable, Equatable {
    let id: String  // UUID from JSONL filename
    let jsonlPath: URL
    let lastModified: Date
    var tokenUsage: TokenUsage
    var isActive: Bool  // Recently modified (within last 5 min)
    var title: String?  // First user message or conversation summary
    var currentTool: String?  // Currently running tool (if any)
    var isWaitingForPermission: Bool = false  // Waiting for user approval

    /// Short display ID (first 4 chars of UUID)
    var shortId: String {
        String(id.prefix(4))
    }

    /// Display title (truncated first message or short ID)
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count > 20 {
                return String(cleaned.prefix(20)) + "…"
            }
            return cleaned
        }
        return shortId
    }

    /// Short tool name for display
    var toolAbbreviation: String? {
        guard let tool = currentTool else { return nil }
        // Short readable abbreviations
        switch tool {
        case "Read": return "Rd"
        case "Write": return "Wr"
        case "Edit": return "Ed"
        case "Bash": return "Run"
        case "Glob": return "Find"    // File search
        case "Grep": return "Srch"    // Text search
        case "Task": return "Agent"
        case "WebFetch": return "Web"
        case "WebSearch": return "Web"
        case "TodoWrite": return "Todo"
        case "NotebookEdit": return "Note"
        default: return String(tool.prefix(4))
        }
    }

    /// Context percentage for this conversation
    var contextPercentage: Double {
        tokenUsage.contextPercentage
    }
}

// MARK: - Session Status (State Machine)

/// Core operational state of a Claude Code session
/// Based on XState-style state machine from claude-code-ui
enum SessionStatus: String, Equatable {
    /// Claude is actively processing (generating response or executing tools)
    case working

    /// A tool is waiting for user permission approval
    case waitingForApproval

    /// Claude finished responding, waiting for user input
    case waitingForInput

    /// No activity for extended period (session may be abandoned)
    case idle

    /// Display name for UI
    var displayName: String {
        switch self {
        case .working: return "Working"
        case .waitingForApproval: return "Needs Approval"
        case .waitingForInput: return "Ready"
        case .idle: return "Idle"
        }
    }

    /// Whether this status indicates active processing
    var isActive: Bool {
        switch self {
        case .working, .waitingForApproval: return true
        case .waitingForInput, .idle: return false
        }
    }

    /// Whether this status requires user attention
    var needsAttention: Bool {
        self == .waitingForApproval
    }
}

// MARK: - Token Usage

/// Token usage data from JSONL message.usage field
struct TokenUsage: Equatable {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheReadInputTokens: Int = 0
    var cacheCreationInputTokens: Int = 0

    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadInputTokens + cacheCreationInputTokens
    }

    /// Context window is 200k for opus-4-5
    static let contextWindow = 200_000

    var contextPercentage: Double {
        guard Self.contextWindow > 0 else { return 0 }
        return min(100, Double(totalTokens) / Double(Self.contextWindow) * 100)
    }

    // MARK: - Cost Estimation (per 1M tokens, USD)
    // Opus 4.5 pricing: $15/1M input, $75/1M output, $1.50/1M cache read, $18.75/1M cache write
    // Sonnet 4: $3/1M input, $15/1M output, $0.30/1M cache read, $3.75/1M cache write

    struct ModelPricing {
        let inputPerMillion: Double
        let outputPerMillion: Double
        let cacheReadPerMillion: Double
        let cacheWritePerMillion: Double
    }

    static let opusPricing = ModelPricing(
        inputPerMillion: 15.0,
        outputPerMillion: 75.0,
        cacheReadPerMillion: 1.50,
        cacheWritePerMillion: 18.75
    )

    static let sonnetPricing = ModelPricing(
        inputPerMillion: 3.0,
        outputPerMillion: 15.0,
        cacheReadPerMillion: 0.30,
        cacheWritePerMillion: 3.75
    )

    /// Calculate estimated cost for this session
    func estimatedCost(model: String) -> Double {
        let pricing = model.contains("opus") ? Self.opusPricing : Self.sonnetPricing

        let inputCost = Double(inputTokens) / 1_000_000 * pricing.inputPerMillion
        let outputCost = Double(outputTokens) / 1_000_000 * pricing.outputPerMillion
        let cacheReadCost = Double(cacheReadInputTokens) / 1_000_000 * pricing.cacheReadPerMillion
        let cacheWriteCost = Double(cacheCreationInputTokens) / 1_000_000 * pricing.cacheWritePerMillion

        return inputCost + outputCost + cacheReadCost + cacheWriteCost
    }
}

// MARK: - Tool Execution

/// Represents a tool call in progress or completed
struct ToolExecution: Identifiable, Equatable {
    let id: String
    let toolName: String
    let argument: String?
    let startTime: Date
    var endTime: Date?
    var isRunning: Bool { endTime == nil }

    var durationMs: Int? {
        guard let end = endTime else { return nil }
        return Int(end.timeIntervalSince(startTime) * 1000)
    }
}

// MARK: - Agent Info

/// Represents a background agent task
struct AgentInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let startTime: Date
    var isActive: Bool = true

    var durationSeconds: Int {
        Int(Date().timeIntervalSince(startTime))
    }
}

// MARK: - Todo Item

/// Claude Code todo item
struct ClaudeTodoItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let status: TodoStatus

    enum TodoStatus: String {
        case pending
        case inProgress = "in_progress"
        case completed
    }
}

// MARK: - Complete State

/// Complete Claude Code state for display
struct ClaudeCodeState: Equatable {
    var sessionId: String = ""
    var model: String = ""
    var cwd: String = ""
    var gitBranch: String = ""

    var tokenUsage: TokenUsage = TokenUsage()

    var lastMessage: String = ""
    var lastMessageTime: Date?

    var activeTools: [ToolExecution] = []
    var recentTools: [ToolExecution] = []

    var agents: [AgentInfo] = []
    var todos: [ClaudeTodoItem] = []

    var isConnected: Bool = false
    var lastUpdateTime: Date?

    /// True when Claude is waiting for user permission to execute a tool
    var needsPermission: Bool = false
    /// The tool waiting for permission (if any)
    var pendingPermissionTool: String?

    /// True when Claude is actively generating a response (thinking)
    var isThinking: Bool = false

    // Convenience accessors
    var contextPercentage: Double { tokenUsage.contextPercentage }
    var hasActiveTools: Bool { !activeTools.isEmpty }
    var currentToolName: String? { activeTools.first?.toolName }

    /// True when the session is actively processing (thinking or running tools)
    var isActive: Bool { isThinking || hasActiveTools }

    // MARK: - State Machine Status

    /// Derive the current session status from component states
    /// This is the canonical state machine status
    var status: SessionStatus {
        // Priority order matters:
        // 1. Needs permission takes precedence (user action required)
        // 2. Working (actively processing)
        // 3. Waiting for input (Claude finished, user's turn)
        // 4. Idle (no recent activity)

        if needsPermission {
            return .waitingForApproval
        }

        if isThinking || hasActiveTools {
            return .working
        }

        // If connected but not active, we're waiting for input
        if isConnected {
            return .waitingForInput
        }

        return .idle
    }

    /// Derive status with idle timeout consideration
    /// - Parameter idleThreshold: Seconds since last update to consider idle
    func status(idleThreshold: TimeInterval) -> SessionStatus {
        // Check base status first
        let baseStatus = status

        // If waiting for input and no recent activity, consider idle
        if baseStatus == .waitingForInput,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) > idleThreshold {
            return .idle
        }

        return baseStatus
    }
}

// MARK: - Daily Stats (from stats-cache.json)

/// Daily activity stats from ~/.claude/stats-cache.json
struct DailyStats: Equatable {
    var messageCount: Int = 0
    var toolCallCount: Int = 0
    var sessionCount: Int = 0
    var tokensUsed: Int = 0
    var date: String = ""

    var isEmpty: Bool {
        // Only empty if date is not set (means we haven't loaded stats yet)
        date.isEmpty
    }
}

/// Stats cache structure matching ~/.claude/stats-cache.json
struct StatsCache: Codable {
    let dailyActivity: [DailyActivity]?
    let dailyModelTokens: [DailyModelTokens]?
    let modelUsage: [String: ModelUsageStats]?
    let totalSessions: Int?
    let totalMessages: Int?

    struct DailyActivity: Codable {
        let date: String
        let messageCount: Int?
        let sessionCount: Int?
        let toolCallCount: Int?
    }

    struct DailyModelTokens: Codable {
        let date: String
        let tokensByModel: [String: Int]?
    }

    struct ModelUsageStats: Codable {
        let inputTokens: Int?
        let outputTokens: Int?
        let cacheReadInputTokens: Int?
        let cacheCreationInputTokens: Int?
    }
}

// MARK: - JSONL Parsing Helpers

/// Represents a parsed JSONL line from session log
struct SessionLogEntry {
    let type: String
    let sessionId: String?
    let model: String?
    let cwd: String?
    let gitBranch: String?
    let usage: TokenUsage?
    let messageContent: String?
    let toolUse: ToolUseInfo?
    let toolResult: ToolResultInfo?
    let timestamp: Date?
}

struct ToolUseInfo {
    let id: String
    let name: String
    let input: [String: Any]?
}

struct ToolResultInfo {
    let toolUseId: String
    let content: String?
    let isError: Bool
}
