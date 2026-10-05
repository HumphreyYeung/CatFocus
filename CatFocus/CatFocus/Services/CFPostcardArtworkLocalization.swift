import SwiftUI
import UIKit

enum CFPostcardArtworkLocalization {
    static func variantName(baseName: String, localizationIdentifier: String) -> String? {
        let identifier = localizationIdentifier.replacingOccurrences(of: "_", with: "-")
        let suffix: String

        if identifier.hasPrefix("ja") {
            suffix = "ja"
        } else if identifier.hasPrefix("ko") {
            suffix = "ko"
        } else if identifier.hasPrefix("zh-Hant") || identifier == "zh-TW" {
            suffix = "zh-Hant-TW"
        } else {
            return nil
        }

        return "\(baseName)_\(suffix)"
    }

    static func resolvedName(
        baseName: String,
        localizationIdentifier: String,
        hasAsset: (String) -> Bool
    ) -> String {
        guard let variant = variantName(
            baseName: baseName,
            localizationIdentifier: localizationIdentifier
        ), hasAsset(variant) else {
            return baseName
        }

        return variant
    }

    static var currentLocalizationIdentifier: String {
        CFLocalization.locale.identifier
    }
}

enum CFPostcardArtwork {
    static func image(baseName: String) -> Image {
        let imageName = CFPostcardArtworkLocalization.resolvedName(
            baseName: baseName,
            localizationIdentifier: CFPostcardArtworkLocalization.currentLocalizationIdentifier,
            hasAsset: { UIImage(named: $0) != nil }
        )

        return Image(imageName)
    }
}
