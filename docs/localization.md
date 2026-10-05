# CatFocus localization

CatFocus follows the system-selected app language by default. It ships English (`en`), Japanese (`ja`), Korean (`ko`), and Traditional Chinese for Taiwan (`zh-Hant-TW`). Users can override the system language in Settings; the choice applies immediately and is saved across launches. English is the development language and fallback.

## Copy and voice

`CatFocus/CatFocus/Resources/Localizable.xcstrings` holds the translated interface copy, onboarding dialogue, contextual Luna messages, postcard titles and letters, accessibility text, subscription descriptions, share exports, and default local reminders.

Luna's voice is warm and lightly cheeky: she likes naps and snacks, occasionally grumbles about training, and celebrates the user's effort. Japanese uses friendly, gentle phrasing; Korean separates polite interface guidance from Luna's familiar dialogue; Traditional Chinese uses Taiwan vocabulary. Instructions, prices, and renewal terms remain clear.

`InfoPlist.xcstrings` localizes the permission explanation for saving cards and videos to Photos. Privacy Policy and Terms of Use links in Settings and Paywall open their public Notion pages in the system browser.

## Implementation

- Literal SwiftUI labels use the string catalog directly.
- `CFLocalization.text` looks up copy carried by String-based models and reusable components.
- `CFLocalization.format` preserves formatted arguments and their order. Translate the complete sentence rather than assembling translated fragments; keep all numeric and string placeholders.
- Dates use the app language's locale; duration labels have full and compact forms for cards and charts.
- The Settings language picker stores `system`, `en`, `ja`, `ko`, or `zh-Hant-TW`. The root SwiftUI locale updates with the preference, while string-based model copy and postcard artwork resolve using the same selected locale.
- Stored mode, pose, sound, postcard, and analytics IDs remain stable. Custom mode names and user-entered names are displayed as entered.
- Postcard definitions retain their original English values and expose localized presentation properties, so their identity and delivery rules do not depend on language.

## Artwork

Add the final image resources using [the postcard artwork naming guide](postcard-localization.md). Existing English art is displayed until a localized image is available. The app does not overlay translated text onto images that already contain lettering.

## Notifications

The bundled default local reminder and postcard-arrival copy is translated. A Firebase Remote Config value matching that default copy is translated when scheduled. Arbitrary replacement text and remote push payloads are delivered as supplied; configure translated campaigns for each language in Firebase rather than expecting the device to translate their content.

## Verification

`CFLocalizationTests` verifies that each shipped language includes translated postcard copy and the Photos permission explanation, checks subscription argument substitution and language resolution, and protects stable IDs and custom names. `CFPostcardArtworkLocalizationTests` covers image selection and English fallback. `CFLocalizationUITests` launches each language and checks the main screens, onboarding dialogue, contract, successful-session result, and immediate/persisted manual language switching, retaining screenshots in the test result.

```sh
xcodebuild -project CatFocus/CatFocus.xcodeproj -scheme CatFocus \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:CatFocusTests/CFLocalizationTests \
  -only-testing:CatFocusTests/CFPostcardArtworkLocalizationTests \
  -only-testing:CatFocusUITests/CFLocalizationUITests test
```

For a manual check, change the app language in iOS Settings and relaunch CatFocus. Review the preset sheet, subscription screen, contract, and long letter text after replacing the final postcard artwork.
