import Testing
@testable import CatFocus

struct CFPostcardArtworkLocalizationTests {
    @Test func supportedLocalesMapToPostcardAssetSuffixes() {
        #expect(
            CFPostcardArtworkLocalization.variantName(
                baseName: "CollectionPoster01",
                localizationIdentifier: "ja-JP"
            ) == "CollectionPoster01_ja"
        )
        #expect(
            CFPostcardArtworkLocalization.variantName(
                baseName: "CollectionPoster02",
                localizationIdentifier: "ko-KR"
            ) == "CollectionPoster02_ko"
        )
        #expect(
            CFPostcardArtworkLocalization.variantName(
                baseName: "CollectionPoster03",
                localizationIdentifier: "zh-Hant-TW"
            ) == "CollectionPoster03_zh-Hant-TW"
        )
    }

    @Test func englishAndUnsupportedLocalesUseBaseArtwork() {
        #expect(
            CFPostcardArtworkLocalization.variantName(
                baseName: "CollectionPoster01",
                localizationIdentifier: "en"
            ) == nil
        )
        #expect(
            CFPostcardArtworkLocalization.variantName(
                baseName: "CollectionPoster01",
                localizationIdentifier: "zh-Hans-CN"
            ) == nil
        )
    }

    @Test func missingLocalizedArtworkFallsBackToBaseImage() {
        let resolved = CFPostcardArtworkLocalization.resolvedName(
            baseName: "CollectionPoster01",
            localizationIdentifier: "ja",
            hasAsset: { _ in false }
        )

        #expect(resolved == "CollectionPoster01")
    }

    @Test func availableLocalizedArtworkIsSelected() {
        let resolved = CFPostcardArtworkLocalization.resolvedName(
            baseName: "CollectionPoster01",
            localizationIdentifier: "ja",
            hasAsset: { $0 == "CollectionPoster01_ja" }
        )

        #expect(resolved == "CollectionPoster01_ja")
    }
}
