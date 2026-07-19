---
target: home
total_score: 25
p0_count: 0
p1_count: 3
timestamp: 2026-07-18T20-43-10Z
slug: source-features-inventory-inventoryview-swift
---
Method: dual-agent (A: e34f5b38-91ba-4984-8c77-e460be2ab9f4 · B: 9a74a5ea-d1ac-42bd-afa1-74b616089a31)

# Critique: Home / Library

**Target:** `Source/Features/Inventory/InventoryView.swift` (Library tab)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Shopping tint + pill strong; empty-query search blanks list with little status |
| 2 | Match System / Real World | 2 | Tab “Library” vs title “Item library” vs “Home sections”; Store sections under Library Edit |
| 3 | User Control and Freedom | 3 | Done / dismiss good; shopping remove has no undo |
| 4 | Consistency and Standards | 2 | Library empty ≪ Store empty; rooted tab uses custom principal not large title |
| 5 | Error Prevention | 3 | Delete/Move guards good; same tap adds *and* removes from shopping |
| 6 | Recognition Rather Than Recall | 2 | Icon-only Saved lists; minimized search; hidden Undefined section |
| 7 | Flexibility and Efficiency | 3 | Bulk move/delete, search-create, section jump, quantity pill — strong for experts |
| 8 | Aesthetic and Minimalist Design | 3 | Flat list on brand; top+bottom+section chrome approaches clutter |
| 9 | Error Recovery | 2 | Create Item on no-match good; empty library and accidental remove weak |
| 10 | Help and Documentation | 2 | Welcome exists; Library empty/gestures give no in-place help |
| **Total** | | **25/40** | **Acceptable** |

## Anti-Patterns Verdict

**LLM assessment:** Passes the product/iOS slop tests. Reads as a competent native utility (plain List, system searchable, SF Symbols, one accent tint)—not cream/glass/eyebrow AI aesthetics. Residual risk is **over-chrome + naming fog** (Home / Library / Item library), not decorative slop.

**Deterministic scan:** `detect.mjs` on `InventoryView.swift` → exit 0, **0 findings** (HTML/CSS detector; native Swift outside domain). Nearby HTML fallback hit `docs/privacy.html` Roboto (`design-system-font`)—unrelated to Home; treat as noise.

**Visual overlays:** Not available. Native iOS target; no localhost HTML surface for `detect.js` injection.

## Overall Impression

Home’s row craft is excellent—tap to add, accent + quantity pill, section jump rail. The biggest opportunity isn’t prettier chrome: teach the empty library, unify naming around “Library,” and make secondary controls (search, Saved lists) recognizable without adding more top-bar noise.

## What's Working

1. **Task-first row interaction** — Tap toggles shopping; accent + expandable quantity pill make status glanceable without badges.
2. **Section title bar + scroll sync** — High-craft jump rail for large bilingual catalogs; Liquid Glass pin matches DESIGN.
3. **Edit mode choreography** — Shopping status hides, reorder chrome deferred; Move/Delete confirmation patterns are solid.

## Priority Issues

### [P1] Empty library is a dead end
- **What:** Centered “No items” only—no CTA, icon, or path to Add/Search.
- **Why:** First-timers and wiped libraries get no next step; Store already teaches with a richer empty state.
- **Fix:** Match Store quality: short title, one sentence, primary **Add item** (optional Search). Honor Reduce Motion.
- **Suggested command:** `/impeccable onboard` (Library empty state)

### [P1] Naming / IA fog (Home · Library · Item library · Home sections)
- **What:** Tab “Library,” principal “Item library,” Edit menu “Home sections”; Store sections reachable from Library Edit.
- **Why:** Users must translate three names for one place; bilingual households pay extra teaching cost.
- **Fix:** One user-facing noun (**Library**) everywhere in UI; rename menu to “Library sections”; keep Store sections clearly labeled or under Settings.
- **Suggested command:** `/impeccable clarify` (Library naming)

### [P1] Secondary chrome discoverability (minimized search + icon Saved lists)
- **What:** Minimized search + top-trailing icon-only Saved lists (`book.pages`).
- **Why:** Easy to miss one-handed; first-timers won’t guess book = Saved lists.
- **Fix:** Clear search glyph + VO on collapsed control; labeled Saved lists once, or move under a labeled menu—don’t leave two unlabeled icons competing.
- **Suggested command:** `/impeccable distill` (Library toolbar)

### [P2] Empty search presentation blanks the catalog
- **What:** Presenting search with empty query hides all rows.
- **Why:** Feels like data loss vs “filter as you type.”
- **Fix:** Show full catalog until query non-empty, or an in-list “Type to filter” placeholder.
- **Suggested command:** `/impeccable harden` (search empty state)

### [P2] Arm’s-length inactive section titles + irreversible shopping toggle
- **What:** Inactive section titles ~0.78 gray; row tap removes from shopping with no undo.
- **Why:** Harder to scan at aisle distance; fat-finger remove mid-planning.
- **Fix:** Bump inactive title contrast; optional undo snack or asymmetric remove (easy add, deliberate remove).
- **Suggested command:** `/impeccable colorize` / `/impeccable harden`

## Persona Red Flags

**Casey (distracted mobile):** Saved lists top-trailing (outside thumb zone); minimized search adds a tap; same-row remove is high mis-tap cost; many sections to scrub horizontally.

**Jordan (first-timer):** Empty “No items” with no next step; Edit opens Items / Home sections / Store sections; icon-only Saved lists; empty search looks broken.

**Maya (bilingual household, arm’s-length):** Inactive section contrast weak for long Hebrew titles; `lineLimit(1)` truncates HE/EN names; search Dynamic Type pinned while list scales; Home/Library naming amplifies cross-language teaching.

## Minor Observations

- Rooted Library uses custom principal instead of large title—acceptable craft, slight HIG drift.
- “Create Item” title case vs “Add item” sentence style.
- Reduce Motion honored on Shopping empty/pull more than on Home principal crossfade / section scrolls.
- No-match Create button is fine; could echo the query in the body.
- Cognitive load: ~5–6 checklist failures on first visit (chrome concurrency, section bar >4 options, naming memory).

## Questions to Consider

1. If Library’s job is building the list from home, why is Saved lists a peer of Edit in the top bar?
2. Should removing from shopping ever be as easy as adding?
3. What if the section bar showed only the active title + a menu once you have >4 sections?
4. Is “Home” still a user-facing word, or an internal metaphor that should leave UI copy?
5. Would a confident empty state that teaches only **Add item** beat another explainer overlay?
