# Kontrol ADR Mobile Control Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Kontrol ADR into a mobile-friendly control panel that keeps existing backend control behavior.

**Architecture:** Keep `KontrolAdrScreen` as the route entry point, add a focused status model for RTS labels, and refactor the screen into compact local widgets for status, power, measurement, progress, and prism data. Backend calls remain in `KontrolRepository`.

**Tech Stack:** Flutter, Material widgets, existing `AppColors`, existing `KontrolRepository`.

---

### Task 1: Status Model

**Files:**
- Create: `lib/features/kontrol_adr/models/kontrol_rts_status.dart`
- Test: `test/kontrol_rts_status_test.dart`

- [ ] Write failing tests for Running, Standby, and Off labels.
- [ ] Implement `KontrolRtsStatus.fromSensors`.
- [ ] Run the focused status test.

### Task 2: Control Panel UI

**Files:**
- Modify: `lib/features/kontrol_adr/screens/kontrol_adr_screen.dart`

- [ ] Replace the simple status bar with a large status card.
- [ ] Replace two raw power buttons with a power control card.
- [ ] Rework access code/start/stop into an action card.
- [ ] Convert process log into a timeline-style section.
- [ ] Make prism live data compact and scan-friendly.

### Task 3: Verification

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
