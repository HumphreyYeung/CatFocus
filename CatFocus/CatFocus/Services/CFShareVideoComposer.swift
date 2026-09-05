import AVFoundation
import SwiftUI
import UIKit
import Photos

enum CFShareVideoComposer {
    private static let outputWidth = 720
    private static let outputHeight = 1280

    static func compose(
        source: CFCatAsset,
        userName: String,
        poseTitle: String,
        focusModeTitle: String = "Focus",
        focusMinutes: Int,
        points: Int,
        duration: TimeInterval = 6
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("catfocus-share-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: outputHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2_500_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: outputHeight
            ]
        )

        guard writer.canAdd(input) else { throw CFShareVideoError.unableToCreateWriter }
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frameRate: Int32 = 30
        let frameCount = Int(duration * Double(frameRate))

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "com.catfocus.share-video", qos: .userInitiated).async {
                let videoReader = videoReader(for: source)
                let fallbackImage = fallbackImage(for: source) ?? UIImage(named: "luna-success")

                for frameIndex in 0..<frameCount {
                    while !input.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.002)
                    }

                    let progress = Double(frameIndex) / Double(max(1, frameCount - 1))
                    let sourceFrame = videoReader?.nextFrame()
                        ?? fallbackImage?.cgImage
                    guard let pixelBuffer = makePixelBuffer(
                        sourceFrame: sourceFrame,
                        sourceFrameIsVideo: videoReader != nil,
                        userName: userName,
                        poseTitle: poseTitle,
                        focusModeTitle: focusModeTitle,
                        focusMinutes: focusMinutes,
                        points: points,
                        progress: progress
                    ) else {
                        input.markAsFinished()
                        writer.cancelWriting()
                        continuation.resume(throwing: CFShareVideoError.unableToCreateFrame)
                        return
                    }

                    let time = CMTime(value: CMTimeValue(frameIndex), timescale: frameRate)
                    adaptor.append(pixelBuffer, withPresentationTime: time)
                }

                input.markAsFinished()
                writer.finishWriting {
                    if writer.status == .completed {
                        continuation.resume(returning: outputURL)
                    } else {
                        continuation.resume(throwing: writer.error ?? CFShareVideoError.exportFailed)
                    }
                }
            }
        }
    }

    private static func videoReader(for source: CFCatAsset) -> CFVideoFrameReader? {
        guard case .video(let name, _) = source,
              let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
            return nil
        }

        return try? CFVideoFrameReader(url: url)
    }

    private static func fallbackImage(for source: CFCatAsset) -> UIImage? {
        switch source {
        case .staticImage(let name), .animated(let name):
            UIImage(named: name)
        case .video(_, let poster):
            UIImage(named: poster)
        }
    }

    static func saveToPhotos(url: URL) async throws {
        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorization == .authorized || authorization == .limited else {
            throw CFShareVideoError.photoPermissionDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? CFShareVideoError.photoSaveFailed)
                }
            }
        }
    }

    static func saveToPhotos(image: UIImage) async throws {
        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorization == .authorized || authorization == .limited else {
            throw CFShareVideoError.photoPermissionDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? CFShareVideoError.photoSaveFailed)
                }
            }
        }
    }

    #if DEBUG
    static func retainDebugCopy(_ url: URL) throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("catfocus-share-latest.mp4")
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
    }
    #endif

    private static func makePixelBuffer(
        sourceFrame: CGImage?,
        sourceFrameIsVideo: Bool,
        userName: String,
        poseTitle: String,
        focusModeTitle: String,
        focusMinutes: Int,
        points: Int,
        progress: Double
    ) -> CVPixelBuffer? {
        let size = CGSize(width: outputWidth, height: outputHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            if let sourceFrame {
                let sourceSize = CGSize(width: sourceFrame.width, height: sourceFrame.height)
                // Reserve a clean white information band below the mascot frame.
                let videoBounds = CGRect(x: 0, y: 64, width: 720, height: 720)
                let scale = min(videoBounds.width / sourceSize.width, videoBounds.height / sourceSize.height)
                let drawSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
                let drawRect = CGRect(
                    x: videoBounds.midX - drawSize.width / 2,
                    y: videoBounds.midY - drawSize.height / 2,
                    width: drawSize.width,
                    height: drawSize.height
                )
                context.cgContext.saveGState()
                if sourceFrameIsVideo {
                    context.cgContext.translateBy(x: 0, y: drawRect.minY + drawRect.height)
                    context.cgContext.scaleBy(x: 1, y: -1)
                }
                let sourceDrawRect = sourceFrameIsVideo
                    ? CGRect(x: drawRect.minX, y: 0, width: drawRect.width, height: drawRect.height)
                    : drawRect
                context.cgContext.draw(sourceFrame, in: sourceDrawRect)
                context.cgContext.restoreGState()
            }

            let gradientColors = [
                UIColor.white.withAlphaComponent(0).cgColor,
                UIColor.white.withAlphaComponent(0.92).cgColor,
                UIColor.white.withAlphaComponent(0.98).cgColor
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors,
                locations: [0, 0.45, 1]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 760),
                    end: CGPoint(x: 0, y: 1080),
                    options: []
                )
            }

            let pointsText = points > 0 ? "+\(points)" : "\(points)"
            drawCentered(
                shareHeadline(for: focusModeTitle, minutes: focusMinutes),
                in: CGRect(x: 36, y: 900, width: 648, height: 34),
                font: UIFont.systemFont(ofSize: 24, weight: .black),
                color: UIColor.black.withAlphaComponent(0.94)
            )
            drawCentered(
                "\(displayName(userName)) × LUNA",
                in: CGRect(x: 36, y: 950, width: 648, height: 24),
                font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                color: UIColor.black.withAlphaComponent(0.78)
            )
            drawCentered(
                "\(poseTitle.uppercased())  ·  \(focusMinutes) MIN FOCUS  ·  \(pointsText) FIT POINTS",
                in: CGRect(x: 36, y: 990, width: 648, height: 20),
                font: UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
                color: UIColor.black.withAlphaComponent(0.56)
            )
            drawCentered(
                "CATFOCUS",
                in: CGRect(x: 36, y: 1080, width: 648, height: 16),
                font: UIFont.systemFont(ofSize: 10, weight: .bold),
                color: UIColor.black.withAlphaComponent(0.40)
            )

            _ = progress
        }

        guard let cgImage = image.cgImage else { return nil }
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            outputWidth,
            outputHeight,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        guard let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let bitmapContext = CGContext(
            data: baseAddress,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        bitmapContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))
        return pixelBuffer
    }

    private static func displayName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Human Friend" : String(trimmed.prefix(24))
    }

    private static func shareHeadline(for mode: String, minutes: Int) -> String {
        let normalizedMode = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let verb: String
        switch normalizedMode {
        case "work": verb = "WORKED"
        case "study": verb = "STUDIED"
        case "read": verb = "READ"
        case "meditation": verb = "MEDITATED"
        case "exercise": verb = "TRAINED"
        default: verb = "FOCUSED"
        }
        return "\(verb) WITH LUNA FOR \(minutes) MIN"
    }

    private static func drawCentered(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        NSString(string: text).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }
}

private final class CFVideoFrameReader {
    private let url: URL
    private let context = CIContext()
    private var reader: AVAssetReader
    private var output: AVAssetReaderTrackOutput

    init(url: URL) throws {
        self.url = url
        let setup = try Self.makeReader(url: url)
        reader = setup.reader
        output = setup.output
    }

    func nextFrame() -> CGImage? {
        if let sample = output.copyNextSampleBuffer(),
           let buffer = CMSampleBufferGetImageBuffer(sample) {
            let ciImage = CIImage(cvPixelBuffer: buffer)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }

        guard let setup = try? Self.makeReader(url: url) else { return nil }
        reader = setup.reader
        output = setup.output
        guard let sample = output.copyNextSampleBuffer(),
              let buffer = CMSampleBufferGetImageBuffer(sample) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }

    private static func makeReader(url: URL) throws -> (reader: AVAssetReader, output: AVAssetReaderTrackOutput) {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw CFShareVideoError.exportFailed
        }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        guard reader.canAdd(output) else { throw CFShareVideoError.exportFailed }
        reader.add(output)
        reader.startReading()
        return (reader, output)
    }
}

enum CFShareVideoError: LocalizedError {
    case unableToCreateWriter
    case unableToCreateFrame
    case exportFailed
    case photoPermissionDenied
    case photoSaveFailed

    var errorDescription: String? {
        switch self {
        case .photoPermissionDenied:
            "Photo access is required to save this video. You can allow it in Settings."
        case .photoSaveFailed:
            "The video could not be saved to Photos."
        default:
            "Unable to create a share video."
        }
    }
}

struct CFVideoShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
