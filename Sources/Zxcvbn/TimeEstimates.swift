import Foundation

enum TimeEstimates {
    struct AttackTimes {
        let crackTimesSeconds: CrackTimes
        let crackTimesDisplay: CrackTimesDisplay
        let score: Int
    }

    static func estimateAttackTimes(guesses: Double) -> AttackTimes {
        let crackTimesSeconds = CrackTimes(
            onlineThrottling100PerHour: guesses / (100.0 / 3600.0),
            onlineNoThrottling10PerSecond: guesses / 10.0,
            offlineSlowHashing1e4PerSecond: guesses / 1e4,
            offlineFastHashing1e10PerSecond: guesses / 1e10
        )
        let crackTimesDisplay = CrackTimesDisplay(
            onlineThrottling100PerHour: displayTime(crackTimesSeconds.onlineThrottling100PerHour),
            onlineNoThrottling10PerSecond: displayTime(crackTimesSeconds.onlineNoThrottling10PerSecond),
            offlineSlowHashing1e4PerSecond: displayTime(crackTimesSeconds.offlineSlowHashing1e4PerSecond),
            offlineFastHashing1e10PerSecond: displayTime(crackTimesSeconds.offlineFastHashing1e10PerSecond)
        )
        return AttackTimes(
            crackTimesSeconds: crackTimesSeconds,
            crackTimesDisplay: crackTimesDisplay,
            score: guessesToScore(guesses)
        )
    }

    static func guessesToScore(_ guesses: Double) -> Int {
        let delta: Double = 5
        if guesses < 1e3 + delta { return 0 }
        if guesses < 1e6 + delta { return 1 }
        if guesses < 1e8 + delta { return 2 }
        if guesses < 1e10 + delta { return 3 }
        return 4
    }

    static func displayTime(_ seconds: Double) -> String {
        let minute: Double = 60
        let hour = minute * 60
        let day = hour * 24
        let month = day * 31
        let year = month * 12
        let century = year * 100

        if seconds < 1 {
            return "less than a second"
        } else if seconds < minute {
            let base = Int(seconds.rounded())
            return "\(base) second\(base != 1 ? "s" : "")"
        } else if seconds < hour {
            let base = Int((seconds / minute).rounded())
            return "\(base) minute\(base != 1 ? "s" : "")"
        } else if seconds < day {
            let base = Int((seconds / hour).rounded())
            return "\(base) hour\(base != 1 ? "s" : "")"
        } else if seconds < month {
            let base = Int((seconds / day).rounded())
            return "\(base) day\(base != 1 ? "s" : "")"
        } else if seconds < year {
            let base = Int((seconds / month).rounded())
            return "\(base) month\(base != 1 ? "s" : "")"
        } else if seconds < century {
            let base = Int((seconds / year).rounded())
            return "\(base) year\(base != 1 ? "s" : "")"
        } else {
            return "centuries"
        }
    }
}
