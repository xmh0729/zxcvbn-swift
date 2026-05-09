# SwiftZxcvbn

Dropbox [zxcvbn](https://github.com/dropbox/zxcvbn) 密码强度评估库的 Swift 移植版本。通过模式匹配（字典、键盘布局、日期、序列、重复、l33t 替换等）评估密码强度，输出 0-4 的评分及破解时间估算。

## 要求

- Swift 5.9+
- iOS 16+ / macOS 13+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/SwiftZxcvbn.git", from: "1.0.0")
]
```

或在 Xcode 中：**File > Add Package Dependencies**，输入仓库 URL。

## 使用

```swift
import Zxcvbn

let result = zxcvbn(password: "P@ssw0rd123")

print(result.score)              // 0-4，越高越强
print(result.feedback.warning)   // 警告信息
print(result.feedback.suggestions) // 改进建议
print(result.crackTimesDisplay.offlineSlowHashing1e4PerSecond) // 破解时间

// 传入用户相关词汇（用户名、邮箱等）以降低包含这些词的密码评分
let result2 = zxcvbn(password: "john2024", userInputs: ["john", "john@example.com"])
```

### 返回结果

`ZxcvbnResult` 包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `password` | `String` | 原始密码 |
| `score` | `Int` | 强度评分 0-4 |
| `guesses` | `Double` | 预估猜测次数 |
| `guessesLog10` | `Double` | 猜测次数的 log10 |
| `crackTimesSeconds` | `CrackTimes` | 不同攻击场景下的破解秒数 |
| `crackTimesDisplay` | `CrackTimesDisplay` | 人类可读的破解时间 |
| `feedback` | `Feedback` | 警告和改进建议 |
| `sequence` | `[Match]` | 匹配到的模式序列 |
| `calcTime` | `TimeInterval` | 计算耗时（毫秒） |

## 项目结构

```
Sources/Zxcvbn/
├── Zxcvbn.swift              # 入口函数
├── Feedback.swift             # 反馈生成
├── TimeEstimates.swift        # 破解时间估算
├── Matching/                  # 模式匹配器
│   ├── Matcher.swift          # omnimatch 入口
│   ├── DictionaryMatcher.swift
│   ├── SpatialMatcher.swift
│   ├── SequenceMatcher.swift
│   ├── RepeatMatcher.swift
│   ├── DateMatcher.swift
│   └── RegexMatcher.swift
├── Scoring/                   # 评分
│   ├── Scoring.swift          # 最优匹配序列（DP）
│   └── GuessEstimator.swift   # 猜测数估算
├── Models/
│   ├── Result.swift           # 结果模型
│   └── Match.swift            # 匹配模型
├── Data/                      # 生成的数据文件
│   ├── AdjacencyGraphs.swift  # 键盘邻接图
│   └── FrequencyLists.swift   # 词频表
└── Utilities/
    └── Math.swift
```

## 构建与测试

```shell
swift build
swift test
```

### 数据重新生成

`Data/` 下的文件由 `scripts/` 中的 Python 脚本生成，不要直接编辑。

## 许可证

MIT License - 参见 [LICENSE.txt](../LICENSE.txt)
