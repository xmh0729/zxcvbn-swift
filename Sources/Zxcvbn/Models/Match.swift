import Foundation

public enum MatchPattern {
    case dictionary(DictionaryMatch)
    case spatial(SpatialMatch)
    case repeat_(RepeatMatch)
    case sequence(SequenceMatch)
    case regex(RegexMatch)
    case date(DateMatch)
    case bruteforce
}

public struct Match {
    public var pattern: MatchPattern
    public let i: Int
    public let j: Int
    public let token: String
    public var guesses: Double?
    public var guessesLog10: Double?

    public var patternName: String {
        switch pattern {
        case .dictionary: return "dictionary"
        case .spatial: return "spatial"
        case .repeat_: return "repeat"
        case .sequence: return "sequence"
        case .regex: return "regex"
        case .date: return "date"
        case .bruteforce: return "bruteforce"
        }
    }
}

public struct DictionaryMatch {
    public var matchedWord: String
    public var rank: Int
    public var dictionaryName: String
    public var reversed: Bool
    public var l33t: Bool
    public var sub: [Character: Character]
    public var subDisplay: String?
    public var baseGuesses: Double?
    public var uppercaseVariations: Double?
    public var l33tVariations: Double?
}

public struct SpatialMatch {
    public let graph: String
    public let turns: Int
    public let shiftedCount: Int
}

public struct RepeatMatch {
    public let baseToken: String
    public let baseGuesses: Double
    public let baseMatches: [Match]
    public let repeatCount: Int
}

public struct SequenceMatch {
    public let sequenceName: String
    public let sequenceSpace: Int
    public let ascending: Bool
}

public struct RegexMatch {
    public let regexName: String
    public let regexMatch: [String]
}

public struct DateMatch {
    public let separator: String
    public let year: Int
    public let month: Int
    public let day: Int
}
