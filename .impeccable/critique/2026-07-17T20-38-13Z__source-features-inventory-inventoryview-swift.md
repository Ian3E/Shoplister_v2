---
target: Home
total_score: 25
p0_count: 0
p1_count: 4
timestamp: 2026-07-17T20-38-13Z
slug: source-features-inventory-inventoryview-swift
---
Method: dual-agent (A: 87f39227-1c30-4c25-b67d-5ede385b1a74 · B: d074c2bc-2978-42b3-84d9-37a57a6a18f6)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 3 | In-shopping tint/pill clear; empty search query blanks the list with no status |
| 2 | Match system / real world | 2 | Store→Home opens via glass **+** while meaning “library”; title “Item library” vs Home mental model |
| 3 | User control and freedom | 3 | Back/Done/search dismiss; no undo after tap removes from shopping |
| 4 | Consistency and standards | 2 | Push-from-Store vs PRODUCT “tabs”; Home Edit also edits Store sections; toolbar hits 30–36pt |
| 5 | Error prevention | 3 | Delete confirms; single tap removes from shopping as easily as adds |
| 6 | Recognition rather than recall | 2 | Tap-to-add unlabeled; Unsorted hidden until title tap; Recipes icon-only |
| 7 | Flexibility and efficiency | 3 | Exact-match Return, quantity pill, bulk edit, recipes→Store — strong once learned |
| 8 | Aesthetic and minimalist design | 3 | Flat native list on brand; principal + glass section bar + bottom chrome can stack densely |
| 9 | Error recovery | 2 | No-match Create Item good; empty library dead end; accidental remove = re-tap only |
| 10 | Help and documentation | 2 | Welcome overlays help; on Home itself no tap-to-add / section / unsorted cues |
| **Total** | | **25/40** | **Acceptable — activation & discoverability hold it back** |

## Anti-Patterns Verdict

**LLM assessment:** Not web/AI slop. Fluent iPhone users would mostly trust this as careful native craft—plain List, system searchable, SF Symbols, semantic labels, accent on membership. Trust hiccups are **mismatched affordances** (Store `+` opens library) and **hidden grammar** (tap = shopping toggle; blank empty-query search), not cream gradients or card grids.

**Deterministic scan:** `detect.mjs` attempted; Swift is outside SCANNABLE_EXTENSIONS — empty `[]` is not a clean bill of health. Manual technical scan: **0 P0, 3 P1, 7 P2, 3 P3**. No browser visualization (native SwiftUI).

**Agreement:** Design and technical both flag Home row a11y lagging Store, missing Reduce Motion on Home, and under-44pt toolbar/pill targets. Design emphasizes empty/search teaching and entry metaphor; detector adds preference-storm/UUID remount and silent Move→new-section failures.

## Overall Impression

Home’s quiet add-to-list feedback (tint + glass quantity pill) is the brand peak—and the surface undersells how to start and what a tap means. Biggest opportunity: teach empty/first catalog and make Store→Home look like “library,” not “create,” while bringing VoiceOver and Reduce Motion up to Store’s bar.

## What's Working

1. **Quiet shopping membership** — Theme tint + expandable glass pill makes “on the list” obvious without banners.
2. **Bilingual layout craft** — Section title bar pins to reading-start; rows/pills mirror via `CatalogLayoutMirroring`.
3. **Native power tools when sought** — Context menu, selection edit + Move, search Return exact-match — experts aren’t trapped.

## Priority Issues

### [P1] Empty Home & empty-query search are non-teaching dead ends
- **Why:** “No items” with no CTA; empty search query clears all rows — Jordan cannot start the core loop.
- **Fix:** Empty library: short why + primary Add item. Empty query: keep catalog visible or show “Type to search or create.”
- **Suggested command:** `/impeccable onboard Home empty & search`

### [P1] Store→Home entry uses “add” visual language
- **Why:** Tinted glass **plus** opens the library (a11y says open Home); fights real-world “add” and conflicts with edit-mode +.
- **Fix:** House/library (or labeled) control for open Home; reserve + for create.
- **Suggested command:** `/impeccable clarify Store→Home entry`

### [P1] Home rows lack VoiceOver labels / button traits (Store has them)
- **Why:** Rows expose name Text only; UIKit context overlay has no a11y bridge — Sam can’t tell on-list state or activate add.
- **Fix:** Match Store: consolidated label (name + shopping state), `.isButton`, accessibility actions for add/remove / qty.
- **Suggested command:** `/impeccable audit Home row accessibility`

### [P1] Primary action (tap = toggle shopping) is invisible grammar
- **Why:** No on-row hint; remove is as easy as add; high one-handed mis-tap cost.
- **Fix:** First-run cue on Home; consider undo on remove; VoiceOver value for on/off list.
- **Suggested command:** `/impeccable onboard Home tap-to-add` · `/impeccable harden accidental remove`

### [P2] No Reduce Motion gating on Home (Store gates)
- **Why:** Edit chrome, section scroll, quantity pill springs ignore `accessibilityReduceMotion`.
- **Fix:** Mirror ShoppingView’s reduce-motion paths.
- **Suggested command:** `/impeccable harden Home reduce motion`

### [P2] Unsorted section is a hidden mode
- **Why:** Only appears after tapping its title — items seem to vanish.
- **Fix:** Always show when non-empty, or persistent “Unsorted (N)” chip.
- **Suggested command:** `/impeccable distill Unsorted reveal`

### [P2] Toolbar / pill targets under 44pt HIG
- **Why:** Move 30pt, circular chrome 36pt, steppers 26–36pt — intentional Liquid Glass tradeoff on Store; Home inherits it.
- **Fix:** Expand hit boxes without breaking glass circles where possible; document the 36pt tradeoff if kept.
- **Suggested command:** `/impeccable audit Home touch targets`

## Persona Red Flags

**Jordan:** Store + → expects add, gets library; empty “No items” / blank search; never told tap = shopping; Edit menu assumes dual-section model; Recipes icon-only.

**Casey:** Section slider at top (thumb-awkward); Edit/Done top-trailing; full-row tap next to qty pill invites fat-finger remove.

**Sam:** No row a11y labels/traits; section chips lack `.isSelected`; no Reduce Motion; explainers use hard-coded 18pt type.

## Minor Observations

- Inactive section title gray (~0.78 white) may fail comfortable contrast.
- Deferred Liquid Glass search attach can miss a frame of bottom search on push.
- `lineLimit(1)` truncates long HE/EN names without full-name affordance.
- Dead `onSelectToggleShopping: {}` and unused non-plain row branch (P3 distill).
- Silent failure when Move → New section `addTag` returns nil.

## Questions to Consider

- If Home is “where I keep it,” why is the front door a **plus** on Store?
- Should an empty search field hide the library or invite typing over a visible catalog?
- Is tap-to-toggle right for a library, or should tap open/edit and a dedicated control add?
- Does editing Store sections from Home teach the model, or tangle IA?
