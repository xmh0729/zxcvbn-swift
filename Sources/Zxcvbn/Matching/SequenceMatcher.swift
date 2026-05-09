import Foundation

enum SequenceMatcher {
    private static let maxDelta = 5

    static func sequenceMatch(password: String) -> [Match] {
        let chars = Array(password)
        guard chars.count > 1 else { return [] }

        var result: [Match] = []
        var i = 0
        var lastDelta: Int? = nil

        func update(_ i: Int, _ j: Int, _ delta: Int) {
            if j - i > 1 || abs(delta) == 1 {
                let absDelta = abs(delta)
                if absDelta > 0 && absDelta <= maxDelta {
                    let token = String(chars[i...j])
                    let sequenceName: String
                    let sequenceSpace: Int
                    if token.allSatisfy({ $0.isLowercase && $0.isLetter }) {
                        sequenceName = "lower"
                        sequenceSpace = 26
                    } else if token.allSatisfy({ $0.isUppercase && $0.isLetter }) {
                        sequenceName = "upper"
                        sequenceSpace = 26
                    } else if token.allSatisfy({ $0.isNumber }) {
                        sequenceName = "digits"
                        sequenceSpace = 10
                    } else {
                        sequenceName = "unicode"
                        sequenceSpace = 26
                    }
                    result.append(Match(
                        pattern: .sequence(SequenceMatch(
                            sequenceName: sequenceName,
                            sequenceSpace: sequenceSpace,
                            ascending: delta > 0
                        )),
                        i: i,
                        j: j,
                        token: token
                    ))
                }
            }
        }

        for k in 1..<chars.count {
            let delta = Int(chars[k].unicodeScalars.first!.value) - Int(chars[k - 1].unicodeScalars.first!.value)
            if lastDelta == nil {
                lastDelta = delta
            }
            if delta == lastDelta { continue }
            let j = k - 1
            update(i, j, lastDelta!)
            i = j
            lastDelta = delta
        }
        update(i, chars.count - 1, lastDelta!)
        return result
    }
}
