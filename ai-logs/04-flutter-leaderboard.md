# Log 04 — Flutter Leaderboard Widget (Claude Code)

**Tool**: Claude Code (Anthropic)  
**Component**: Leaderboard screen widget in `mobile_flutter/`  
**Date**: April 2026

## Prompt

```
Generate a Flutter StatelessWidget for a climbing leaderboard screen. Each row shows:
- Rank number (1st has a gold crown icon)
- Username
- Weekly climb count
- A progress bar relative to the top user's count

Dark theme: background #1a1a1a, accent #E8500A (orange).
Use ListView.builder with a List<LeaderboardEntry> input model.
No external packages — use only Flutter's built-in widgets.

LeaderboardEntry model:
class LeaderboardEntry {
  final String username;
  final int weeklyCount;
  final int badgeCount;
}
```

## Outcome

**Status**: Buggy (one targeted fix required)

Generated a clean `ListView.builder` structure with correct dark theme styling matching the colour scheme. One bug: the progress bar width calculation used `entry.weeklyCount / 100` (hard-coded maximum) instead of dividing by the top user's count — causing progress bars to overflow or disappear when weekly counts exceeded 100 or fell below 10.

## Human Modifications

- Fixed progress bar calculation to `entry.weeklyCount / entries.first.weeklyCount`
- Clamped result to `0.0–1.0` to prevent rendering overflow
- Adjusted font sizes and padding to match the existing app design system
