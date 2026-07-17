---
target: new item page
total_score: 23
p0_count: 0
p1_count: 4
timestamp: 2026-07-12T19-18-40Z
slug: source-features-inventory-newitemview-swift
---
Method: dual-agent (A: 5e3422ab-fedc-4220-9b01-7ba0417284f6 · B: 7b31b857-0a08-4f20-9a5d-364d764cc022)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 2 | Disabled Save is silent; photo load/save failures invisible |
| 2 | Match system / real world | 2 | Home/Store section model assumes welcome-explainer memory |
| 3 | User control and freedom | 3 | Cancel + swipe dismiss; no unsaved-changes guard |
| 4 | Consistency and standards | 3 | Matches ItemEditor form; toolbar placements differ from editor |
| 5 | Error prevention | 2 | Name guard works; photo and section-create failures unhandled |
| 6 | Recognition rather than recall | 2 | Section semantics not on-form; Store add-to-list outcome hidden |
| 7 | Flexibility and efficiency | 3 | Prefill, defaults, inline new section, addToShoppingAfterSave |
| 8 | Aesthetic and minimalist design | 3 | Clean Form; photo block always expanded |
| 9 | Error recovery | 2 | Silent failures; disabled Save unexplained |
| 10 | Help and documentation | 1 | No section footers or contextual help on this screen |
| **Total** | | **23/40** | **Acceptable — clarity and feedback gaps for first-timers** |

## Anti-Patterns Verdict

**LLM assessment:** Not AI slop. Standard SwiftUI `Form` with system pickers, SF Symbols, Cancel/Save toolbar — reads as native iOS utility, not a web port. It is **template-native bland**: interchangeable with a generic settings form and misses Shoplister's distinctive Home-vs-Store mental model taught in the welcome explainer but absent here.

**Deterministic scan:** `detect.mjs` not applicable (native SwiftUI). Assessment B technical scan found 0 P0, 5 P1, 8 P2, 5 P3 issues. No browser visualization (not a viewable web target).

## Overall Impression

The New Item sheet is structurally sound and on-brand for a calm native grocery app — but it underserves first-timers at the exact moment they need the Home/Store concept explained. The biggest opportunity is bridging welcome-explainer copy onto this form and making Save/photo outcomes visible, especially on the Store pull-to-add path where saving also adds to the shopping list invisibly.

## What's Working

1. **Shared section picker** — `CatalogItemSectionPicker` is reused in add and edit flows with inline "New section" creation; learn once, use everywhere.
2. **Bilingual care** — Name field RTL alignment, localized labels, stored names via `CatalogContentLocalization`.
3. **Smart entry paths** — Search prefill, default sections on appear, and `addToShoppingAfterSave` connect create → list with minimal taps for users who already understand the model.

## Priority Issues

### [P1] Home/Store section model unexplained on the form
- **Why:** Core Shoplister concept is non-obvious; welcome copy exists but this form only shows "Sections" + Home/Store pickers.
- **Fix:** Add section footers adapting welcome copy ("where you keep it" / "where you buy it"). Consider a clearer section header than generic "Sections".
- **Suggested command:** `/impeccable clarify NewItemView sections`

### [P1] Disabled Save with no explanation
- **Why:** Empty name → gray Save with zero feedback; Jordan assumes the app is broken.
- **Fix:** Inline hint under name field or accessibility hint on disabled Save.
- **Suggested command:** `/impeccable harden NewItemView validation`

### [P1] Store pull-to-add outcome invisible
- **Why:** When `addToShoppingAfterSave` is true, save adds to shopping list but UI never says so.
- **Fix:** Subtitle, banner, or contextual copy when opened from Store search.
- **Suggested command:** `/impeccable onboard NewItemView store-flow`

### [P1] Photo failures silent (load and save)
- **Why:** `try?` on photo load; `ItemImageStore.save` can fail without user feedback — preview may show but item saves without image.
- **Fix:** Surface errors in Photo section; verify save success.
- **Suggested command:** `/impeccable harden NewItemView photo handling`

### [P2] Name field doesn't auto-focus on blank open
- **Why:** Extra tap before typing on toolbar + path hurts mobile flow.
- **Fix:** `@FocusState` + focus on appear when no prefill.
- **Suggested command:** `/impeccable polish NewItemView focus`

### [P2] Dead `isInternetSearchPresented` state
- **Why:** Unused `@State` — leftover from abandoned feature.
- **Fix:** Remove.
- **Suggested command:** `/impeccable distill NewItemView`

## Persona Red Flags

**Jordan (first-timer):** "Sections" + Home/Store pickers with no inline definitions; "Undefined" default unexplained; gray Save with no reason; Store create path doesn't say item goes on shopping list.

**Casey (mobile):** Save/Cancel in top toolbar (thumb-unreachable); photo section adds scroll before quick add; no draft persistence on dismiss.

**Sam (accessibility):** Name field placeholder-only; disabled Save unexplained; photo preview unlabeled; pickers don't convey library vs shopping-list semantics when linearly navigating.

## Minor Observations

- Photo section always shows Library + Camera even when empty — could collapse behind "Add photo".
- `isValid` tag checks redundant after `onAppear` sets defaults.
- Section-name alert `TextField` lacks Hebrew alignment used elsewhere.
- "New section" as picker sentinel is non-idiomatic HIG and confuses VoiceOver selection.

## Questions to Consider

- Should New Item default to name-only save with sections silently defaulted for speed, teaching sections only on edit?
- When `addToShoppingAfterSave` is true, should the title be "Add to list" instead of "New Item"?
- Can section footers be shared between NewItemView and ItemEditorView to prevent drift?
