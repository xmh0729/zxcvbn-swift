import Foundation

enum GuessEstimator {
    private static let bruteforceCardinality: Double = 10
    private static let minSubmatchGuessesSingleChar: Double = 10
    private static let minSubmatchGuessesMultiChar: Double = 50

    static func estimateGuesses(match: inout Match, password: String) -> Double {
        if let g = match.guesses { return g }
        var minGuesses: Double = 1
        if match.token.count < password.count {
            minGuesses = match.token.count == 1
                ? minSubmatchGuessesSingleChar
                : minSubmatchGuessesMultiChar
        }
        let guesses: Double
        switch match.pattern {
        case .bruteforce:
            guesses = bruteforceGuesses(match: match)
        case .dictionary:
            guesses = dictionaryGuesses(match: &match)
        case .spatial:
            guesses = spatialGuesses(match: match)
        case .repeat_:
            guesses = repeatGuesses(match: match)
        case .sequence:
            guesses = sequenceGuesses(match: match)
        case .regex:
            guesses = regexGuesses(match: match)
        case .date:
            guesses = dateGuesses(match: match)
        }
        match.guesses = max(guesses, minGuesses)
        match.guessesLog10 = MathUtils.log10(match.guesses!)
        return match.guesses!
    }

    // MARK: - Bruteforce

    static func bruteforceGuesses(match: Match) -> Double {
        var guesses = pow(bruteforceCardinality, Double(match.token.count))
        if guesses == Double.infinity {
            guesses = Double.greatestFiniteMagnitude
        }
        let minGuesses: Double = match.token.count == 1
            ? minSubmatchGuessesSingleChar + 1
            : minSubmatchGuessesMultiChar + 1
        return max(guesses, minGuesses)
    }

    // MARK: - Repeat

    static func repeatGuesses(match: Match) -> Double {
        guard case .repeat_(let rm) = match.pattern else { return 0 }
        return rm.baseGuesses * Double(rm.repeatCount)
    }

    // MARK: - Sequence

    static func sequenceGuesses(match: Match) -> Double {
        guard case .sequence(let sm) = match.pattern else { return 0 }
        let firstChr = match.token.first!
        var baseGuesses: Double
        if "aAzZ01".contains(firstChr) || firstChr == "9" {
            baseGuesses = 4
        } else if firstChr.isNumber {
            baseGuesses = 10
        } else {
            baseGuesses = 26
        }
        if !sm.ascending {
            baseGuesses *= 2
        }
        return baseGuesses * Double(match.token.count)
    }

    // MARK: - Regex

    static func regexGuesses(match: Match) -> Double {
        guard case .regex(let rm) = match.pattern else { return 0 }
        let charClassBases: [String: Double] = [
            "alpha_lower": 26,
            "alpha_upper": 26,
            "alpha": 52,
            "alphanumeric": 62,
            "digits": 10,
            "symbols": 33,
        ]
        if let base = charClassBases[rm.regexName] {
            return pow(base, Double(match.token.count))
        }
        switch rm.regexName {
        case "recent_year":
            let year = Int(rm.regexMatch[0]) ?? Scoring.referenceYear
            var yearSpace = Double(abs(year - Scoring.referenceYear))
            yearSpace = max(yearSpace, Double(Scoring.minYearSpace))
            return yearSpace
        default:
            return 0
        }
    }

    // MARK: - Date

    static func dateGuesses(match: Match) -> Double {
        guard case .date(let dm) = match.pattern else { return 0 }
        var yearSpace = Double(abs(dm.year - Scoring.referenceYear))
        yearSpace = max(yearSpace, Double(Scoring.minYearSpace))
        var guesses = yearSpace * 365
        if !dm.separator.isEmpty {
            guesses *= 4
        }
        return guesses
    }

    // MARK: - Spatial

    static func spatialGuesses(match: Match) -> Double {
        guard case .spatial(let sm) = match.pattern else { return 0 }
        let s: Double
        let d: Double
        if sm.graph == "qwerty" || sm.graph == "dvorak" {
            s = Double(Scoring.keyboardStartingPositions)
            d = Scoring.keyboardAverageDegree
        } else {
            s = Double(Scoring.keypadStartingPositions)
            d = Scoring.keypadAverageDegree
        }
        var guesses: Double = 0
        let L = match.token.count
        let t = sm.turns
        for i in 2...L {
            let possibleTurns = min(t, i - 1)
            for j in 1...possibleTurns {
                guesses += MathUtils.nCk(i - 1, j - 1) * s * pow(d, Double(j))
            }
        }
        if sm.shiftedCount > 0 {
            let S = sm.shiftedCount
            let U = match.token.count - S
            if S == 0 || U == 0 {
                guesses *= 2
            } else {
                var shiftedVariations: Double = 0
                for i in 1...min(S, U) {
                    shiftedVariations += MathUtils.nCk(S + U, i)
                }
                guesses *= shiftedVariations
            }
        }
        return guesses
    }

    // MARK: - Dictionary

    static func dictionaryGuesses(match: inout Match) -> Double {
        guard case .dictionary(var dm) = match.pattern else { return 0 }
        dm.baseGuesses = Double(dm.rank)
        dm.uppercaseVariations = uppercaseVariations(match: match)
        dm.l33tVariations = l33tVariations(match: match)
        let reversedVariations: Double = dm.reversed ? 2 : 1
        let result = Double(dm.rank) * dm.uppercaseVariations! * dm.l33tVariations! * reversedVariations
        match.pattern = .dictionary(dm)
        return result
    }

    // MARK: - Uppercase Variations

    static let startUpper = try! NSRegularExpression(pattern: "^[A-Z][^A-Z]+$")
    static let endUpper = try! NSRegularExpression(pattern: "^[^A-Z]+[A-Z]$")
    static let allUpper = try! NSRegularExpression(pattern: "^[^a-z]+$")
    static let allLower = try! NSRegularExpression(pattern: "^[^A-Z]+$")

    static func uppercaseVariations(match: Match) -> Double {
        let word = match.token
        let range = NSRange(location: 0, length: word.count)
        if allLower.firstMatch(in: word, range: range) != nil || word.lowercased() == word {
            return 1
        }
        for regex in [startUpper, endUpper, allUpper] {
            if regex.firstMatch(in: word, range: range) != nil {
                return 2
            }
        }
        let U = Double(word.filter { $0.isUppercase }.count)
        let L = Double(word.filter { $0.isLowercase }.count)
        var variations: Double = 0
        for i in 1...Int(min(U, L)) {
            variations += MathUtils.nCk(Int(U + L), i)
        }
        return variations
    }

    // MARK: - L33t Variations

    static func l33tVariations(match: Match) -> Double {
        guard case .dictionary(let dm) = match.pattern else { return 1 }
        if !dm.l33t { return 1 }
        var variations: Double = 1
        let chrs = Array(match.token.lowercased())
        for (subbed, unsubbed) in dm.sub {
            let S = chrs.filter { $0 == subbed }.count
            let U = chrs.filter { $0 == unsubbed }.count
            if S == 0 || U == 0 {
                variations *= 2
            } else {
                let p = min(U, S)
                var possibilities: Double = 0
                for i in 1...p {
                    possibilities += MathUtils.nCk(U + S, i)
                }
                variations *= possibilities
            }
        }
        return variations
    }
}
