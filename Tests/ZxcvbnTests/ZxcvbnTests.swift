// Standalone test runner - no XCTest dependency needed
import Zxcvbn
import Foundation

var passed = 0
var failed = 0
var errors: [String] = []

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        let e = "FAIL [\(file.split(separator: "/").last ?? ""):\(line)] \(message)"
        errors.append(e)
        print("  ✗ \(message)")
    }
}

func section(_ name: String) {
    print("\n── \(name) ──")
}

// ============================================================
// 1. 主入口 API
// ============================================================
section("主入口 API")

do {
    let r = zxcvbn(password: "")
    assert(r.score == 0, "空密码得分应为0, 实际=\(r.score)")
    assert(r.guesses == 1, "空密码猜测数应为1, 实际=\(r.guesses)")
    assert(r.sequence.isEmpty, "空密码序列应为空")
    print("  ✓ 空密码")
}

do {
    let r = zxcvbn(password: "password")
    assert(r.score == 0, "常见密码 'password' 得分应为0, 实际=\(r.score)")
    assert(r.guesses < 1000, "常见密码猜测数应<1000, 实际=\(r.guesses)")
    print("  ✓ 弱密码 'password'")
}

do {
    let r = zxcvbn(password: "8j$&Qm!Xz@Lp3rW9")
    assert(r.score >= 3, "强密码得分应>=3, 实际=\(r.score)")
    print("  ✓ 强密码")
}

do {
    let passwords = ["", "a", "123", "password", "tr0ub4dor&3", "correcthorsebatterystaple", "8j$&Qm!Xz@Lp3rW9"]
    var allInRange = true
    for pw in passwords {
        let r = zxcvbn(password: pw)
        if !(0...4).contains(r.score) { allInRange = false }
    }
    assert(allInRange, "所有密码得分应在 0-4 范围内")
    print("  ✓ 得分范围 0-4")
}

do {
    let r = zxcvbn(password: "test123")
    assert(r.password == "test123", "结果应保存原密码")
    assert(r.guesses > 0, "猜测数应>0")
    assert(r.guessesLog10 > 0, "guessesLog10应>0")
    assert(r.crackTimesSeconds.onlineThrottling100PerHour > 0, "在线限流时间应>0")
    assert(r.crackTimesSeconds.onlineNoThrottling10PerSecond > 0, "在线无限流时间应>0")
    assert(r.crackTimesSeconds.offlineSlowHashing1e4PerSecond > 0, "离线慢哈希时间应>0")
    assert(r.crackTimesSeconds.offlineFastHashing1e10PerSecond > 0, "离线快哈希时间应>0")
    assert(!r.crackTimesDisplay.onlineThrottling100PerHour.isEmpty, "显示时间不应为空")
    assert(r.calcTime > 0, "计算时间应>0")
    print("  ✓ 结果字段完整性")
}

do {
    let without = zxcvbn(password: "jackson5")
    let with_ = zxcvbn(password: "jackson5", userInputs: ["jackson", "jackson5"])
    assert(with_.score <= without.score, "含用户输入时分数应<=不含时 (\(with_.score) vs \(without.score))")
    print("  ✓ 用户自定义词降低评分")
}

// ============================================================
// 2. Dictionary Matcher
// ============================================================
section("Dictionary Matcher")

do {
    let matches = DictionaryMatcher.dictionaryMatch(password: "password")
    let tokens = matches.map { $0.token.lowercased() }
    assert(tokens.contains("password"), "应匹配常见密码 'password'")
    print("  ✓ 识别常见密码")
}

do {
    let matches = DictionaryMatcher.dictionaryMatch(password: "abcpassword123")
    let tokens = matches.map { $0.token.lowercased() }
    assert(tokens.contains("password"), "应在子串中找到 'password'")
    print("  ✓ 子串匹配")
}

do {
    let matches = DictionaryMatcher.reverseDictionaryMatch(password: "drowssap")
    let hasReversed = matches.contains { m in
        if case .dictionary(let dm) = m.pattern { return dm.reversed && dm.matchedWord == "password" }
        return false
    }
    assert(hasReversed, "应识别反转密码 'drowssap'")
    print("  ✓ 反转词匹配")
}

do {
    let matches = DictionaryMatcher.l33tMatch(password: "p@ssw0rd")
    let hasL33t = matches.contains { m in
        if case .dictionary(let dm) = m.pattern { return dm.l33t }
        return false
    }
    assert(hasL33t, "应识别 l33t 密码 'p@ssw0rd'")
    print("  ✓ L33t 替换匹配")
}

// ============================================================
// 3. Spatial Matcher
// ============================================================
section("Spatial Matcher")

do {
    let matches = SpatialMatcher.spatialMatch(password: "qwerty")
    let hasQwerty = matches.contains { m in
        if case .spatial(let sm) = m.pattern { return sm.graph == "qwerty" }
        return false
    }
    assert(hasQwerty, "应识别 qwerty 键盘模式")
    print("  ✓ qwerty 键盘模式")
}

do {
    let matches = SpatialMatcher.spatialMatch(password: "zxcvbn")
    let hasSpatial = matches.contains { m in
        if case .spatial(_) = m.pattern { return true }
        return false
    }
    assert(hasSpatial, "应识别 zxcvbn 键盘模式")
    print("  ✓ zxcvbn 键盘模式")
}

// ============================================================
// 4. Sequence Matcher
// ============================================================
section("Sequence Matcher")

do {
    let matches = SequenceMatcher.sequenceMatch(password: "abcdef")
    let hasAsc = matches.contains { m in
        if case .sequence(let sm) = m.pattern { return sm.ascending }
        return false
    }
    assert(hasAsc, "应识别升序序列 'abcdef'")
    print("  ✓ 字母升序序列")
}

do {
    let matches = SequenceMatcher.sequenceMatch(password: "123456")
    let hasSeq = matches.contains { m in
        if case .sequence(_) = m.pattern { return true }
        return false
    }
    assert(hasSeq, "应识别数字序列 '123456'")
    print("  ✓ 数字序列")
}

do {
    let matches = SequenceMatcher.sequenceMatch(password: "fedcba")
    let hasDesc = matches.contains { m in
        if case .sequence(let sm) = m.pattern { return !sm.ascending }
        return false
    }
    assert(hasDesc, "应识别降序序列 'fedcba'")
    print("  ✓ 反向序列")
}

// ============================================================
// 5. Repeat Matcher
// ============================================================
section("Repeat Matcher")

do {
    let matches = RepeatMatcher.repeatMatch(password: "aaaaaa")
    let hasRepeat = matches.contains { m in
        if case .repeat_(let rm) = m.pattern { return rm.baseToken == "a" && rm.repeatCount == 6 }
        return false
    }
    assert(hasRepeat, "应识别单字符重复 'aaaaaa'")
    print("  ✓ 单字符重复")
}

do {
    let matches = RepeatMatcher.repeatMatch(password: "abcabcabc")
    let hasRepeat = matches.contains { m in
        if case .repeat_(let rm) = m.pattern { return rm.baseToken == "abc" && rm.repeatCount == 3 }
        return false
    }
    assert(hasRepeat, "应识别多字符重复 'abcabcabc'")
    print("  ✓ 多字符重复")
}

// ============================================================
// 6. Date Matcher
// ============================================================
section("Date Matcher")

do {
    let matches = DateMatcher.dateMatch(password: "13/02/1991")
    let hasDate = matches.contains { m in
        if case .date(let dm) = m.pattern { return dm.year == 1991 && dm.month == 2 && dm.day == 13 }
        return false
    }
    assert(hasDate, "应识别日期 '13/02/1991'")
    print("  ✓ 带分隔符日期")
}

do {
    let matches = DateMatcher.dateMatch(password: "13021991")
    let hasDate = matches.contains { m in
        if case .date(let dm) = m.pattern { return dm.year == 1991 && dm.month == 2 && dm.day == 13 }
        return false
    }
    assert(hasDate, "应识别无分隔符日期 '13021991'")
    print("  ✓ 无分隔符日期")
}

// ============================================================
// 7. Regex Matcher
// ============================================================
section("Regex Matcher")

do {
    let matches = RegexMatcher.regexMatch(password: "2019")
    let hasYear = matches.contains { m in
        if case .regex(let rm) = m.pattern { return rm.regexName == "recent_year" }
        return false
    }
    assert(hasYear, "应识别近期年份 '2019'")
    print("  ✓ 近期年份匹配")
}

// ============================================================
// 8. Omnimatch 综合
// ============================================================
section("Omnimatch 综合")

do {
    let matches = Matcher.omnimatch(password: "password123")
    assert(!matches.isEmpty, "omnimatch 应返回非空匹配")
    let hasDictionary = matches.contains { if case .dictionary(_) = $0.pattern { return true }; return false }
    assert(hasDictionary, "应包含字典匹配")
    print("  ✓ 综合匹配器协作")
}

do {
    let matches = Matcher.omnimatch(password: "password123abc")
    var sorted = true
    for i in 0..<(matches.count - 1) {
        if matches[i].i > matches[i + 1].i || (matches[i].i == matches[i + 1].i && matches[i].j > matches[i + 1].j) {
            sorted = false; break
        }
    }
    assert(sorted, "omnimatch 结果应按位置排序")
    print("  ✓ 结果排序")
}

// ============================================================
// 9. Scoring
// ============================================================
section("Scoring")

do {
    let matches = Matcher.omnimatch(password: "password")
    let result = Scoring.mostGuessableMatchSequence(password: "password", matches: matches)
    assert(result.guesses > 0, "猜测数应>0")
    assert(!result.sequence.isEmpty, "应返回非空匹配序列")
    print("  ✓ 基本评分")
}

do {
    let result = Scoring.mostGuessableMatchSequence(password: "", matches: [])
    assert(result.guesses == 1, "空密码猜测数应=1, 实际=\(result.guesses)")
    print("  ✓ 空密码评分")
}

do {
    let matches = Matcher.omnimatch(password: "password")
    let with_ = Scoring.mostGuessableMatchSequence(password: "password", matches: matches)
    let without = Scoring.mostGuessableMatchSequence(password: "password", matches: matches, excludeAdditive: true)
    assert(with_.guesses >= without.guesses, "含额外因子猜测数应>=不含时")
    print("  ✓ excludeAdditive 参数")
}

// ============================================================
// 10. Time Estimates
// ============================================================
section("Time Estimates")

do {
    let t = TimeEstimates.estimateAttackTimes(guesses: 1)
    assert(t.score == 0, "guesses=1 时得分应为0")
    print("  ✓ 最低猜测数得分")
}

do {
    let t = TimeEstimates.estimateAttackTimes(guesses: 1e11)
    assert(t.score == 4, "guesses=1e11 时得分应为4, 实际=\(t.score)")
    print("  ✓ 极高猜测数得分")
}

do {
    assert(TimeEstimates.guessesToScore(1) == 0, "边界: 1 -> 0")
    assert(TimeEstimates.guessesToScore(999) == 0, "边界: 999 -> 0")
    assert(TimeEstimates.guessesToScore(1e3) == 1, "边界: 1e3 -> 1")
    assert(TimeEstimates.guessesToScore(1e6) == 2, "边界: 1e6 -> 2")
    assert(TimeEstimates.guessesToScore(1e8) == 3, "边界: 1e8 -> 3")
    assert(TimeEstimates.guessesToScore(1e10) == 4, "边界: 1e10 -> 4")
    print("  ✓ 得分边界值")
}

do {
    let d0 = TimeEstimates.displayTime(0)
    assert(d0 == "less than a second", "0秒应显示 'less than a second', 实际='\(d0)'")
    let d3600 = TimeEstimates.displayTime(3600)
    assert(d3600.contains("hour"), "3600秒应包含 'hour', 实际='\(d3600)'")
    let dMonth = TimeEstimates.displayTime(86400 * 30)
    assert(dMonth.contains("month"), "30天应包含 'month', 实际='\(dMonth)'")
    let dCentury = TimeEstimates.displayTime(86400 * 365 * 200)
    assert(dCentury.contains("centuries"), "200年应包含 'centuries', 实际='\(dCentury)'")
    print("  ✓ 时间格式化")
}

do {
    let t = TimeEstimates.estimateAttackTimes(guesses: 1e6)
    assert(t.crackTimesSeconds.onlineThrottling100PerHour > t.crackTimesSeconds.onlineNoThrottling10PerSecond, "限流 > 无限流")
    assert(t.crackTimesSeconds.onlineNoThrottling10PerSecond > t.crackTimesSeconds.offlineSlowHashing1e4PerSecond, "无限流 > 慢哈希")
    assert(t.crackTimesSeconds.offlineSlowHashing1e4PerSecond > t.crackTimesSeconds.offlineFastHashing1e10PerSecond, "慢哈希 > 快哈希")
    print("  ✓ 攻击时间排序")
}

// ============================================================
// 11. Feedback
// ============================================================
section("Feedback")

do {
    let r = zxcvbn(password: "password")
    assert(!r.feedback.warning.isEmpty, "弱密码应有警告, 实际为空")
    assert(!r.feedback.suggestions.isEmpty, "弱密码应有建议")
    print("  ✓ 弱密码反馈")
}

do {
    let r = zxcvbn(password: "8j$&Qm!Xz@Lp3rW9kN")
    assert(r.feedback.warning.isEmpty, "强密码不应有警告, 实际='\(r.feedback.warning)'")
    print("  ✓ 强密码无警告")
}

do {
    let r = zxcvbn(password: "123456")
    assert(!r.feedback.warning.isEmpty, "极常见密码应有警告")
    print("  ✓ 极常见密码反馈")
}

// ============================================================
// 12. Math 工具
// ============================================================
section("Math 工具")

do {
    assert(nCk(0, 0) == 1, "C(0,0)=1")
    assert(nCk(1, 0) == 1, "C(1,0)=1")
    assert(nCk(5, 2) == 10, "C(5,2)=10")
    assert(nCk(10, 3) == 120, "C(10,3)=120")
    assert(nCk(3, 5) == 0, "C(3,5)=0 (k>n)")
    print("  ✓ nCk 组合数")
}

do {
    assert(factorial(0) == 1, "0!=1")
    assert(factorial(1) == 1, "1!=1")
    assert(factorial(5) == 120, "5!=120")
    print("  ✓ factorial 阶乘")
}

// ============================================================
// 13. 已知密码对比
// ============================================================
section("已知密码对比")

do {
    assert(zxcvbn(password: "").score == 0, "空密码=0")
    assert(zxcvbn(password: "123456").score == 0, "'123456'=0")
    assert(zxcvbn(password: "password").score == 0, "'password'=0")
    assert(zxcvbn(password: "qwerty").score == 0, "'qwerty'=0")

    let medium = zxcvbn(password: "tr0ub4dor&3")
    assert(medium.score >= 1, "中等密码得分>=1, 实际=\(medium.score)")

    let strong = zxcvbn(password: "W@k5!m&Zp#2xL9qR")
    assert(strong.score >= 3, "强密码得分>=3, 实际=\(strong.score)")
    print("  ✓ 已知密码评分")
}

do {
    let weak = zxcvbn(password: "password")
    let strong = zxcvbn(password: "W@k5!m&Zp#2xL9qR")
    assert(weak.guesses < strong.guesses, "弱密码猜测数<强密码")
    assert(weak.score < strong.score, "弱密码分数<强密码")
    print("  ✓ 强弱对比")
}

// ============================================================
// 14. 性能
// ============================================================
section("性能")

do {
    let r = zxcvbn(password: "correcthorsebatterystaple")
    assert(r.calcTime < 1000, "常规密码计算<1秒, 实际=\(r.calcTime)ms")
    print("  ✓ 常规密码性能 (\(String(format: "%.1f", r.calcTime))ms)")
}

do {
    let longPw = String(repeating: "a", count: 50)
    let r = zxcvbn(password: longPw)
    assert(r.calcTime < 5000, "长密码计算<5秒, 实际=\(r.calcTime)ms")
    print("  ✓ 长密码性能 (\(String(format: "%.1f", r.calcTime))ms)")
}

// ============================================================
// 总结
// ============================================================
print("\n══════════════════════════════")
print("总计: \(passed + failed) 项测试, ✓ \(passed) 通过, ✗ \(failed) 失败")
if !errors.isEmpty {
    print("\n失败详情:")
    for e in errors { print("  \(e)") }
}
print("══════════════════════════════")

if failed > 0 {
    exit(1)
}
