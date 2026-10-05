import Foundation
import Testing
@testable import CatFocus

struct CFLocalizationTests {
    @Test func shippedBundlesIncludeTranslatedDynamicCopyAndPermissionPrompt() throws {
        for language in ["ja", "ko", "zh-Hant-TW"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            for postcard in [PostcardCatalog.welcome] + PostcardCatalog.all {
                for key in [postcard.title, postcard.dateLine, postcard.letter, postcard.accessibilityDescription] {
                    #expect(bundle.localizedString(forKey: key, value: nil, table: "Localizable") != key)
                }
            }
            let permission = bundle.localizedString(forKey: "NSPhotoLibraryAddUsageDescription", value: nil, table: "InfoPlist")
            #expect(permission != "NSPhotoLibraryAddUsageDescription")
            #expect(!permission.isEmpty)
        }
    }

    @Test func translatedFormatsPreserveArgumentOrderAndValues() throws {
        for language in ["en", "ja", "ko", "zh-Hant-TW"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            let key = "Free today. Seven days free. Renews %@ at %@ per week."
            let format = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            let value = String(format: format, arguments: ["DATE", "PRICE"])
            #expect(value.contains("DATE"))
            #expect(value.contains("PRICE"))
            #expect(!value.contains("%@"))
        }
    }

    @Test func customModeNamesAndStableIdentifiersAreNotTranslated() {
        #expect(PresetFocusMode.custom.displayTitle(customName: "My own mode") == "My own mode")
        #expect(TrainingPose.jumpRope.id == "jumpRope")
        #expect(PresetSound.purring.id == "purring")
        #expect(PostcardCatalog.welcome.id == "welcome-letter")
    }

    @Test func languagePreferenceUsesSystemByDefaultAndSupportsShippedLocales() {
        #expect(CFLocalization.locale(for: "system", systemIdentifier: "ja").identifier == "ja")
        #expect(CFLocalization.locale(for: "zh-Hant-TW", systemIdentifier: "en").identifier == "zh-Hant-TW")
        #expect(CFLocalization.locale(for: "unsupported", systemIdentifier: "ko").identifier == "ko")
    }
}
