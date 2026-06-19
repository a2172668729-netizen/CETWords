# 词库审计报告

生成方式：`python3 tools/audit_vocab.py`

## 结论

当前词库应表述为：

> 基于公开整理词库，覆盖常见 CET4/CET6 词汇，非官方授权词库。

不建议声称“官方完整词库”或“完整覆盖官方四六级大纲”，因为当前来源是公开社区整理仓库，不是官方大纲原始词表或授权词库。较严谨的产品文案是：“覆盖常见 CET4/CET6 词汇，适合备考复习使用，词库来源为公开整理资料。”

## 来源

- GitHub 仓库：`KyleBing/english-vocabulary`
- 四级文件：`3 四级-乱序.txt`
- 六级文件：`4 六级-乱序.txt`
- 本地文件：`CETWords/Resources/VocabSources/cet4.txt`
- 本地文件：`CETWords/Resources/VocabSources/cet6.txt`

## 汇总

| 指标 | 数值 |
| --- | ---: |
| 四级词条数 | 7508 |
| 六级词条数 | 5651 |
| 原始词条总数 | 13159 |
| 去重后总词数（按小写英文词头） | 6661 |
| 完全重复数量（按“词头+释义”重复的多余条目） | 898 |
| 英文词头重复数量（按小写词头重复的多余条目） | 6498 |
| 大小写重复数量（同一词头不同大小写形式） | 2 |
| 四级和六级交叉重复数量（按小写词头） | 1873 |
| 四级内部重复词数量（distinct word） | 2355 |
| 四级内部重复多余条目数 | 2965 |
| 六级内部重复词数量（distinct word） | 1424 |
| 六级内部重复多余条目数 | 1660 |
| 四级/六级交叉重复出现次数 | 6319 |
| 四级/六级交叉重复多余出现次数 | 4446 |
| 异常词条数量（格式/空词头/无中文释义/疑似乱码合计，可能重叠） | 0 |

## 统计口径说明

1. `原始词条总数`：按非空行统计，一行算一条。
2. `去重后总词数`：按英文词头小写、去掉首尾空白后去重，只看 `word`，不看释义，也不区分四级/六级来源。
3. `完全重复数量`：按“英文词头小写 + 释义文本归一化”统计重复的多余条目数。例如同一完整词条出现 3 次，计为 2 个完全重复；它不是 distinct word 数。
4. `英文词头重复数量`：按小写英文词头统计重复的多余条目数，不要求释义相同，包含同级内部重复和跨级重复。
5. `四级内部重复词数量`、`六级内部重复词数量`：只在各自级别内部按小写英文词头统计，表示有重复的 distinct word 组数。
6. `四级和六级交叉重复数量`：四级词头集合与六级词头集合的交集大小，是 distinct word 数量，不是出现次数。交叉重复常见于核心词汇，并不一定是错误。
7. `四级/六级交叉重复出现次数`：这些交叉词在两个文件中实际出现的总行数；`多余出现次数` 是出现次数减去 distinct word 数。

## 分级检查

| 级别 | 词条数 | 空行 | 格式异常 | 无英文单词 | 无中文释义 | 疑似乱码/异常字符 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 四级 | 7508 | 0 | 0 | 0 | 0 | 0 |
| 六级 | 5651 | 0 | 0 | 0 | 0 | 0 |

## 重复说明

- 四级和六级交叉重复不一定是错误。很多核心词会同时出现在四级和六级复习资料中，保留级别标签有助于按考试范围学习。
- “英文词头重复”包括同一词在同一级别或跨级别中多次出现，可能来自不同释义、词性或整理源重复。
- “完全重复”只统计词头和释义都相同的重复条目。

### 四级/六级交叉重复示例

abandon, abnormal, absence, absent, absolutely, absorb, abstract, abundant, abuse, academic, accelerate, acceptance, access, accident, accommodate, accommodation, accompany, accomplish, accord, accordance, account, accountant, accumulate, accurate, accuse, accustom, accustomed, achieve, achievement, acid, acknowledge, acquaint, acquaintance, acquire, action, acute, adapt, addition, additional, address, adequate, adjust, administration, admiration, admit, adopt, advantage, adventure, adversity, advertise, advisable, advocate, affection, affirm, afford, agenda, agent, aggressive, agony, aid, alarm, album, alcohol, alert, alliance, allocate, allowance, alloy, ally, alongside, alter, alternative, amateur, ambassador, ambition, ambitious, amplify, analyse, analysis, ancestor ……另有 1793 个未展示

### 完全重复词条示例

- `bacteria	n. 细菌`：共 5 条。四级 第 760 行 `bacteria	n. 细菌`；四级 第 3910 行 `bacteria	 n. 细菌`；四级 第 5128 行 `bacteria	 n. 细菌`；六级 第 856 行 `bacteria	n. 细菌`；另有 1 条
- `fertilizer	n. 肥料`：共 4 条。四级 第 2431 行 `fertilizer	n. 肥料`；四级 第 7494 行 `fertilizer	 n. 肥料`；六级 第 1060 行 `fertilizer	n. 肥料`；六级 第 5644 行 `fertilizer	n. 肥料`
- `orchestra	n. 管弦乐队`：共 4 条。四级 第 1570 行 `orchestra	n. 管弦乐队`；四级 第 7072 行 `orchestra	 n. 管弦乐队`；六级 第 2648 行 `orchestra	n. 管弦乐队`；六级 第 5278 行 `orchestra	n. 管弦乐队`
- `phenomenon	n. 现象`：共 4 条。四级 第 430 行 `phenomenon	n. 现象`；四级 第 3530 行 `phenomenon	 n. 现象`；四级 第 5738 行 `phenomenon	 n. 现象`；六级 第 392 行 `phenomenon	n. 现象`
- `planet	n. 行星`：共 4 条。四级 第 1102 行 `planet	n. 行星`；四级 第 4245 行 `planet	 n. 行星`；四级 第 5625 行 `planet	 n. 行星`；六级 第 3984 行 `planet	n. 行星`
- `refusal	n. 拒绝`：共 4 条。四级 第 455 行 `refusal	n. 拒绝`；四级 第 2363 行 `refusal	n. 拒绝`；四级 第 5359 行 `refusal	 n. 拒绝`；六级 第 3740 行 `refusal	n. 拒绝`
- `specialist	n. 专家`：共 4 条。四级 第 2624 行 `specialist	n. 专家`；四级 第 5801 行 `specialist	 n. 专家`；六级 第 1194 行 `specialist	n. 专家`；六级 第 4140 行 `specialist	n. 专家`
- `accustom	v. 使习惯`：共 3 条。四级 第 1014 行 `accustom	v. 使习惯`；四级 第 1945 行 `accustom	v. 使习惯`；六级 第 915 行 `accustom	v. 使习惯`
- `apartment	n. 一套公寓房间`：共 3 条。四级 第 1405 行 `apartment	n. 一套公寓房间`；四级 第 5513 行 `apartment	 n. 一套公寓房间`；六级 第 3894 行 `apartment	n. 一套公寓房间`
- `bride	n. 新娘`：共 3 条。四级 第 692 行 `bride	n. 新娘`；四级 第 7109 行 `bride	 n. 新娘`；六级 第 781 行 `bride	n. 新娘`
- 另有 851 组未展示

### 四级内部重复示例

- `absent`：共 3 条。四级 第 1123 行 `absent	adj. 缺席的`；四级 第 1914 行 `absent	adj. 不在场的；缺乏的`；四级 第 6214 行 `absent	 adj. 缺席的， 不在场的； 缺乏的， 不存在的； 心不在焉的`
- `absorb`：共 3 条。四级 第 399 行 `absorb	v. 吸收（液体、气体等）`；四级 第 1249 行 `absorb	v. 吸收；中文释义；使专心`；四级 第 5221 行 `absorb	 vt. 吸收； 吸引…的注意， 使全神贯注； 把…并入， 同化`
- `abstract`：共 3 条。四级 第 682 行 `abstract	adj. 抽象的`；四级 第 2400 行 `abstract	adj. 抽象的 n. 摘要`；四级 第 6110 行 `abstract	 adj. 抽象的，抽象派的 n. 摘要， 梗概； 抽象派艺术作品 vt. 做…的摘要； 提取`
- `abundant`：共 3 条。四级 第 347 行 `abundant	adj. 大量的，丰富的`；四级 第 4504 行 `abundant	 adj. 丰富的；大量的`；四级 第 5233 行 `abundant	 adj. 丰富的， 富裕的； 大量的， 充足的`
- `abuse`：共 3 条。四级 第 588 行 `abuse	v. 虐待；滥用`；四级 第 1660 行 `abuse	v. 滥用；虐待 n. 滥用`；四级 第 6871 行 `abuse	 vt. 滥用； 虐待， 伤害； 辱骂， 毁谤 n. 滥用； 虐待， 伤害； 辱骂， 毁谤`
- `academic`：共 3 条。四级 第 489 行 `academic	adj. 学术的`；四级 第 1450 行 `academic	adj. 学院的；学术的`；四级 第 5145 行 `academic	 adj. 学院的； 学术的； 纯理论的， 不切实际的`
- `accelerate`：共 3 条。四级 第 1158 行 `accelerate	v. 加速`；四级 第 2864 行 `accelerate	v. （使）加快；促进`；四级 第 5777 行 `accelerate	 vt. 使加快， 使增速`
- `access`：共 3 条。四级 第 1 行 `access	v. 获取 n. 接近，入口`；四级 第 4669 行 `access	 n. 通道，入口`；四级 第 7212 行 `access	 n. 接近；通道，入口；接近的机会 vt. 存取`
- `accompany`：共 3 条。四级 第 888 行 `accompany	v. 陪伴`；四级 第 1253 行 `accompany	v. 陪伴，陪同；伴随`；四级 第 5637 行 `accompany	 vt. 陪伴， 陪同， 伴随； 为…伴奏`
- `accomplish`：共 3 条。四级 第 665 行 `accomplish	v. 完成`；四级 第 1544 行 `accomplish	v. 达到（目的）；完成`；四级 第 6336 行 `accomplish	 vt. 达到； 完成`
- 另有 2345 组未展示

### 六级内部重复示例

- `abstract`：共 3 条。六级 第 234 行 `abstract	adj. 抽象的`；六级 第 2319 行 `abstract	adj. 理论上的 n. 抽象派作品`；六级 第 4399 行 `abstract	adj. 抽象的，抽象派的 n. 摘要，梗概；抽象派艺术作品`
- `administration`：共 3 条。六级 第 866 行 `administration	n. 管理；政府`；六级 第 2414 行 `administration	n. 局（或署、处等）`；六级 第 4843 行 `administration	n. 管理； 管理部门， 行政机关； 实行， 执行`
- `alert`：共 3 条。六级 第 762 行 `alert	adj. 机警的 v. 提醒`；六级 第 2426 行 `alert	adj. 警惕的`；六级 第 5181 行 `alert	adj. 警觉的，留神的，注意的 vt. 使认识到，使意识到 n. 警戒， 戒备； 警报`
- `alien`：共 3 条。六级 第 545 行 `alien	adj. 陌生的`；六级 第 1743 行 `alien	adj. 外国的 n. 外国人`；六级 第 3787 行 `alien	adj. 外国的，外国人的；陌生的；性质不同的，不相容的 n. 外国人， 外侨； 外星人`
- `ascend`：共 3 条。六级 第 528 行 `ascend	v. 上升`；六级 第 2170 行 `ascend	v. 攀登，登高`；六级 第 3410 行 `ascend	vi. 渐渐上升，升高 vt. 攀登， 登上`
- `assault`：共 3 条。六级 第 784 行 `assault	n. 攻击`；六级 第 1665 行 `assault	v. 袭击 n. 攻击`；六级 第 4950 行 `assault	n. 攻击， 袭击`
- `assert`：共 3 条。六级 第 589 行 `assert	v. 主张，断言`；六级 第 2819 行 `assert	v. 断言，宣称；维护`；六级 第 5548 行 `assert	vt. 肯定地说， 断言； 维护， 坚持； 坚持己见`
- `assumption`：共 3 条。六级 第 499 行 `assumption	n. 假设`；六级 第 3024 行 `assumption	n. 假定`；六级 第 5074 行 `assumption	n. 假定， 臆断； 担任， 承担`
- `attendant`：共 3 条。六级 第 757 行 `attendant	n. 服务人员`；六级 第 1908 行 `attendant	n. 侍者；（要人的）侍从；（病人的）护理人员`；六级 第 4456 行 `attendant	adj. 伴随的， 随之产生的 n. 服务人员，侍者，随从`
- `awkward`：共 3 条。六级 第 737 行 `awkward	adj. 尴尬的；棘手的；笨拙的`；六级 第 3031 行 `awkward	adj. 令人尴尬的`；六级 第 4292 行 `awkward	adj. 笨拙的， 尴尬的； 难操纵的， 使用不便的； 不灵巧的`
- 另有 1414 组未展示

### 大小写重复示例

- `heaven`：Heaven, heaven
- `catholic`：Catholic, catholic

## 异常样例

### 格式异常

无

### 无英文单词

无

### 无中文释义

无

### 疑似乱码或异常字符

无

## 后续建议

1. App 和文档统一使用“基于公开整理词库，覆盖常见 CET4/CET6 词汇，非官方授权词库”。
2. App 学习层可以按英文词头合并交叉重复词，但应在统一词条中保留四级/六级来源集合，并用 `word::<小写词头>` 保存统一学习进度。
3. 如果以后要上架或商业分发，应替换为授权明确的词库，或逐条核对当前公开整理词库的版权和准确性。
4. 可在后续阶段增加 JSON 词库支持，用音标、短语、例句补足当前 txt 词库的信息不足。
