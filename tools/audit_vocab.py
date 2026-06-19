#!/usr/bin/env python3
from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Optional
import re


ROOT = Path(__file__).resolve().parents[1]
VOCAB_DIR = ROOT / "CETWords" / "Resources" / "VocabSources"
OUTPUT = ROOT / "VOCAB_AUDIT.md"

SOURCES = {
    "四级": VOCAB_DIR / "cet4.txt",
    "六级": VOCAB_DIR / "cet6.txt",
}

CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")
ASCII_LETTER_RE = re.compile(r"[A-Za-z]")
SUSPICIOUS_WORD_RE = re.compile(r"[^A-Za-z '\-./]")
MOJIBAKE_RE = re.compile(r"\ufffd|锟斤拷|Ã|Â|â€|鈥|�")
CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


@dataclass(frozen=True)
class Row:
    level: str
    line_number: int
    raw: str
    word: str
    meaning: str
    format_error: Optional[str]

    @property
    def normalized_word(self) -> str:
        return " ".join(self.word.strip().lower().split())

    @property
    def normalized_line(self) -> str:
        return f"{self.normalized_word}\t{' '.join(self.meaning.strip().split())}"


@dataclass
class LevelAudit:
    level: str
    path: Path
    total_lines: int
    entry_count: int
    empty_lines: int
    format_errors: list[Row]
    missing_words: list[Row]
    missing_chinese_meanings: list[Row]
    suspicious_rows: list[tuple[Row, str]]
    rows: list[Row]


def parse_file(level: str, path: Path) -> LevelAudit:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    rows: list[Row] = []
    empty_lines = 0
    format_errors: list[Row] = []
    missing_words: list[Row] = []
    missing_chinese_meanings: list[Row] = []
    suspicious_rows: list[tuple[Row, str]] = []

    for index, raw in enumerate(lines, start=1):
        if not raw.strip():
            empty_lines += 1
            continue

        format_error = None
        if "\t" not in raw:
            parts = [raw.strip(), ""]
            format_error = "缺少制表符分隔"
        else:
            parts = raw.split("\t", 1)

        word = parts[0].strip()
        meaning = parts[1].strip() if len(parts) > 1 else ""
        row = Row(level=level, line_number=index, raw=raw, word=word, meaning=meaning, format_error=format_error)
        rows.append(row)

        if format_error:
            format_errors.append(row)
        if not word or not ASCII_LETTER_RE.search(word):
            missing_words.append(row)
        if not meaning or not CJK_RE.search(meaning):
            missing_chinese_meanings.append(row)

        reasons = []
        if MOJIBAKE_RE.search(raw):
            reasons.append("疑似编码乱码")
        if CONTROL_RE.search(raw):
            reasons.append("包含控制字符")
        if word and SUSPICIOUS_WORD_RE.search(word):
            reasons.append("英文词头包含异常字符")
        if word and CJK_RE.search(word):
            reasons.append("英文词头包含中文")
        if reasons:
            suspicious_rows.append((row, "；".join(reasons)))

    return LevelAudit(
        level=level,
        path=path,
        total_lines=len(lines),
        entry_count=len(rows),
        empty_lines=empty_lines,
        format_errors=format_errors,
        missing_words=missing_words,
        missing_chinese_meanings=missing_chinese_meanings,
        suspicious_rows=suspicious_rows,
        rows=rows,
    )


def duplicate_count(counter: Counter[str]) -> int:
    return sum(count - 1 for count in counter.values() if count > 1)


def sample_rows(rows: list[Row], limit: int = 12) -> str:
    if not rows:
        return "无"
    lines = []
    for row in rows[:limit]:
        raw = row.raw.replace("|", "\\|")
        lines.append(f"- {row.level} 第 {row.line_number} 行：`{raw}`")
    if len(rows) > limit:
        lines.append(f"- 另有 {len(rows) - limit} 条未展示")
    return "\n".join(lines)


def sample_suspicious(rows: list[tuple[Row, str]], limit: int = 12) -> str:
    if not rows:
        return "无"
    lines = []
    for row, reason in rows[:limit]:
        raw = row.raw.replace("|", "\\|")
        lines.append(f"- {row.level} 第 {row.line_number} 行（{reason}）：`{raw}`")
    if len(rows) > limit:
        lines.append(f"- 另有 {len(rows) - limit} 条未展示")
    return "\n".join(lines)


def duplicate_groups(rows: list[Row], key_name: str) -> dict[str, list[Row]]:
    grouped: dict[str, list[Row]] = defaultdict(list)
    for row in rows:
        key = row.normalized_line if key_name == "line" else row.normalized_word
        if key:
            grouped[key].append(row)
    return {
        key: values for key, values in grouped.items()
        if len(values) > 1
    }


def duplicate_extra_entries(groups: dict[str, list[Row]]) -> int:
    return sum(len(rows) - 1 for rows in groups.values())


def sample_duplicate_groups(groups: dict[str, list[Row]], limit: int = 10) -> str:
    if not groups:
        return "无"

    lines = []
    sorted_groups = sorted(groups.items(), key=lambda item: (-len(item[1]), item[0]))
    for key, rows in sorted_groups[:limit]:
        location_parts = []
        for row in rows[:4]:
            raw = row.raw.replace("|", "\\|")
            location_parts.append(f"{row.level} 第 {row.line_number} 行 `{raw}`")
        locations = "；".join(location_parts)
        suffix = f"；另有 {len(rows) - 4} 条" if len(rows) > 4 else ""
        lines.append(f"- `{key}`：共 {len(rows)} 条。{locations}{suffix}")
    if len(groups) > limit:
        lines.append(f"- 另有 {len(groups) - limit} 组未展示")
    return "\n".join(lines)


def main() -> None:
    audits = [parse_file(level, path) for level, path in SOURCES.items()]
    all_rows = [row for audit in audits for row in audit.rows]

    rows_by_level = {audit.level: audit.rows for audit in audits}
    exact_line_groups = duplicate_groups(all_rows, key_name="line")
    exact_word_groups = duplicate_groups(all_rows, key_name="word")
    level_word_groups = {
        level: duplicate_groups(rows, key_name="word")
        for level, rows in rows_by_level.items()
    }

    cased_by_normalized: dict[str, set[str]] = defaultdict(set)
    for row in all_rows:
        if row.normalized_word:
            cased_by_normalized[row.normalized_word].add(row.word)

    case_duplicate_groups = {
        word: forms for word, forms in cased_by_normalized.items()
        if len(forms) > 1
    }
    case_duplicate_entries = sum(len(forms) - 1 for forms in case_duplicate_groups.values())

    words_by_level = {
        audit.level: {row.normalized_word for row in audit.rows if row.normalized_word}
        for audit in audits
    }
    cross_duplicates = words_by_level["四级"] & words_by_level["六级"]
    cross_duplicate_occurrences = sum(
        sum(1 for row in all_rows if row.normalized_word == word)
        for word in cross_duplicates
    )
    cross_duplicate_extra_entries = cross_duplicate_occurrences - len(cross_duplicates)
    unique_total_words = len(set().union(*words_by_level.values()))

    total_format_errors = sum(len(audit.format_errors) for audit in audits)
    total_missing_words = sum(len(audit.missing_words) for audit in audits)
    total_missing_chinese = sum(len(audit.missing_chinese_meanings) for audit in audits)
    suspicious_rows = [item for audit in audits for item in audit.suspicious_rows]
    abnormal_total = total_format_errors + total_missing_words + total_missing_chinese + len(suspicious_rows)

    exact_duplicate_entries = duplicate_extra_entries(exact_line_groups)
    exact_word_duplicate_entries = duplicate_extra_entries(exact_word_groups)
    cet4_internal_groups = level_word_groups["四级"]
    cet6_internal_groups = level_word_groups["六级"]
    cet4_internal_extra = duplicate_extra_entries(cet4_internal_groups)
    cet6_internal_extra = duplicate_extra_entries(cet6_internal_groups)

    level_rows = "\n".join(
        f"| {audit.level} | {audit.entry_count} | {audit.empty_lines} | {len(audit.format_errors)} | "
        f"{len(audit.missing_words)} | {len(audit.missing_chinese_meanings)} | {len(audit.suspicious_rows)} |"
        for audit in audits
    )

    case_samples = []
    for normalized, forms in list(case_duplicate_groups.items())[:12]:
        case_samples.append(f"- `{normalized}`：{', '.join(sorted(forms))}")
    case_sample_text = "\n".join(case_samples) if case_samples else "无"

    cross_sample_text = ", ".join(sorted(cross_duplicates)[:80]) if cross_duplicates else "无"
    if len(cross_duplicates) > 80:
        cross_sample_text += f" ……另有 {len(cross_duplicates) - 80} 个未展示"

    report = f"""# 词库审计报告

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
| 四级词条数 | {audits[0].entry_count} |
| 六级词条数 | {audits[1].entry_count} |
| 原始词条总数 | {len(all_rows)} |
| 去重后总词数（按小写英文词头） | {unique_total_words} |
| 完全重复数量（按“词头+释义”重复的多余条目） | {exact_duplicate_entries} |
| 英文词头重复数量（按小写词头重复的多余条目） | {exact_word_duplicate_entries} |
| 大小写重复数量（同一词头不同大小写形式） | {case_duplicate_entries} |
| 四级和六级交叉重复数量（按小写词头） | {len(cross_duplicates)} |
| 四级内部重复词数量（distinct word） | {len(cet4_internal_groups)} |
| 四级内部重复多余条目数 | {cet4_internal_extra} |
| 六级内部重复词数量（distinct word） | {len(cet6_internal_groups)} |
| 六级内部重复多余条目数 | {cet6_internal_extra} |
| 四级/六级交叉重复出现次数 | {cross_duplicate_occurrences} |
| 四级/六级交叉重复多余出现次数 | {cross_duplicate_extra_entries} |
| 异常词条数量（格式/空词头/无中文释义/疑似乱码合计，可能重叠） | {abnormal_total} |

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
{level_rows}

## 重复说明

- 四级和六级交叉重复不一定是错误。很多核心词会同时出现在四级和六级复习资料中，保留级别标签有助于按考试范围学习。
- “英文词头重复”包括同一词在同一级别或跨级别中多次出现，可能来自不同释义、词性或整理源重复。
- “完全重复”只统计词头和释义都相同的重复条目。

### 四级/六级交叉重复示例

{cross_sample_text}

### 完全重复词条示例

{sample_duplicate_groups(exact_line_groups)}

### 四级内部重复示例

{sample_duplicate_groups(cet4_internal_groups)}

### 六级内部重复示例

{sample_duplicate_groups(cet6_internal_groups)}

### 大小写重复示例

{case_sample_text}

## 异常样例

### 格式异常

{sample_rows([row for audit in audits for row in audit.format_errors])}

### 无英文单词

{sample_rows([row for audit in audits for row in audit.missing_words])}

### 无中文释义

{sample_rows([row for audit in audits for row in audit.missing_chinese_meanings])}

### 疑似乱码或异常字符

{sample_suspicious(suspicious_rows)}

## 后续建议

1. App 和文档统一使用“基于公开整理词库，覆盖常见 CET4/CET6 词汇，非官方授权词库”。
2. 进入下一阶段升级词库模型时，不删除交叉重复词；应保留 `level`，并用稳定 `id` 区分四级/六级来源。
3. 如果以后要上架或商业分发，应替换为授权明确的词库，或逐条核对当前公开整理词库的版权和准确性。
4. 可在后续阶段增加 JSON 词库支持，用音标、短语、例句补足当前 txt 词库的信息不足。
"""

    OUTPUT.write_text(report, encoding="utf-8")

    print(f"四级词条数: {audits[0].entry_count}")
    print(f"六级词条数: {audits[1].entry_count}")
    print(f"去重后总词数: {unique_total_words}")
    print(f"完全重复数量: {exact_duplicate_entries}")
    print(f"四级内部重复词数量: {len(cet4_internal_groups)}")
    print(f"六级内部重复词数量: {len(cet6_internal_groups)}")
    print(f"大小写重复数量: {case_duplicate_entries}")
    print(f"四级和六级交叉重复数量: {len(cross_duplicates)}")
    print(f"异常词条数量: {abnormal_total}")
    print(f"报告已写入: {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
