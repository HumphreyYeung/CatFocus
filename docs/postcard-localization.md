# Postcard artwork localization

The app follows the system-selected app localization. English is the base artwork and fallback; localized variants are optional until final artwork is supplied.

For a base asset named `CollectionPoster01`, add localized image sets with these names:

- `CollectionPoster01_ja` — Japanese
- `CollectionPoster01_ko` — Korean
- `CollectionPoster01_zh-Hant-TW` — Traditional Chinese (Taiwan)

Repeat for `CollectionPoster02` through `CollectionPoster12`, and for `luna-onboarding-pact` (the welcome postcard). The collection hero may also use the same convention if its embedded lettering needs localization.

When a localized image set is not present, CatFocus deliberately displays the existing base image, so artwork can be added incrementally without a broken-image state. Replace the placeholder/base artwork with final localized art under the same image-set names; no per-postcard branching changes should then be needed.

UI copy is managed through `Localizable.xcstrings`. Interface labels, Luna's dialogue, postcard titles and letters, default local reminders, and accessibility copy are translated separately from the artwork. See [the localization guide](localization.md) for the copy conventions, dynamic formatting, and validation workflow.
