# Login Beranda Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the mobile login and beranda screens into a cleaner operational dashboard experience.

**Architecture:** Add a focused shared UI file for small card, status, metric, and empty-state widgets. Rework `LoginScreen` and `BerandaScreen` layouts while keeping their existing controllers, repository calls, routes, and session flow.

**Tech Stack:** Flutter, Material 3, existing `AppTheme`, existing assets.

---

### Task 1: Shared Dashboard Widgets

**Files:**
- Create: `lib/shared/widgets/dashboard_widgets.dart`
- Test: `test/dashboard_widgets_test.dart`

- [ ] Add a widget test for `MetricTile` showing title, value, and unit.
- [ ] Implement `AppSurfaceCard`, `StatusPill`, `MetricTile`, and `EmptyPanel`.
- [ ] Run `flutter test test/dashboard_widgets_test.dart`.

### Task 2: Login Screen Polish

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`

- [ ] Keep existing login logic and controllers.
- [ ] Rebuild the visual layout with a constrained illustration area, clean bottom form card, stronger button, and compact logo/version footer.
- [ ] Keep existing validation and error display.

### Task 3: Beranda Dashboard Refresh

**Files:**
- Modify: `lib/features/beranda/screens/beranda_screen.dart`

- [ ] Keep existing `_loadUser`, `_fetchData`, timer refresh, and logout flow.
- [ ] Refresh the header with clearer user/date/status hierarchy.
- [ ] Add a primary RTS status card and four metric tiles for humidity, battery, temperature, and power.
- [ ] Keep the menu routes unchanged while improving menu card layout and tap feedback.

### Task 4: Verification

**Files:**
- All touched Dart files

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Fix any analyzer or test failures before finishing.
