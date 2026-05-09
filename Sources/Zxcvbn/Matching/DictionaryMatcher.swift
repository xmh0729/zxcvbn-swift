import Foundation

enum DictionaryMatcher {
    static let l33tTable: [Character: [Character]] = [
        "a": ["4", "@"],
        "b": ["8"],
        "c": ["(", "{", "[", "<"],
        "e": ["3"],
        "g": ["6", "9"],
        "i": ["1", "!", "|"],
        "l": ["1", "|", "7"],
        "o": ["0"],
        "s": ["$", "5"],
        "t": ["+", "7"],
        "x": ["%"],
        "z": ["2"],
    ]

    // MARK: - Dictionary Match

    static func dictionaryMatch(
        password: String,
        rankedDictionaries: [String: [String: Int]]? = nil
    ) -> [Match] {
        let dicts = rankedDictionaries ?? FrequencyLists.rankedDictionaries
        var matches: [Match] = []
        let chars = Array(password)
        let len = chars.count
        let passwordLower = password.lowercased()
        let lowerChars = Array(passwordLower)

        for (dictionaryName, rankedDict) in dicts {
            for i in 0..<len {
                for j in i..<len {
                    let word = String(lowerChars[i...j])
                    if let rank = rankedDict[word] {
                        let token = String(chars[i...j])
                        matches.append(Match(
                            pattern: .dictionary(DictionaryMatch(
                                matchedWord: word,
                                rank: rank,
                                dictionaryName: dictionaryName,
                                reversed: false,
                                l33t: false,
                                sub: [:],
                                subDisplay: nil,
                                baseGuesses: nil,
                                uppercaseVariations: nil,
                                l33tVariations: nil
                            )),
                            i: i,
                            j: j,
                            token: token
                        ))
                    }
                }
            }
        }
        return Matcher.sorted(matches)
    }

    // MARK: - Reverse Dictionary Match

    static func reverseDictionaryMatch(
        password: String,
        rankedDictionaries: [String: [String: Int]]? = nil
    ) -> [Match] {
        let reversedPassword = String(password.reversed())
        var matches = dictionaryMatch(password: reversedPassword, rankedDictionaries: rankedDictionaries)
        let len = password.count
        matches = matches.map { match in
            var m = match
            let reversedToken = String(match.token.reversed())
            let newI = len - 1 - match.j
            let newJ = len - 1 - match.i
            m = Match(
                pattern: {
                    if case .dictionary(var dm) = match.pattern {
                        dm.reversed = true
                        return .dictionary(dm)
                    }
                    return match.pattern
                }(),
                i: newI,
                j: newJ,
                token: reversedToken
            )
            return m
        }
        return Matcher.sorted(matches)
    }

    // MARK: - L33t Match

    static func relevantL33tSubtable(password: String, table: [Character: [Character]]) -> [Character: [Character]] {
        let passwordChars = Set(password)
        var subtable: [Character: [Character]] = [:]
        for (letter, subs) in table {
            let relevantSubs = subs.filter { passwordChars.contains($0) }
            if !relevantSubs.isEmpty {
                subtable[letter] = relevantSubs
            }
        }
        return subtable
    }

    static func enumerateL33tSubs(table: [Character: [Character]]) -> [[Character: Character]] {
        let keys = Array(table.keys).sorted()
        var subs: [[[Character]]] = [[]]

        func dedup(_ subs: [[[Character]]]) -> [[[Character]]] {
            var deduped: [[[Character]]] = []
            var members: Set<String> = []
            for sub in subs {
                let assoc = sub.sorted { a, b in
                    if a[0] == b[0] { return a[1] < b[1] }
                    return a[0] < b[0]
                }
                let label = assoc.map { "\($0[0]),\($0[1])" }.joined(separator: "-")
                if !members.contains(label) {
                    members.insert(label)
                    deduped.append(sub)
                }
            }
            return deduped
        }

        func helper(_ keys: ArraySlice<Character>) {
            guard let firstKey = keys.first else { return }
            let restKeys = keys.dropFirst()
            var nextSubs: [[[Character]]] = []
            for l33tChr in table[firstKey]! {
                for sub in subs {
                    var dupL33tIndex = -1
                    for i in 0..<sub.count {
                        if sub[i][0] == l33tChr {
                            dupL33tIndex = i
                            break
                        }
                    }
                    if dupL33tIndex == -1 {
                        let subExtension = sub + [[l33tChr, firstKey]]
                        nextSubs.append(subExtension)
                    } else {
                        var subAlternative = sub
                        subAlternative.remove(at: dupL33tIndex)
                        subAlternative.append([l33tChr, firstKey])
                        nextSubs.append(sub)
                        nextSubs.append(subAlternative)
                    }
                }
            }
            subs = dedup(nextSubs)
            helper(restKeys)
        }

        helper(keys[...])

        return subs.map { sub in
            var dict: [Character: Character] = [:]
            for pair in sub {
                dict[pair[0]] = pair[1]
            }
            return dict
        }
    }

    static func l33tMatch(
        password: String,
        rankedDictionaries: [String: [String: Int]]? = nil,
        l33tTable: [Character: [Character]]? = nil
    ) -> [Match] {
        let table = l33tTable ?? self.l33tTable
        var matches: [Match] = []
        let chars = Array(password)

        for sub in enumerateL33tSubs(table: relevantL33tSubtable(password: password, table: table)) {
            if sub.isEmpty { break }
            let subbedPassword = String(chars.map { sub[$0] ?? $0 })
            for match in dictionaryMatch(password: subbedPassword, rankedDictionaries: rankedDictionaries) {
                let token = String(chars[match.i...match.j])
                if token.lowercased() == {
                    if case .dictionary(let dm) = match.pattern { return dm.matchedWord }
                    return ""
                }() {
                    continue
                }
                // Build the subset of sub that's in use for this match
                var matchSub: [Character: Character] = [:]
                for (subbedChr, chr) in sub {
                    if token.contains(subbedChr) {
                        matchSub[subbedChr] = chr
                    }
                }
                let subDisplay = matchSub.map { "\($0.key) -> \($0.value)" }.joined(separator: ", ")

                if case .dictionary(var dm) = match.pattern {
                    dm.l33t = true
                    dm.sub = matchSub
                    dm.subDisplay = subDisplay
                    matches.append(Match(
                        pattern: .dictionary(dm),
                        i: match.i,
                        j: match.j,
                        token: token
                    ))
                }
            }
        }
        return Matcher.sorted(matches.filter { $0.token.count > 1 })
    }
}
