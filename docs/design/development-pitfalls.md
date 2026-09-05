# CatFocus Development Pitfalls Log

This document records pitfalls discovered during CatFocus development so future work can quickly check known issues before repeating mistakes.

## How To Use This Log

- Read this file before starting a new implementation phase.
- Add a short entry whenever a mistake, ambiguity, or tooling issue costs time.
- Keep entries actionable: symptom, why it matters, and what to do next time.
- Promote recurring or severe issues into `AGENTS.md` only after they become stable repo rules.

## Product Semantics

### Luna / Kuro Naming Drift

- **Symptom:** Onboarding used `Luna`, while earlier app screens and result copy referenced `Kuro`.
- **Why it matters:** CatFocus depends on a single Practice Partner relationship. Name drift makes the product feel like disconnected screens.
- **Rule:** Use `Luna` as the default cat name. If custom naming is added later, route it through one model and never hardcode alternate names in views.

### Too Many Fitness Concepts

- **Symptom:** `Health`, `Fitness`, `Fit Points`, and `Training Energy` were initially considered as separate user-facing values.
- **Why it matters:** Too many metrics make the app feel like a complicated sim instead of a focused companion product.
- **Rule:** Keep only `Fit Points` and `Fitness Score` as core values. Derive `Health Status` from `Fitness Score`. Use `Training Energy` only in narrative copy.

### Permanent Fitness Is Too Easy To Keep Healthy

- **Symptom:** A lifetime accumulated fitness score could let Luna stay healthy forever after early usage.
- **Why it matters:** The product should encourage ongoing practice, not one-time grinding.
- **Rule:** Treat `Fitness Score` as a recent-practice score based on recent training behavior. Keep the first implementation simple, but avoid modeling it as permanent lifetime progress.

### Formula Tuning Can Distract From UI Flow

- **Symptom:** It is easy to spend too much time tuning exact Fitness Score math before the core app flow exists.
- **Why it matters:** Early development should validate component standards, navigation, and resource containers first.
- **Rule:** Keep formula tests directional during Phase One. Verify that consistency increases score and failures reduce it, but avoid locking exact numeric formulas until the UI chain is usable.

## Design System

### Magic Numbers In Views

- **Symptom:** Pages can drift by manually tuning padding, offsets, frame sizes, corner radii, or shadows.
- **Why it matters:** Small visual changes become scattered UI diffs.
- **Rule:** Define reusable tokens first. Views should choose token values or component variants, not raw styling values.

### Direct Image Usage

- **Symptom:** Pages may directly call `Image("...")` and hand-tune frame sizes.
- **Why it matters:** Replacing static images with GIF, Lottie, or Rive later becomes expensive.
- **Rule:** Cat artwork goes through `CFCatAsset` and `CFCatHero`. The resource container owns sizing, alignment, and fallback behavior.

### Generic Components That Lose Product Meaning

- **Symptom:** Components named `CustomButton`, `RoundedCard`, or `OptionView` do not explain their role.
- **Why it matters:** Designers and developers cannot map Figma components to SwiftUI views confidently.
- **Rule:** Prefer semantic names such as `CFPrimaryButton`, `CFStatusPill`, `CFSelectableTile`, and `CFTrainingResultView`.

## Tooling

### Figma MCP Startup Timeout

- **Symptom:** Figma MCP calls sometimes fail with `timed out handshaking with MCP server`.
- **Why it matters:** Full-file Figma scans can block progress and waste time.
- **Rule:** Prefer node-level links or uploaded screenshots for analysis. Avoid full-file scans unless the MCP service is stable.

### No Existing Xcode Project

- **Symptom:** The repository started with documentation only, no `.xcodeproj`.
- **Why it matters:** Hand-writing a full Xcode project creates large generated diffs before standards are proven.
- **Rule:** If an Xcode project exists, integrate into the app target directly. If it does not, use a small Swift Package first to validate product models, design tokens, SwiftUI components, and previews.

### Nested Git Repository

- **Symptom:** The new Xcode project was created inside the outer CatFocus repo and includes its own `.git` directory.
- **Why it matters:** Adding the subdirectory from the outer repo can accidentally create submodule-like behavior or hide inner changes from the outer repo.
- **Rule:** Keep the Xcode project folded into the outer repo. The original nested `.git` was renamed to `CatFocus/.git-disabled-backup` and ignored so it no longer acts as a nested repository.

### SwiftData Template Macro Failure

- **Symptom:** The default Xcode SwiftData template failed to compile in the sandbox with `SwiftDataMacros.PersistentModelMacro` and `QueryMacro` plugin errors.
- **Why it matters:** Phase One does not need persistence, and template code can block unrelated UI foundation work.
- **Rule:** Remove SwiftData template dependencies until the product model actually needs persistence. Reintroduce storage deliberately behind focused model tests.
