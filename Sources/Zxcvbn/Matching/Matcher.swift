import Foundation

public enum Matcher {
    static func sorted(_ matches: [Match]) -> [Match] {
        matches.sorted { m1, m2 in
            if m1.i != m2.i { return m1.i < m2.i }
            return m1.j < m2.j
        }
    }

    public static func omnimatch(password: String) -> [Match] {
        var matches: [Match] = []
        matches.append(contentsOf: DictionaryMatcher.dictionaryMatch(password: password))
        matches.append(contentsOf: DictionaryMatcher.reverseDictionaryMatch(password: password))
        matches.append(contentsOf: DictionaryMatcher.l33tMatch(password: password))
        matches.append(contentsOf: SpatialMatcher.spatialMatch(password: password))
        matches.append(contentsOf: RepeatMatcher.repeatMatch(password: password))
        matches.append(contentsOf: SequenceMatcher.sequenceMatch(password: password))
        matches.append(contentsOf: RegexMatcher.regexMatch(password: password))
        matches.append(contentsOf: DateMatcher.dateMatch(password: password))
        return sorted(matches)
    }
}
