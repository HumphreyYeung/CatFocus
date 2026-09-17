# Paywall Design QA

## Scope

- Reference: `/Users/humphreyyeung/Downloads/Frame 88 (3).png`
- Runtime: iPhone 16 Plus Simulator, iOS 18.6
- Screens checked: standard Focus/Pose Paywall and Collection postcard Paywall
- The reference hero artwork was intentionally excluded; each CatFocus Paywall keeps its existing source-specific hero.

## Comparison

- Product lockup, headline, supporting copy, benefits, trial status, renewal timeline, CTA, restore control, and legal links follow the reference hierarchy.
- The renewal date is calculated from the Paywall presentation date plus seven local calendar days.
- The only purchasable plan shown and processed is weekly at the current mock price of `$4.99/week`.
- Long postcard copy fits without clipping on the tested viewport.
- Both variants use the same calculated media height and crop boundary.
- Both variants reserve identical 120-point title and 148-point benefit regions, keeping the trial block and CTA on the same vertical baseline.
- Both main headlines remain on one line, with controlled text scaling on narrower devices.
- Timeline labels are vertically centered against their corresponding bullet points.
- Paywalls use a fixed, non-scrollable canvas; the Collection hero fades into the white content area with a restrained lower gradient.
- Benefit checks use the orange accent with a low-opacity orange circular field; the trial status is text-only.
- The Paywall CTA includes a short, transform-only sweep highlight and disables it when Reduce Motion is enabled.
- Both Terms of Use and Privacy Policy open the existing legal document sheet.
- The page remains vertically scrollable for smaller screens and larger accessibility text sizes.

## Findings

- P0: none
- P1: none
- P2: none
- P3: production pricing is still a local mock value and should be sourced from StoreKit when the real SKU is connected.

final result: passed
