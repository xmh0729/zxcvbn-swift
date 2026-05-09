import Foundation

enum RegexMatcher {
    private static let regexen: [String: NSRegularExpression] = {
        var result: [String: NSRegularExpression] = [:]
        result["recent_year"] = try! NSRegularExpression(pattern: "19\\d\\d|200\\d|201\\d")
        return result
    }()

    static func regexMatch(
        password: String,
        regexes: [String: NSRegularExpression]? = nil
    ) -> [Match] {
        let rxes = regexes ?? regexen
        var matches: [Match] = []
        let nsPassword = password as NSString
        for (name, regex) in rxes {
            let results = regex.matches(in: password, range: NSRange(location: 0, length: password.count))
            for rxMatch in results {
                let token = nsPassword.substring(with: rxMatch.range)
                var groups: [String] = []
                for g in 0..<rxMatch.numberOfRanges {
                    let r = rxMatch.range(at: g)
                    if r.location != NSNotFound {
                        groups.append(nsPassword.substring(with: r))
                    }
                }
                matches.append(Match(
                    pattern: .regex(RegexMatch(
                        regexName: name,
                        regexMatch: groups
                    )),
                    i: rxMatch.range.location,
                    j: rxMatch.range.location + rxMatch.range.length - 1,
                    token: token
                ))
            }
        }
        return Matcher.sorted(matches)
    }
}
