import Foundation
import CoreImage
import AppKit
import ImageIO

private let rawExtensions: Set<String> = ["raf", "dng", "nef", "cr2", "cr3", "arw"]

// MARK: - Public entry point

nonisolated func loadDisplayImage(url: URL) -> NSImage? {
    let ext = url.pathExtension.lowercased()

    guard rawExtensions.contains(ext) else {
        return NSImage(contentsOf: url)
    }

    // Fast path: cached JPEG on disk
    let cacheURL = previewCacheURL(for: url)
    if FileManager.default.fileExists(atPath: cacheURL.path),
       let cached = NSImage(contentsOf: cacheURL) {
        return cached
    }

    // Embedded JPEG (fast — no full RAW decode)
    if let jpeg = extractEmbeddedJPEG(url: url) {
        try? jpeg.write(to: cacheURL)
        return NSImage(data: jpeg)
    }

    // Fallback: CIRAWFilter full decode (slow)
    if let img = decodeCIRAW(url: url) {
        writeImageCache(img, to: cacheURL)
        return img
    }

    return nil
}

// MARK: - Cache

nonisolated private func previewCacheURL(for url: URL) -> URL {
    var hasher = Hasher()
    url.path.hash(into: &hasher)
    let hash = UInt64(bitPattern: Int64(hasher.finalize()))
    let name = String(format: "see_%016llx.jpg", hash)
    return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
}

nonisolated private func writeImageCache(_ img: NSImage, to url: URL) {
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let jpeg = rep.representation(using: .jpeg,
                                        properties: [.compressionFactor: 0.88])
    else { return }
    try? jpeg.write(to: url)
}

// MARK: - Embedded JPEG extraction

nonisolated private func extractEmbeddedJPEG(url: URL) -> Data? {
    let ext = url.pathExtension.lowercased()
    return ext == "raf" ? extractRAFJPEG(url: url) : extractTIFFJPEG(url: url)
}

/// Fujifilm RAF: "FUJIFILMCCD-RAW " magic, jpeg_offset @ 84, jpeg_len @ 88 (big-endian)
nonisolated private func extractRAFJPEG(url: URL) -> Data? {
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

/// TIFF-based RAW (DNG, NEF, CR2, CR3, ARW):
/// Use CGImageSource thumbnail — macOS RAW plugin exposes the embedded JPEG preview.
/// Require ≥ 1500 px on the long edge so we don't get tiny icon thumbnails.
nonisolated private func extractTIFFJPEG(url: URL) -> Data? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

    let opts: [CFString: Any] = [kCGImageSourceThumbnailMaxPixelSize: 9000]
    guard let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary),
          max(cgImg.width, cgImg.height) >= 1500 else { return nil }

    return cgImageToJPEGData(cgImg)
}

nonisolated private func cgImageToJPEGData(_ cgImg: CGImage) -> Data? {
    let dest = NSMutableData()
    guard let d = CGImageDestinationCreateWithData(dest, "public.jpeg" as CFString, 1, nil)
    else { return nil }
    CGImageDestinationAddImage(d, cgImg,
                               [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
    return CGImageDestinationFinalize(d) ? (dest as Data) : nil
}

// MARK: - CIRAWFilter fallback

nonisolated private func decodeCIRAW(url: URL) -> NSImage? {
    guard let rawFilter = CIRAWFilter(imageURL: url) else { return nil }
    // previewImage is faster; fall back to full outputImage
    guard let output = rawFilter.previewImage ?? rawFilter.outputImage else { return nil }

    let ctx = CIContext(options: [.useSoftwareRenderer: false])
    guard let cgImg = ctx.createCGImage(output, from: output.extent) else { return nil }
    return NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
}
