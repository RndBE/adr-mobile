# Hasil Report Dashboard Mobile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Hasil Pengukuran and Detail Pengukuran into a mobile report dashboard.

**Architecture:** Keep existing repository endpoints and models. Add a small summary helper model for report counts, then refactor the two screens with dashboard cards, filters, summary headers, clearer status badges, and ASCII-safe coordinate labels.

**Tech Stack:** Flutter, existing Material widgets, existing `AppColors`, `HasilRepository`.

---

### Task 1: Summary Helpers

**Files:**
- Create: `lib/features/hasil_pengukuran/models/hasil_report_summary.dart`
- Test: `test/hasil_report_summary_test.dart`

- [ ] Write tests for log and detail report summaries.
- [ ] Implement summary helpers.
- [ ] Run focused tests.

### Task 2: Hasil Pengukuran Screen

**Files:**
- Modify: `lib/features/hasil_pengukuran/screens/hasil_pengukuran_screen.dart`

- [ ] Add report summary card.
- [ ] Add All/R0/Event/Site filters.
- [ ] Restyle log cards as mobile report items.

### Task 3: Detail Pengukuran Screen

**Files:**
- Modify: `lib/features/hasil_pengukuran/screens/detail_hasil_screen.dart`

- [ ] Add detail summary card.
- [ ] Restyle Event and Harian cards.
- [ ] Replace broken encoded labels with `N0`, `E0`, `Z0`, `N1`, `E1`, `Z1`, `dN`, `dE`, `dZ`.

### Task 4: Verification

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
