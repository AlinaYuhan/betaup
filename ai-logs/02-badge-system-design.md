# Log 02 — Gamification Badge System Design (Claude Code)

**Tool**: Claude Code (Anthropic)  
**Component**: `Badge.java`, `BadgeCriteriaType.java`, `BadgeCatalogInitializer.java`  
**Date**: April 2026

## Prompt

```
Design a gamification badge system for a climbing tracking app. I need:

1. A JPA entity for Badge with fields: badgeKey (unique), name, description, 
   threshold (int), criteriaType, category, and standard audit fields.

2. A BadgeCriteriaType enum covering: total logs, completed climbs, flash climbs, 
   gym check-ins, unique gyms visited, posts created, likes received, comments made, 
   and coach feedback received.

3. An ApplicationRunner (BadgeCatalogInitializer) that seeds an initial catalogue 
   of ~15-18 badges across meaningful categories. The app tracks bouldering sessions, 
   individual route completions, flash results, gym visits, and community posts.

Use Spring Boot 3.2, JPA/Hibernate, Lombok @Builder. Make it idempotent — 
upsert by badgeKey rather than insert-only.
```

## Outcome

**Status**: Success (after domain tuning)

Generated a complete 3-file implementation: `BadgeCriteriaType` enum with 9 criteria types, `Badge` entity with `@Builder` and proper JPA annotations, and `BadgeCatalogInitializer` seeding 18 badges across LEVEL / CHALLENGE / VENUE / SOCIAL categories.

Two issues required human correction:
- Threshold values (e.g. 30 sends for "Intermediate") were calibrated for a generic fitness app — too low for real climbing progression
- SOCIAL category underweighted community engagement

## Human Modifications

- Adjusted thresholds to reflect actual climbing progression (100 sends → "Century Climber", 10 flashes → "Flash Master")
- Expanded SOCIAL badges to include `LIKES_RECEIVED` and `COMMENTS_MADE`
- Added `@Order(2)` annotation after discovering initializer sequencing issue (see Log 05)
