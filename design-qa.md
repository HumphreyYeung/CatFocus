# Paywall Trial Reminder Design QA

- Source visual truth: `/Users/humphreyyeung/Downloads/IMG_7427.PNG`, used as the interaction and grouping reference for the trial-ending reminder above the primary CTA.
- Baseline implementation: `/private/tmp/catfocus-paywall-before-reminder.png`.
- Iteration 1 implementation: `/private/tmp/catfocus-paywall-trial-reminder.png`.
- Final implementation: `/private/tmp/catfocus-paywall-trial-reminder-final.png`.
- Viewport: iPhone 16 Pro Simulator, iOS 18.6, portrait, 402 × 874 points.
- Pixels and normalization: source 1179 × 2556 px at 3× (393 × 852 points); implementation 1206 × 2622 px at 3× (402 × 874 points). The screens intentionally use different device viewports, so the comparison evaluates the reminder/CTA relationship and vertical hierarchy rather than literal whole-screen coordinates.
- State: Start-training Paywall, Weekly Training selected, reminder enabled.

## Full-view comparison

The final Paywall adopts the reference's conversion pattern: a trial-ending reminder sits immediately above the primary free-trial CTA and reads as part of the same decision area. CatFocus intentionally retains its monochrome palette, native SwiftUI switch, existing pricing cards, and existing graphite CTA instead of copying the reference's purple styling.

The final pass keeps both pricing options fully visible, gives `Cancel Anytime` clear separation from both the plan selector and reminder control, and preserves the primary button's original bottom anchor and legal-link relationship.

## Focused-region comparison

No separate crop was required because the source and final full-resolution screenshots clearly show the complete reminder, switch, CTA, cancellation copy, and adjacent plan card. The important control labels, corner treatment, spacing, and switch state remain readable at original resolution.

## Required fidelity surfaces

- Fonts and typography: the reminder uses the app's rounded system typography at 12.5pt semibold, subordinate to the CTA and consistent with Paywall supporting text.
- Spacing and layout rhythm: the 48pt reminder row has a full touch target, 16pt horizontal inset, an 8pt relationship to the CTA, and balanced spacing around `Cancel Anytime`; both pricing cards remain unobscured.
- Colors and visual tokens: the reminder uses `surfaceWhisper`, `textSecondary`, and the existing graphite tint. The CTA color and dimensions are unchanged.
- Image quality and asset fidelity: the existing Luna treadmill video and white media treatment remain intact; the reminder uses the native SF Symbols bell and native iOS switch.
- Copy and content: `Remind me before trial ends` communicates the reassurance directly; its accessibility hint specifies that the reminder arrives one day before the three-day trial ends.

## Interaction verification

- The reminder defaults to enabled and was toggled off and back on in Simulator.
- Disabling it removes a pending trial reminder.
- Starting the weekly trial while enabled requests notification permission and schedules a local reminder for one day before trial expiration.
- The switch exposes a semantic accessibility label, value, and hint.
- Xcode Debug build succeeded for the iPhone 16 Pro Simulator.

## Findings

No actionable P0, P1, or P2 issues remain.

## Comparison history

- Iteration 1: `/private/tmp/catfocus-paywall-trial-reminder.png` implemented the reminder and preserved the CTA position, but the taller fixed conversion area obscured the bottom edge of the Lifetime Access card (P2).
- Fix: tightened only non-critical upper-screen vertical spacing, reduced the hero canvas from 172pt to 144pt with proportional scaling, and reduced benefit-list spacing.
- Post-fix evidence: `/private/tmp/catfocus-paywall-trial-reminder-final.png` shows both plan cards fully visible, the reminder and cancellation copy separated cleanly, and the CTA/legal area retained at the bottom.

## Follow-up polish

- P3: validate the notification copy and exact scheduling date against the production subscription provider once StoreKit replaces the current local entitlement flow.

final result: passed
