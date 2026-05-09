import Foundation

enum FeedbackGenerator {
    static let defaultFeedback = Feedback(
        warning: "",
        suggestions: [
            "Use a few words, avoid common phrases",
            "No need for symbols, digits, or uppercase letters",
        ]
    )

    static func getFeedback(score: Int, sequence: [Match]) -> Feedback {
        if sequence.isEmpty {
            return defaultFeedback
        }
        if score > 2 {
            return Feedback(warning: "", suggestions: [])
        }

        var longestMatch = sequence[0]
        for match in sequence.dropFirst() {
            if match.token.count > longestMatch.token.count {
                longestMatch = match
            }
        }

        let extraFeedback = "Add another word or two. Uncommon words are better."

        if let feedback = getMatchFeedback(match: longestMatch, isSoleMatch: sequence.count == 1) {
            var suggestions = feedback.suggestions
            suggestions.insert(extraFeedback, at: 0)
            return Feedback(
                warning: feedback.warning,
                suggestions: suggestions
            )
        } else {
            return Feedback(warning: "", suggestions: [extraFeedback])
        }
    }

    static func getMatchFeedback(match: Match, isSoleMatch: Bool) -> Feedback? {
        switch match.pattern {
        case .dictionary(let dm):
            return getDictionaryMatchFeedback(match: match, dm: dm, isSoleMatch: isSoleMatch)

        case .spatial(let sm):
            let warning = sm.turns == 1
                ? "Straight rows of keys are easy to guess"
                : "Short keyboard patterns are easy to guess"
            return Feedback(
                warning: warning,
                suggestions: ["Use a longer keyboard pattern with more turns"]
            )

        case .repeat_(let rm):
            let warning = rm.baseToken.count == 1
                ? "Repeats like \"aaa\" are easy to guess"
                : "Repeats like \"abcabcabc\" are only slightly harder to guess than \"abc\""
            return Feedback(
                warning: warning,
                suggestions: ["Avoid repeated words and characters"]
            )

        case .sequence:
            return Feedback(
                warning: "Sequences like abc or 6543 are easy to guess",
                suggestions: ["Avoid sequences"]
            )

        case .regex(let rm):
            if rm.regexName == "recent_year" {
                return Feedback(
                    warning: "Recent years are easy to guess",
                    suggestions: [
                        "Avoid recent years",
                        "Avoid years that are associated with you",
                    ]
                )
            }
            return nil

        case .date:
            return Feedback(
                warning: "Dates are often easy to guess",
                suggestions: ["Avoid dates and years that are associated with you"]
            )

        case .bruteforce:
            return nil
        }
    }

    static func getDictionaryMatchFeedback(match: Match, dm: DictionaryMatch, isSoleMatch: Bool) -> Feedback {
        var warning: String = ""
        if dm.dictionaryName == "passwords" {
            if isSoleMatch && !dm.l33t && !dm.reversed {
                if dm.rank <= 10 {
                    warning = "This is a top-10 common password"
                } else if dm.rank <= 100 {
                    warning = "This is a top-100 common password"
                } else {
                    warning = "This is a very common password"
                }
            } else if let guessesLog10 = match.guessesLog10, guessesLog10 <= 4 {
                warning = "This is similar to a commonly used password"
            }
        } else if dm.dictionaryName == "english_wikipedia" {
            if isSoleMatch {
                warning = "A word by itself is easy to guess"
            }
        } else if dm.dictionaryName == "surnames" || dm.dictionaryName == "male_names" || dm.dictionaryName == "female_names" {
            if isSoleMatch {
                warning = "Names and surnames by themselves are easy to guess"
            } else {
                warning = "Common names and surnames are easy to guess"
            }
        }

        var suggestions: [String] = []
        let word = match.token
        let range = NSRange(location: 0, length: word.count)
        if GuessEstimator.startUpper.firstMatch(in: word, range: range) != nil {
            suggestions.append("Capitalization doesn't help very much")
        } else if GuessEstimator.allUpper.firstMatch(in: word, range: range) != nil && word.lowercased() != word {
            suggestions.append("All-uppercase is almost as easy to guess as all-lowercase")
        }

        if dm.reversed && match.token.count >= 4 {
            suggestions.append("Reversed words aren't much harder to guess")
        }
        if dm.l33t {
            suggestions.append("Predictable substitutions like '@' instead of 'a' don't help very much")
        }

        return Feedback(warning: warning, suggestions: suggestions)
    }
}
