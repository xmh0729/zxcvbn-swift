import Foundation

enum DateMatcher {
    static let dateMaxYear = 2050
    static let dateMinYear = 1000
    static let dateSplits: [Int: [[Int]]] = [
        4: [[1, 2], [2, 3]],
        5: [[1, 3], [2, 3]],
        6: [[1, 2], [2, 4], [4, 5]],
        7: [[1, 3], [2, 3], [4, 5], [4, 6]],
        8: [[2, 4], [4, 6]],
    ]

    static func dateMatch(password: String) -> [Match] {
        let chars = Array(password)
        let len = chars.count
        var matches: [Match] = []

        let maybeDateNoSep = try! NSRegularExpression(pattern: "^\\d{4,8}$")
        let maybeDateWithSep = try! NSRegularExpression(pattern: "^(\\d{1,4})([\\s/\\\\_.-])(\\d{1,2})\\2(\\d{1,4})$")

        // Dates without separators
        guard len >= 4 else { return [] }
        for i in 0...(len - 4) {
            for j in (i + 3)...min(i + 7, len - 1) {
                let token = String(chars[i...j])
                let tokenRange = NSRange(location: 0, length: token.count)
                guard maybeDateNoSep.firstMatch(in: token, range: tokenRange) != nil else { continue }

                var candidates: [(year: Int, month: Int, day: Int)] = []
                guard let splits = dateSplits[token.count] else { continue }
                for split in splits {
                    let k = split[0]
                    let l = split[1]
                    let ints = [
                        Int(String(Array(token)[0..<k]))!,
                        Int(String(Array(token)[k..<l]))!,
                        Int(String(Array(token)[l...]))!,
                    ]
                    if let dmy = mapIntsToDmy(ints) {
                        candidates.append(dmy)
                    }
                }
                guard !candidates.isEmpty else { continue }

                var bestCandidate = candidates[0]
                var minDistance = abs(bestCandidate.year - Scoring.referenceYear)
                for candidate in candidates.dropFirst() {
                    let distance = abs(candidate.year - Scoring.referenceYear)
                    if distance < minDistance {
                        bestCandidate = candidate
                        minDistance = distance
                    }
                }

                matches.append(Match(
                    pattern: .date(DateMatch(
                        separator: "",
                        year: bestCandidate.year,
                        month: bestCandidate.month,
                        day: bestCandidate.day
                    )),
                    i: i,
                    j: j,
                    token: token
                ))
            }
        }

        // Dates with separators
        if len >= 6 {
            for i in 0...(len - 6) {
                for j in (i + 5)...min(i + 9, len - 1) {
                    let token = String(chars[i...j])
                    let nsToken = token as NSString
                    let tokenRange = NSRange(location: 0, length: token.count)
                    guard let rxMatch = maybeDateWithSep.firstMatch(in: token, range: tokenRange) else { continue }
                    let ints = [
                        Int(nsToken.substring(with: rxMatch.range(at: 1)))!,
                        Int(nsToken.substring(with: rxMatch.range(at: 3)))!,
                        Int(nsToken.substring(with: rxMatch.range(at: 4)))!,
                    ]
                    guard let dmy = mapIntsToDmy(ints) else { continue }
                    matches.append(Match(
                        pattern: .date(DateMatch(
                            separator: nsToken.substring(with: rxMatch.range(at: 2)),
                            year: dmy.year,
                            month: dmy.month,
                            day: dmy.day
                        )),
                        i: i,
                        j: j,
                        token: token
                    ))
                }
            }
        }

        // Filter submatches
        return Matcher.sorted(matches.filter { match in
            !matches.contains { other in
                if other.i == match.i && other.j == match.j && other.token == match.token {
                    return false
                }
                return other.i <= match.i && other.j >= match.j
            }
        })
    }

    static func mapIntsToDmy(_ ints: [Int]) -> (year: Int, month: Int, day: Int)? {
        guard ints[1] <= 31, ints[1] > 0 else { return nil }

        var over12 = 0
        var over31 = 0
        var under1 = 0
        for val in ints {
            if (val > 99 && val < dateMinYear) || val > dateMaxYear { return nil }
            if val > 31 { over31 += 1 }
            if val > 12 { over12 += 1 }
            if val <= 0 { under1 += 1 }
        }
        guard over31 < 2, over12 < 3, under1 < 2 else { return nil }

        let possibleYearSplits: [(y: Int, rest: [Int])] = [
            (ints[2], [ints[0], ints[1]]),
            (ints[0], [ints[1], ints[2]]),
        ]

        for (y, rest) in possibleYearSplits {
            if y >= dateMinYear && y <= dateMaxYear {
                if let dm = mapIntsToDm(rest) {
                    return (year: y, month: dm.month, day: dm.day)
                } else {
                    return nil
                }
            }
        }

        for (y, rest) in possibleYearSplits {
            if let dm = mapIntsToDm(rest) {
                return (year: twoToFourDigitYear(y), month: dm.month, day: dm.day)
            }
        }

        return nil
    }

    static func mapIntsToDm(_ ints: [Int]) -> (day: Int, month: Int)? {
        for (d, m) in [(ints[0], ints[1]), (ints[1], ints[0])] {
            if d >= 1 && d <= 31 && m >= 1 && m <= 12 {
                return (day: d, month: m)
            }
        }
        return nil
    }

    static func twoToFourDigitYear(_ year: Int) -> Int {
        if year > 99 {
            return year
        } else if year > 50 {
            return year + 1900
        } else {
            return year + 2000
        }
    }
}
