import SwiftUI

enum CFIcon: Equatable, Sendable {
    case heart
    case gear
    case hourglass
    case play
    case plus
    case focus
    case stats
    case myCat
    case music
    case spark
    case book
    case laptop
    case moon
    case puzzle
    case pose
    case flame
    case rain
    case wave
    case ban
    case share
    case bell
    case speaker
    case download
    case camera
    case message
    case apple
    case arrowDown
    case xmark

    var systemName: String {
        switch self {
        case .heart:
            "heart.fill"
        case .gear:
            "gearshape.fill"
        case .hourglass:
            "hourglass"
        case .play:
            "play.fill"
        case .plus:
            "plus"
        case .focus:
            "flame.fill"
        case .stats:
            "chart.bar.fill"
        case .myCat:
            "pawprint.fill"
        case .music:
            "music.note"
        case .spark:
            "sparkles"
        case .book:
            "book.closed.fill"
        case .laptop:
            "laptopcomputer"
        case .moon:
            "moon.zzz.fill"
        case .puzzle:
            "puzzlepiece.fill"
        case .pose:
            "figure.run"
        case .flame:
            "flame.fill"
        case .rain:
            "cloud.rain.fill"
        case .wave:
            "water.waves"
        case .ban:
            "nosign"
        case .share:
            "arrowshape.turn.up.right.fill"
        case .bell:
            "bell.fill"
        case .speaker:
            "speaker.wave.2.fill"
        case .download:
            "square.and.arrow.down"
        case .camera:
            "camera.fill"
        case .message:
            "message.fill"
        case .apple:
            "apple.logo"
        case .arrowDown:
            "arrow.down"
        case .xmark:
            "xmark"
        }
    }

    var image: Image {
        Image(systemName: systemName)
    }
}
