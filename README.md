# 六级备考背词 iPhone App

这个 README 只做导航。功能实现看 Swift 文件，词库来源和审计看专门文档。

App 会把四级和六级来源词汇按英文词头合并去重，再用固定乱序规则分为 20 个小词库。学习入口不再区分四级和六级；来源信息只在单词详情中保留。

## 先打开哪个文件

| 任务 | 文件 |
| --- | --- |
| 用 Xcode 运行 App | `CETWords.xcodeproj` |
| 看 App 入口 | `CETWords/CETWordsApp.swift`、`CETWords/ContentView.swift` |
| 看学习逻辑 | `CETWords/StudyEngine.swift` |
| 看进度保存 | `CETWords/ProgressStore.swift` |
| 看词库加载 | `CETWords/WordBank.swift` |
| 看页面 | `CETWords/Views/` |
| 查词库来源 | `VOCAB_SOURCE.md` |
| 查词库质量 | `VOCAB_AUDIT.md` |

## 运行入口

1. 在 Mac 上打开 `CETWords.xcodeproj`。
2. 在 Xcode 里选择 iPhone 或模拟器。
3. 如需真机运行，在 Signing & Capabilities 里选择 Apple ID 团队。
4. 点击运行按钮。

## 本轮下一步

1. 用模拟器或真机跑一次，记录是否能启动。
2. 检查今日学习、复习、20 个小词库、测验、统计、设置页面是否都能打开。
3. 如果要继续维护，优先补一个“手动测试清单”。
