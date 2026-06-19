# Free Study and Word List Access Design

## Goal

Fix four usability problems in the CET vocabulary app:

1. Today's available study words feel too few.
2. After finishing today's task, the user cannot keep learning.
3. Tapping "应用设置" can crash or destabilize the app.
4. Learned and favorite word lists are not obvious enough to find.

## Chosen Approach

Add a separate free study mode instead of changing the meaning of today's task.

Today's task still follows the daily goal and keeps the progress display meaningful. Free study is an extra learning path for users who want to continue after the daily target is complete.

## Study Modes

The app will have these study modes:

- Daily: due review words, weak words, then new words, limited by the daily target.
- Review: due review words only.
- Weak: weak words only.
- Quiz: mixed quiz task.
- Free: extra learning, not limited by the remaining daily target.

Free study should prefer unlearned words first. If there are not enough unlearned words, it can include due, weak, and learned words so the user can keep practicing.

## Today Screen

The Today screen should keep showing daily progress, such as `30/30`, when today's task is finished.

When daily progress is complete, the user should still see a clear action:

- "继续自由学习"

This starts free study mode instead of rebuilding an empty daily task.

## Word List Access

The app already has Library filters for learned and favorite words. The problem is discoverability.

Add clearer entry points for:

- 未学单词
- 已学单词
- 收藏单词

These entries should open `LibraryView` with the matching filter already selected.

## Settings Stability

The settings button should apply draft settings, save them, and rebuild the current task safely.

Before changing settings logic, fix the obvious SwiftUI structure problems in `TodayView.swift` and `ReviewView.swift`, especially sheet and toolbar brace nesting. This keeps view state predictable when settings trigger a task rebuild.

## Testing

Use the existing pure Swift learning-policy check to verify task-building rules.

Add or update checks for free study task building:

- Free study returns words even after the daily target is complete.
- Free study prefers unlearned words.
- Daily task remains limited by the daily target.

Full Xcode build should be attempted, but current local verification may be blocked by the machine's CoreSimulator runtime issue.
