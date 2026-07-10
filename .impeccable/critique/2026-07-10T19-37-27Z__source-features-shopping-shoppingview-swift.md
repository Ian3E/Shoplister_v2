---
target: Store
total_score: 26
p0_count: 0
p1_count: 2
timestamp: 2026-07-10T19-37-27Z
slug: source-features-shopping-shoppingview-swift
---
Method: dual-agent (A: 880e9f89-8e4c-4760-ac02-d5ac3f66f938 · B: 45d1e3cf-783e-4301-a9f2-39446be315cc)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Subtitle and dimmed sections work; qty=1 hidden; pull-to-clear has no post-action confirmation |
| 2 | Match System / Real World | 3 | Store sections fit the task; pull gestures and custom icons diverge from standard checkbox/refresh models |
| 3 | User Control and Freedom | 3 | Undo for clears (menu + shake); pull-to-clear is immediate with recovery only if undo paths are known |
| 4 | Consistency and Standards | 2 | Home uses expandable quantity pill; Store rows use static qty + long-press menu only |
| 5 | Error Prevention | 2 | Clear list confirms; pull-to-clear has no guard — high accidental-clear risk while scrolling |
| 6 | Recognition Rather Than Recall | 2 | Pull/pinch/shake/long-press largely invisible; empty add hint retires after 5 trips |
| 7 | Flexibility and Efficiency | 3 | Rich power features if discovered (pinch, shake, sort-checked, save recipe) |
| 8 | Aesthetic and Minimalist Design | 3 | Flat, scannable list; persistent top chrome + bottom glass + when empty adds noise |
| 9 | Error Recovery | 3 | Menu undo after clears; shake undo adds extra alert; no toast-undo at point of pull-to-clear |
| 10 | Help and Documentation | 2 | Settings explain toggles; Store gestures not taught in UI after hint retires |
| **Total** | | **26/40** | **Acceptable — solid native baseline; discoverability and destructive-gesture guardrails need work** |

## Anti-Patterns Verdict

**LLM assessment:** Store reads **native and trustworthy**, not AI-generated. Plain lists, systemBackground, SF typography, one accent tint, quiet completion (dimmed headers, collapsible sections). No cream surfaces, card grids, gradient text, or decorative glass on list rows. Residual glass (save toast, bottom Open Home button) is brief platform chrome, not template slop.

**Deterministic scan:** `detect.mjs` on `ShoppingView.swift` returned **1 finding** — `bounce-easing` at line 9 (`.spring(`). **False positive:** SwiftUI damped springs ≠ CSS bounce/elastic. No HTML/CSS anti-patterns apply to Swift source.

**Browser overlays:** Not applicable (native iOS SwiftUI).

## Overall Impression

The Store tab delivers on PRODUCT.md's "task-first Store" promise: check-off is fast, sections are scannable, bilingual/RTL is thoughtful, and completion states recede appropriately. The single biggest opportunity is **making power features safe and discoverable** — especially pull-to-clear (destructive, unconfirmed) and the gap between Home's quantity pill and Store's long-press-only quantity path.

## What's Working

1. **Quiet completion** — Dimmed all-checked section titles, auto/manual collapse, optional sort-checked bucket, and snappy list mutations keep remaining work obvious without card chrome.
2. **Bilingual craft** — Manual row mirroring, quantity on the physical leading edge per language, combined nav accessibility labels — RTL is integrated, not bolted on.
3. **Native list density** — Full-bleed rows, 44pt-scaled touch targets, tap-to-check, inter-group hairlines without nested cards — reads at arm's length in an aisle.

## Priority Issues

### [P1] Pull-to-clear is destructive without confirmation
- **Why:** ~150pt bottom pull clears all checked items on finger-up with no alert or inline undo — easy misfire while one-hand scrolling.
- **Fix:** Add confirmation, or instant clear + bottom toast with Undo (Mail pattern); surface undo at the point of action.
- **Suggested command:** `/impeccable harden Store pull-to-clear`

### [P1] Hidden gestures are undiscoverable and poorly taught
- **Why:** Pull-to-add/clear, pinch collapse, shake undo, and long-press quantity live outside standard affordances; empty hint fades after 5 trips and bottom "+" opens Home, not pull-to-add.
- **Fix:** Coach mark or Settings explainer; list-level accessibility hints; fix empty-state copy to match actual "+" behavior.
- **Suggested command:** `/impeccable onboard Store gestures`

### [P2] Store quantity adjustment is inconsistent with Home
- **Why:** Store shows qty only when >1; adjustment requires long-press context menu; Home uses expandable pill; only increase accessibility action on rows.
- **Fix:** Swipe +/- or tap-to-expand pill parity; always show qty on unchecked rows; add decrease accessibility action.
- **Suggested command:** `/impeccable shape Store row quantity`

### [P2] Empty-state copy conflates two add paths
- **Why:** Hint says "Tap + or pull down to add" but bottom toolbar "+" opens Home library, not pull-to-add search.
- **Fix:** Split copy or make empty-state primary action launch pull-to-add directly.
- **Suggested command:** `/impeccable clarify Store empty state`

### [P3] Nav title hidden when list is empty
- **Why:** Principal toolbar only shows when list has items — empty Store loses "Shopping list" context.
- **Fix:** Show title + "All done" subtitle when empty overlay is visible.
- **Suggested command:** `/impeccable layout Store navigation bar`

## Persona Red Flags

**Alex (Power User):** Pinch collapse has zero visible affordance. Shake undo requires alert while menu undo is one-tap — inconsistent tiers. No swipe/inline qty on Store vs Home pill. Undo menu swap is easy to miss after fast clear.

**Jordan (First-Timer):** Empty hint "+" does not match bottom button (opens Home). No pull-to-add teaching after hint retires. Section collapse requires discovering chevron tap. Share/save only under ⋯.

**Casey (One-Handed Mobile):** Pull-to-clear at list bottom is highest accidental-destruct risk. Gear and ⋯ in top corners — poor thumb reach. Pull-to-add requires scroll-to-top latch first. All-checked alert interrupts checkout when last item checked by someone else.

## Minor Observations

- Three "add" visual dialects on one screen: hint `plus.circle.fill`, pull overlay filled circle, bottom bar plain `plus` in glass.
- Shopping rows lack explicit combined accessibilityLabel (checked + qty when qty==1 omitted).
- Checked rows hide quantity — can't verify count without unchecking.
- Platform Liquid Glass on save toast and bottom Open Home — ancillary, not on list rows; optional product pass if strict zero-glass Store is desired.

## Questions to Consider

- If pull-to-clear always depends on undo discovery, should it stay a gesture or move menu-only with confirmation?
- Should empty-state bottom "+" launch pull-to-add search instead of Home, making the hint literally true?
- Does hiding quantity when == 1 help scanning, or force long-press discovery for the most common case?
