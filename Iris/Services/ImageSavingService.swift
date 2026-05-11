import Foundation
import CoreImage
import AppKit
import ImageIO
import SwiftUI

enum ImageSavingService {

    enum SaveError: LocalizedError {
        case loadFailed, renderFailed, writeFailed

        var errorDescription: String? {
            switch self {
            case .loadFailed:  return "Could not load image data."
            case .renderFailed: return "Could not apply transforms."
            case .writeFailed: return "Could not write file."
            }
        }
    }

    static let rawExtensions: Set<String> = ["raf", "dng", "nef", "cr2", "cr3", "arw"]

    nonisolated static func isWritable(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        // For RAW: writing a new JPEG next to it — check directory
        let checkPath = rawExtensions.contains(ext)
            ? url.deletingLastPathComponent().path
            : url.path
        return FileManager.default.isWritableFile(atPath: checkPath)
    }

    // Saves transformed image in place. For RAW, writes a JPEG alongside (same name, .jpg).
    nonisolated static func save(url: URL, rotation: Angle, flipH: Bool, flipV: Bool) throws {
        guard let source = ImageLoadingService.loadDisplayImage(url: url) else {
            throw SaveError.loadFailed
        }

        guard let transformed = applyTransforms(to: source, rotation: rotation, flipH: flipH, flipV: flipV) else {
            throw SaveError.renderFailed
        }

        let ext = url.pathExtension.lowercased()
        let isRAW = rawExtensions.contains(ext)
        let saveURL = isRAW ? url.deletingPathExtension().appendingPathExtension("jpg") : url
        let uti = utType(for: isRAW ? "jpg" : ext)

        try writeImage(transformed, to: saveURL, uti: uti)
    }

    // Transforms order matches StageView: .scaleEffect (flip) is inner, .rotationEffect is outer.
    // CIImage is y-up so rotation sign is negated vs SwiftUI y-down.
    nonisolated private static func applyTransforms(
        to nsImage: NSImage,
        rotation: Angle,
        flipH: Bool,
        flipV: Bool
    ) -> CGImage? {
        guard let tiff = nsImage.tiffRepresentation,
              let bmp = NSBitmapImageRep(data: tiff),
              let cg = bmp.cgImage else { return nil }

        var ci = CIImage(cgImage: cg)

        // Step 1: flip (inner/first, matches .scaleEffect)
        if flipH {
            let t = CGAffineTransform(scaleX: -1, y: 1)
                .translatedBy(x: -ci.extent.width, y: 0)
            ci = ci.transformed(by: t)
            ci = ci.transformed(by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
        }
        if flipV {
            let t = CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -ci.extent.height)
            ci = ci.transformed(by: t)
            ci = ci.transformed(by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
        }

        // Step 2: rotation (outer/second, matches .rotationEffect)
        // SwiftUI CW-positive (y-down) → CIImage CCW-positive (y-up): negate
        let radians = CGFloat(-rotation.radians)
        if abs(radians.truncatingRemainder(dividingBy: .pi * 2)) > 0.001 {
            let w = ci.extent.width
            let h = ci.extent.height
            let t = CGAffineTransform(translationX: w / 2, y: h / 2)
                .rotated(by: radians)
                .translatedBy(x: -w / 2, y: -h / 2)
            ci = ci.transformed(by: t)
            ci = ci.transformed(by: CGAffineTransform(translationX: -ci.extent.origin.x, y: -ci.extent.origin.y))
        }

        let ctx = CIContext(options: [.useSoftwareRenderer: false])
        return ctx.createCGImage(ci, from: ci.extent)
    }

    nonisolated private static func utType(for ext: String) -> String {
        switch ext {
        case "png":         return "public.png"
        case "tif", "tiff": return "public.tiff"
        case "heic":        return "public.heic"
        default:            return "public.jpeg"
        }
    }

    nonisolated private static func writeImage(_ cgImage: CGImage, to url: URL, uti: String) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti as CFString, 1, nil) else {
            throw SaveError.writeFailed
        }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.95]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw SaveError.writeFailed
        }
    }
}
