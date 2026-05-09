import Foundation

enum MathUtils {
    static func nCk(_ n: Int, _ k: Int) -> Double {
        if k > n { return 0 }
        if k == 0 { return 1 }
        var r: Double = 1
        var n = Double(n)
        for d in 1...k {
            r *= n
            r /= Double(d)
            n -= 1
        }
        return r
    }

    static func log10(_ n: Double) -> Double {
        Foundation.log10(n)
    }

    static func log2(_ n: Double) -> Double {
        Foundation.log2(n)
    }

    static func factorial(_ n: Int) -> Double {
        if n < 2 { return 1 }
        var f: Double = 1
        for i in 2...n {
            f *= Double(i)
        }
        return f
    }

    /// Modulo that handles negative numbers correctly (always returns non-negative)
    static func mod(_ n: Int, _ m: Int) -> Int {
        ((n % m) + m) % m
    }
}
