import Foundation

public func zxcvbn(password: String, userInputs: [String] = []) -> ZxcvbnResult {
    let start = CFAbsoluteTimeGetCurrent()

    let sanitizedInputs = userInputs.compactMap { input -> String? in
        return input.lowercased()
    }
    FrequencyLists.setUserInputDictionary(sanitizedInputs)

    let matches = Matcher.omnimatch(password: password)
    let result = Scoring.mostGuessableMatchSequence(password: password, matches: matches)
    let attackTimes = TimeEstimates.estimateAttackTimes(guesses: result.guesses)
    let feedback = FeedbackGenerator.getFeedback(score: attackTimes.score, sequence: result.sequence)
    let calcTime = (CFAbsoluteTimeGetCurrent() - start) * 1000

    return ZxcvbnResult(
        password: password,
        guesses: result.guesses,
        guessesLog10: result.guessesLog10,
        crackTimesSeconds: attackTimes.crackTimesSeconds,
        crackTimesDisplay: attackTimes.crackTimesDisplay,
        score: attackTimes.score,
        feedback: feedback,
        sequence: result.sequence,
        calcTime: calcTime
    )
}
