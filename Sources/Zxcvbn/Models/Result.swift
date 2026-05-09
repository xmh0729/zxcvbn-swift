import Foundation

public struct ZxcvbnResult {
    public let password: String
    public let guesses: Double
    public let guessesLog10: Double
    public let crackTimesSeconds: CrackTimes
    public let crackTimesDisplay: CrackTimesDisplay
    public let score: Int
    public let feedback: Feedback
    public let sequence: [Match]
    public let calcTime: TimeInterval
}

public struct CrackTimes {
    public let onlineThrottling100PerHour: Double
    public let onlineNoThrottling10PerSecond: Double
    public let offlineSlowHashing1e4PerSecond: Double
    public let offlineFastHashing1e10PerSecond: Double
}

public struct CrackTimesDisplay {
    public let onlineThrottling100PerHour: String
    public let onlineNoThrottling10PerSecond: String
    public let offlineSlowHashing1e4PerSecond: String
    public let offlineFastHashing1e10PerSecond: String
}

public struct Feedback {
    public let warning: String
    public let suggestions: [String]
}
