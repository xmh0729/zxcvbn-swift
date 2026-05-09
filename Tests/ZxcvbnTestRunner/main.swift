import Zxcvbn
import Foundation

// 调查 tr0ub4dor&3 的匹配详情
let pw = "tr0ub4dor&3"

print("=== Swift zxcvbn result for '\(pw)' ===")
let r = zxcvbn(password: pw)
print("score: \(r.score)")
print("guesses: \(r.guesses)")
print("guessesLog10: \(r.guessesLog10)")
print("sequence length: \(r.sequence.count)")

for (i, m) in r.sequence.enumerated() {
    print("  match \(i): token='\(m.token)' i=\(m.i) j=\(m.j) guesses=\(m.guesses ?? -1)")
    switch m.pattern {
    case .dictionary(let dm):
        print("    pattern=dictionary word='\(dm.matchedWord)' rank=\(dm.rank) dict='\(dm.dictionaryName)' l33t=\(dm.l33t) reversed=\(dm.reversed) sub='\(dm.subDisplay ?? "")' baseGuesses=\(dm.baseGuesses ?? -1) upperVar=\(dm.uppercaseVariations ?? -1) l33tVar=\(dm.l33tVariations ?? -1)")
    case .spatial(let sm):
        print("    pattern=spatial graph='\(sm.graph)' turns=\(sm.turns) shifted=\(sm.shiftedCount)")
    case .sequence(let sm):
        print("    pattern=sequence name='\(sm.sequenceName)' space=\(sm.sequenceSpace) asc=\(sm.ascending)")
    case .repeat_(let rm):
        print("    pattern=repeat base='\(rm.baseToken)' count=\(rm.repeatCount)")
    case .regex(let rm):
        print("    pattern=regex name='\(rm.regexName)'")
    case .date(let dm):
        print("    pattern=date \(dm.year)-\(dm.month)-\(dm.day) sep='\(dm.separator)'")
    case .bruteforce:
        print("    pattern=bruteforce")
    }
}

// 也单独看 omnimatch 找到了多少匹配
let allMatches = Matcher.omnimatch(password: pw)
print("\n=== All omnimatch results (\(allMatches.count) matches) ===")
var patternCounts: [String: Int] = [:]
for m in allMatches {
    let name: String
    switch m.pattern {
    case .dictionary(let dm):
        name = dm.l33t ? "dictionary(l33t)" : (dm.reversed ? "dictionary(reversed)" : "dictionary")
        if dm.l33t {
            print("  L33T: token='\(m.token)' word='\(dm.matchedWord)' rank=\(dm.rank) dict='\(dm.dictionaryName)' sub='\(dm.subDisplay ?? "")'")
        }
    case .spatial(_): name = "spatial"
    case .sequence(_): name = "sequence"
    case .repeat_(_): name = "repeat"
    case .regex(_): name = "regex"
    case .date(_): name = "date"
    case .bruteforce: name = "bruteforce"
    }
    patternCounts[name, default: 0] += 1
}
print("patterns:", patternCounts)

// 用字典匹配间接检查 troubadour 是否在频率表
print("\n=== Checking if troubadour/troubador in dictionaries ===")
let troubadorMatches = Matcher.omnimatch(password: "troubadour")
for m in troubadorMatches {
    if case .dictionary(let dm) = m.pattern, m.token.lowercased() == "troubadour" {
        print("  'troubadour' found: dict='\(dm.dictionaryName)' rank=\(dm.rank)")
    }
}
let troubador2 = Matcher.omnimatch(password: "troubador")
for m in troubador2 {
    if case .dictionary(let dm) = m.pattern, m.token.lowercased() == "troubador" {
        print("  'troubador' found: dict='\(dm.dictionaryName)' rank=\(dm.rank)")
    }
}
