import Foundation

enum RepeatMatcher {
    static func repeatMatch(password: String) -> [Match] {
        var matches: [Match] = []
        let greedy = try! NSRegularExpression(pattern: "(.+)\\1+")
        let lazy = try! NSRegularExpression(pattern: "(.+?)\\1+")
        let lazyAnchored = try! NSRegularExpression(pattern: "^(.+?)\\1+$")
        let nsPassword = password as NSString
        var lastIndex = 0

        while lastIndex < password.count {
            let range = NSRange(location: lastIndex, length: password.count - lastIndex)
            guard let greedyResult = greedy.firstMatch(in: password, range: range),
                  let lazyResult = lazy.firstMatch(in: password, range: range) else {
                break
            }

            let greedyFullRange = greedyResult.range
            let lazyFullRange = lazyResult.range

            let matchResult: NSTextCheckingResult
            let baseToken: String

            if greedyFullRange.length > lazyFullRange.length {
                matchResult = greedyResult
                let fullMatch = nsPassword.substring(with: greedyFullRange)
                // Run anchored lazy on greedy's match to find shortest repeated string
                if let anchoredResult = lazyAnchored.firstMatch(in: fullMatch, range: NSRange(location: 0, length: fullMatch.count)) {
                    baseToken = (fullMatch as NSString).substring(with: anchoredResult.range(at: 1))
                } else {
                    baseToken = nsPassword.substring(with: greedyResult.range(at: 1))
                }
            } else {
                matchResult = lazyResult
                baseToken = nsPassword.substring(with: lazyResult.range(at: 1))
            }

            let fullMatch = nsPassword.substring(with: matchResult.range)
            let i = matchResult.range.location
            let j = i + matchResult.range.length - 1

            // Recursively match and score the base string
            let baseAnalysis = Scoring.mostGuessableMatchSequence(
                password: baseToken,
                matches: Matcher.omnimatch(password: baseToken)
            )

            matches.append(Match(
                pattern: .repeat_(RepeatMatch(
                    baseToken: baseToken,
                    baseGuesses: baseAnalysis.guesses,
                    baseMatches: baseAnalysis.sequence,
                    repeatCount: fullMatch.count / baseToken.count
                )),
                i: i,
                j: j,
                token: fullMatch
            ))
            lastIndex = j + 1
        }
        return matches
    }
}
