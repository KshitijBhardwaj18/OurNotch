import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoError: Error {
    case unreadable
}

/// Turns any image file into a small square JPEG (~100 KB) that's cheap to encrypt and send.
enum PhotoProcessing {
    static let maxSide = 512

    static func squareJPEG(from url: URL, quality: Double = 0.8) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw PhotoError.unreadable }
        // Decode at a bounded size with the camera's rotation applied, so huge photos stay fast.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSide * 4,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoError.unreadable
        }

        // Square crop: centered sideways; for tall photos, nearer the top, where faces usually are.
        let side = min(image.width, image.height)
        let crop = CGRect(x: (image.width - side) / 2, y: (image.height - side) / 4, width: side, height: side)
        guard let square = image.cropping(to: crop) else { throw PhotoError.unreadable }

        let target = min(side, maxSide)
        guard let context = CGContext(data: nil, width: target, height: target, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw PhotoError.unreadable }
        context.interpolationQuality = .high
        context.draw(square, in: CGRect(x: 0, y: 0, width: target, height: target))
        guard let resized = context.makeImage() else { throw PhotoError.unreadable }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoError.unreadable
        }
        CGImageDestinationAddImage(destination, resized, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.unreadable }
        return data as Data
    }
}

/// This Mac's copies of the two photos (mine and my partner's), kept as plain files per identity.
struct PhotoCache {
    enum Kind: String { case mine, partner }

    static let defaultRoot = URL.applicationSupportDirectory.appending(path: "OurNotch/Photos")

    let directory: URL

    init(ownerId: String, root: URL = defaultRoot) {
        directory = root.appending(path: ownerId)
    }

    func save(_ jpeg: Data, _ kind: Kind) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try jpeg.write(to: url(kind), options: .atomic)
    }

    func load(_ kind: Kind) -> Data? {
        try? Data(contentsOf: url(kind))
    }

    private func url(_ kind: Kind) -> URL { directory.appending(path: "\(kind.rawValue).jpg") }
}
