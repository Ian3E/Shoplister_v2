---
target: settings
total_score: 28
p0_count: 0
p1_count: 2
timestamp: 2026-07-18T21-39-24Z
slug: source-features-settings-settingsview-swift
---
Method: dual-agent (A: 85aceb94-2f4a-4f09-8098-df4713ff60dc · B: a40f5a22-5845-457f-9064-8e5ab51192e4)

# Critique: Settings

**Target:** `Source/Features/Settings/SettingsView.swift` (+ Settings section surfaces)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Theme/text drafts lack explicit pending vs applied cue |
| 2 | Match System / Real World | 3 | “Device” vague; “Reset library” misframes language change |
| 3 | User Control and Freedom | 3 | Done and swipe both commit drafts—no abandon-without-save |
| 4 | Consistency and Standards | 3 | About links hardcode blue; Theme uses custom plain layout |
| 5 | Error Prevention | 4 | Strong confirms on language, import replace, clear library |
| 6 | Recognition Rather Than Recall | 2 | Gestures / sections / language far from where users need them |
| 7 | Flexibility and Efficiency | 2 | No Settings search; App features rows not actionable shortcuts |
| 8 | Aesthetic and Minimalist Design | 3 | Clean root; App features wall + five toggle sections add noise |
| 9 | Error Recovery | 2 | Clear/language irreversible; backup errors may be system jargon |
| 10 | Help and Documentation | 3 | Solid catalog + footers, but help is deep and non-actionable |
| **Total** | | **28/40** | **Good** |

## Anti-Patterns Verdict

**LLM assessment:** Passes product/iOS trust tests — first-party Settings sheet (grouped list, SF Symbols, gradient root tiles, Done). Not SaaS cards or AI cream/eyebrow tropes. Residual polish: hardcoded tile RGB, About rows forced blue, a few hard-coded preview point sizes.

**Deterministic scan:** `detect.mjs` on Settings Swift → exit 0, **0 findings**. `.swift` is outside HTML/CSS scannable extensions — empty means unscannable, not verified clean. No Settings-related HTML findings used.

**Visual overlays:** Not available (native SwiftUI sheet; no HTML inject target).

## Overall Impression

Settings is trustworthy HIG tools UI with excellent live Theme/Text Size Store previews and strong destructive confirms. Biggest gaps: bury gesture help under About, language/reset framing risk for bilingual households, and sub-44pt theme swatches — not visual slop.

## What's Working

1. **HIG-shaped root** — Gradient `SettingsRootRowLabel` tiles + Done feel native and on-brand.
2. **Live Store previews** — Theme/Text Size + `SettingsStoreListPreview` make preferences concrete (incl. EN/HE demo).
3. **Destructive-path discipline** — Language / import / clear confirms and footers protect data without drama.

## Priority Issues

### [P1] Gesture & power-feature help buried and non-actionable
- **What:** Pull/pinch/shake etc. only in About → App features; rows don’t deep-link to related toggles.
- **Why:** Users looking for “how do I…” won’t find Store behaviors.
- **Fix:** Promote Tips/Gestures (or under Shopping list); link feature rows to matching settings where they exist.
- **Suggested command:** `/impeccable onboard` / `/impeccable clarify`

### [P1] Library language IA + “Reset library” framing
- **What:** Language only under Item library; confirm button says “Reset library” for a language switch + wipe.
- **Why:** Bilingual households miss Language at root; label spikes fear / wrong mental model.
- **Fix:** Surface Language higher; rename confirm to match outcome; keep severity in the message.
- **Suggested command:** `/impeccable clarify`

### [P2] Theme/text drafts commit on any dismiss
- **What:** ContentView commits drafts when Settings closes (Done or swipe).
- **Why:** Preview-then-abandon is natural; accidental swipe locks loud theme/huge type.
- **Fix:** Cancel vs Done, or commit only from Done.
- **Suggested command:** `/impeccable harden`

### [P2] Theme swatch hit targets under 44pt
- **What:** Preset circles / ColorPicker frame **28×28**.
- **Why:** Misses HIG touch floor for motor / low-vision users.
- **Fix:** Visual 28pt dots inside ≥44pt hit areas.
- **Suggested command:** `/impeccable adapt`

### [P3] Section management invisible from Settings Item library
- **What:** `GroupTagEditorSheet` only from Store/Library toolbars, not Settings.
- **Why:** “Manage sections” seekers hit a dead end (language/backup/clear only).
- **Fix:** Add Home/Store sections links that present the same sheet.
- **Suggested command:** `/impeccable shape` / `/impeccable distill`

## Persona Red Flags

- **Jordan:** Gestures under About; “Device” unclear; sections not in Item library Settings; five shopping toggles with no recommended default.
- **Sam:** 28pt theme swatches; hard-coded preview sizes; Contact Support missing a11y hint; long App features scroll.
- **Maya:** Language buried + “Reset library” confirm; UI language ≠ library language distinction under-explained on picker footer; Theme preview locks medium text size.

## Minor Observations

Five single-toggle Shopping sections feel long; About `.blue` not accent; Theme preview “+” dead but may still be in a11y tree; shopping/library root tiles share similar blue gradient; Theme/Text Size plain vs insetGrouped elsewhere.

## Questions to Consider

1. Why is the best product education dressed as About trivia instead of Shopping-list help?
2. Should Language be a first-class root row for a bilingual product?
3. What if Theme/Text Size committed live like toggles, and Done only dismissed?
4. Does “Device” earn its own chapter?
5. If Maya never opens About, does she learn UI language ≠ library language?
