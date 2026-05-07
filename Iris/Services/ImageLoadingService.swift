import Foundation
import CoreImage
import AppKit
import ImageIO

enum ImageLoadingService {

    // MARK: - Display image

    nonisolated static func loadDisplayImage(url: URL) -> NSImage? {
        let rawExtensions: Set<String> = ["raf", "dng", "nef", "cr2", "cr3", "arw"]
        let ext = url.pathExtension.lowercased()

        guard rawExtensions.contains(ext) else {
            return NSImage(contentsOf: url)
        }

        let cacheURL = previewCacheURL(for: url)
        if FileManager.default.fileExists(atPath: cacheURL.path),
           let cached = NSImage(contentsOf: cacheURL) {
            return cached
        }

        if let jpeg = extractEmbeddedJPEG(url: url) {
            try? jpeg.write(to: cacheURL)
            return NSImage(data: jpeg)
        }

        if let img = decodeCIRAW(url: url) {
            writeImageCache(img, to: cacheURL)
            return img
        }

        return nil
    }

    // MARK: - Thumbnail

    nonisolated static func loadThumbnail(url: URL) async -> NSImage? {
        await Task.detached {
            let opts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 200,
            ]
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
            else { return nil as NSImage? }
            return NSImage(cgImage: cgImg,
                           size: NSSize(width: cgImg.width, height: cgImg.height))
        }.value
    }

    // MARK: - Cache

    nonisolated private static func previewCacheURL(for url: URL) -> URL {
        var hasher = Hasher()
        url.path.hash(into: &hasher)
        let hash = UInt64(bitPattern: Int64(hasher.finalize()))
        let name = String(format: "see_%016llx.jpg", hash)
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }

    nonisolated private static func writeImageCache(_ img: NSImage, to url: URL) {
        guard let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpeg = rep.representation(using: .jpeg,
                                            properties: [.compressionFactor: 0.88])
        else { return }
        try? jpeg.write(to: url)
    }

    // MARK: - Embedded JPEG extraction

    nonisolated private static func extractEmbeddedJPEG(url: URL) -> Data? {
        url.pathExtension.lowercased() == "raf"
            ? extractRAFJPEG(url: url)
            : extractTIFFJPEG(url: url)
    }

    nonisolated private static func extractRAFJPEG(url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= 92 else { return nil }

        let magic = Array("FUJIFILMCCD-RAW ".utf8)
        guard Array(data.prefix(16)) == magic else { return nil }

        let jpegOffset = data[84..<88].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        let jpegLen    = data[88..<92].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        let off = Int(jpegOffset), len = Int(jpegLen)
        guard len > 0, off + len <= data.count else { return nil }

        let jpeg = data[off..<(off + len)]
        guard jpeg.prefix(2).elementsEqual([0xFF, 0xD8]) else { return nil }
        return Data(jpeg)
    }

    nonisolated private static func extractTIFFJPEG(url: URL) -> Data? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let opts: [CFString: Any] = [kCGImageSourceThumbnailMaxPixelSize: 9000]
        guard let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary),
              max(cgImg.width, cgImg.height) >= 1500 else { return nil }

        return cgImageToJPEGData(cgImg)
    }

    nonisolated private static func cgImageToJPEGData(_ cgImg: CGImage) -> Data? {
        let dest = NSMutableData()
        guard let d = CGImageDestinationCreateWithData(dest, "public.jpeg" as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(d, cgImg,
                                   [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
        return CGImageDestinationFinalize(d) ? (dest as Data) : nil
    }

    // MARK: - CIRAWFilter fallback

    nonisolated private static func decodeCIRAW(url: URL) -> NSImage? {
        guard let rawFilter = CIRAWFilter(imageURL: url) else { return nil }
        guard let output = rawFilter.previewImage ?? rawFilter.outputImage else { return nil }

        let ctx = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImg = ctx.createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
    }
}
