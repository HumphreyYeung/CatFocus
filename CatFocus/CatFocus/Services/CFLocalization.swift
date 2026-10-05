import Foundation

/// Lookup for copy passed through String-based models and reusable components.
/// User-entered names and stable persistence/analytics identifiers stay untouched.
enum CFLocalization {
    static let languagePreferenceKey = "appLanguage"

    static let supportedLanguageIdentifiers = ["en", "ja", "ko", "zh-Hant-TW"]

    static var locale: Locale {
        locale(for: UserDefaults.standard.string(forKey: languagePreferenceKey) ?? "system")
    }

    static func locale(for selection: String, systemIdentifier: String? = nil) -> Locale {
        let identifier: String
        if selection == "system" {
            identifier = systemIdentifier ?? Bundle.main.preferredLocalizations.first ?? "en"
        } else if supportedLanguageIdentifiers.contains(selection) {
            identifier = selection
        } else {
            identifier = systemIdentifier ?? Bundle.main.preferredLocalizations.first ?? "en"
        }
        return Locale(identifier: identifier)
    }

    private static var localizationBundle: Bundle {
        localizationBundle(for: locale)
    }

    private static func localizationBundle(for locale: Locale) -> Bundle {
        let identifier = locale.identifier
        guard let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    static func text(_ key: String) -> String {
        text(key, locale: locale)
    }

    static func text(_ key: String, locale: Locale) -> String {
        NSLocalizedString(key, bundle: localizationBundle(for: locale), comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    static func duration(minutes: Int, compact: Bool = false) -> String {
        let minutes = max(0, minutes)
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return format(compact ? "%lldm" : "%lld min", minutes) }
        if remainder == 0 { return format(compact ? "%lldh" : "%lld h", hours) }
        return format(compact ? "%lldh%lldm" : "%lld h %lld min", hours, remainder)
    }
}
