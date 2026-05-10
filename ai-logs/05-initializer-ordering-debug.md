# Log 05 — Spring Boot Initializer Ordering Bug (Claude Code)

**Tool**: Claude Code (Anthropic)  
**Component**: `BadgeCatalogInitializer.java`, `DemoAccountInitializer.java`  
**Date**: May 2026

## Prompt

```
My DemoAccountInitializer runs but badgeRepository.findByBadgeKey() always 
returns empty Optional. BadgeCatalogInitializer is supposed to seed the badge 
catalogue first — here are both files. The award() calls complete without errors 
but the demo account ends up with zero badges. No exception is thrown anywhere. 
What's wrong?

[Both initializer files appended in full]
```

## Outcome

**Status**: Success

Claude identified the root cause immediately: `BadgeCatalogInitializer` had no `@Order` annotation, which defaults to `Integer.MAX_VALUE` (lowest priority) in Spring's `ApplicationRunner` ordering. This meant it ran *after* `DemoAccountInitializer` despite appearing to seed data first. The badge table was empty at the moment the `award()` call ran — causing a silent failure with no exception.

This was a non-obvious Spring Boot framework behaviour that was difficult to diagnose from symptoms alone.

## Human Modifications

- Added `@Order(2)` to `BadgeCatalogInitializer`
- Added `@Order(3)` to `DemoAccountInitializer`  
- Audited all other `ApplicationRunner` beans in the project and assigned explicit `@Order` values to prevent the same issue recurring
- Added a log statement confirming badge count after seeding for future debugging
