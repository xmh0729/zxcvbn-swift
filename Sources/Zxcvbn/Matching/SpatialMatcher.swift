import Foundation

enum SpatialMatcher {
    private static let shiftedChars: Set<Character> = Set("~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?")

    static func spatialMatch(
        password: String,
        graphs: [String: [String: [String?]]]? = nil
    ) -> [Match] {
        let g = graphs ?? AdjacencyGraphs.allGraphs
        var matches: [Match] = []
        for (graphName, graph) in g {
            matches.append(contentsOf: spatialMatchHelper(password: password, graph: graph, graphName: graphName))
        }
        return Matcher.sorted(matches)
    }

    static func spatialMatchHelper(
        password: String,
        graph: [String: [String?]],
        graphName: String
    ) -> [Match] {
        var matches: [Match] = []
        let chars = Array(password)
        let len = chars.count
        guard len > 1 else { return [] }
        var i = 0
        while i < len - 1 {
            var j = i + 1
            var lastDirection: Int? = nil
            var turns = 0
            var shiftedCount: Int
            if (graphName == "qwerty" || graphName == "dvorak") && shiftedChars.contains(chars[i]) {
                shiftedCount = 1
            } else {
                shiftedCount = 0
            }
            while true {
                let prevChar = String(chars[j - 1])
                var found = false
                var foundDirection = -1
                var curDirection = -1
                let adjacents = graph[prevChar] ?? []

                if j < len {
                    let curChar = String(chars[j])
                    for adj in adjacents {
                        curDirection += 1
                        if let adj = adj, adj.contains(curChar) {
                            found = true
                            foundDirection = curDirection
                            if let idx = adj.firstIndex(of: Character(curChar)), adj.distance(from: adj.startIndex, to: idx) == 1 {
                                shiftedCount += 1
                            }
                            if lastDirection != foundDirection {
                                turns += 1
                                lastDirection = foundDirection
                            }
                            break
                        }
                    }
                }

                if found {
                    j += 1
                } else {
                    if j - i > 2 {
                        matches.append(Match(
                            pattern: .spatial(SpatialMatch(
                                graph: graphName,
                                turns: turns,
                                shiftedCount: shiftedCount
                            )),
                            i: i,
                            j: j - 1,
                            token: String(chars[i..<j])
                        ))
                    }
                    i = j
                    break
                }
            }
        }
        return matches
    }
}
