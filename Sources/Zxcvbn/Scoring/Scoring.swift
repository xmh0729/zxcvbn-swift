import Foundation

public enum Scoring {
    static let minGuessesBeforeGrowingSequence: Double = 10000
    static let minYearSpace = 20
    static var referenceYear: Int { Calendar.current.component(.year, from: Date()) }

    static let keyboardAverageDegree: Double = {
        calcAverageDegree(AdjacencyGraphs.qwerty)
    }()
    static let keypadAverageDegree: Double = {
        calcAverageDegree(AdjacencyGraphs.keypad)
    }()
    static let keyboardStartingPositions: Int = AdjacencyGraphs.qwerty.count
    static let keypadStartingPositions: Int = AdjacencyGraphs.keypad.count

    private static func calcAverageDegree(_ graph: [String: [String?]]) -> Double {
        var average: Double = 0
        for (_, neighbors) in graph {
            average += Double(neighbors.compactMap { $0 }.count)
        }
        average /= Double(graph.count)
        return average
    }

    public struct ScoringResult {
        public let password: String
        public let guesses: Double
        public let guessesLog10: Double
        public let sequence: [Match]
    }

    public static func mostGuessableMatchSequence(
        password: String,
        matches: [Match],
        excludeAdditive: Bool = false
    ) -> ScoringResult {
        let n = password.count
        let chars = Array(password)

        guard n > 0 else {
            return ScoringResult(password: password, guesses: 1, guessesLog10: 0, sequence: [])
        }

        // Partition matches by ending index j
        var matchesByJ: [[Match]] = Array(repeating: [], count: n)
        for m in matches {
            matchesByJ[m.j].append(m)
        }
        for i in 0..<n {
            matchesByJ[i].sort { $0.i < $1.i }
        }

        // optimal.m[k][l], optimal.pi[k][l], optimal.g[k][l]
        var optimalM: [[Int: Match]] = Array(repeating: [:], count: n)
        var optimalPi: [[Int: Double]] = Array(repeating: [:], count: n)
        var optimalG: [[Int: Double]] = Array(repeating: [:], count: n)

        func makeBruteforceMatch(_ i: Int, _ j: Int) -> Match {
            Match(
                pattern: .bruteforce,
                i: i,
                j: j,
                token: String(chars[i...j])
            )
        }

        func update(_ m: Match, _ l: Int) {
            var m = m
            let k = m.j
            let pi = GuessEstimator.estimateGuesses(match: &m, password: password) * (l > 1 ? optimalPi[m.i - 1][l - 1]! : 1)
            var g = MathUtils.factorial(l) * pi
            if !excludeAdditive {
                g += pow(minGuessesBeforeGrowingSequence, Double(l - 1))
            }
            for (competingL, competingG) in optimalG[k] {
                if competingL > l { continue }
                if competingG <= g { return }
            }
            optimalG[k][l] = g
            optimalM[k][l] = m
            optimalPi[k][l] = pi
        }

        func bruteforceUpdate(_ k: Int) {
            let m = makeBruteforceMatch(0, k)
            update(m, 1)
            guard k >= 1 else { return }
            for i in 1...k {
                let m = makeBruteforceMatch(i, k)
                for (l, lastM) in optimalM[i - 1] {
                    if lastM.patternName == "bruteforce" { continue }
                    update(m, l + 1)
                }
            }
        }

        func unwind() -> [Match] {
            var optimalMatchSequence: [Match] = []
            var k = n - 1
            var l: Int? = nil
            var g = Double.infinity
            for (candidateL, candidateG) in optimalG[k] {
                if candidateG < g {
                    l = candidateL
                    g = candidateG
                }
            }
            guard var currentL = l else { return [] }
            while k >= 0 {
                let m = optimalM[k][currentL]!
                optimalMatchSequence.insert(m, at: 0)
                k = m.i - 1
                currentL -= 1
            }
            return optimalMatchSequence
        }

        for k in 0..<n {
            for m in matchesByJ[k] {
                if m.i > 0 {
                    for l in optimalM[m.i - 1].keys {
                        update(m, l + 1)
                    }
                } else {
                    update(m, 1)
                }
            }
            bruteforceUpdate(k)
        }

        let optimalMatchSequence = unwind()
        let optimalL = optimalMatchSequence.count
        let guesses = optimalG[n - 1][optimalL]!

        return ScoringResult(
            password: password,
            guesses: guesses,
            guessesLog10: MathUtils.log10(guesses),
            sequence: optimalMatchSequence
        )
    }
}
