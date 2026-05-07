import Foundation
import AppKit
import ImageIO

enum PhotoLibraryService {

    // MARK: - Panel (main-actor, must run on main thread)

    static func presentFolderPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder of photos"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    // MARK: - Scanning (nonisolated — runs off main thread)

    nonisolated static func scan(folder: URL) -> [PhotoMeta] {
        let supportedExtensions: Set<String> = [
            "jpg", "jpeg", "png", "heic", "heif", "webp",
            "raf", "dng", "nef", "cr2", "cr3", "arw",
            "tiff", "tif",
        ]

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return entries
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { buildMeta(url: $0) }
    }

    nonisolated static func buildMeta(url: URL) -> PhotoMeta? {
        let supportedExtensions: Set<String> = [
            "jpg", "jpeg", "png", "heic", "heif", "webp",
            "raf", "dng", "nef", "cr2", "cr3", "arw",
            "tiff", "tif",
        ]

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int else { return nil }

        let ext = url.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else { return nil }

        let size = formatSize(fileSize)
        let name = url.lastPathComponent

        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return PhotoMeta(path: url, name: name, size: size, width: 0, height: 0,
                             date: "", camera: "", lens: "", focal: "", aperture: "",
                             shutter: "", iso: 0, gps: "", profile: "", rating: 0)
        }

        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] ?? [:]
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        let gpsDict = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] ?? [:]

        let width  = props[kCGImagePropertyPixelWidth]  as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0

        let make  = tiff[kCGImagePropertyTIFFMake]  as? String ?? ""
        let model = tiff[kCGImagePropertyTIFFModel] as? String ?? ""
        let camera: String
        switch (make.isEmpty, model.isEmpty) {
        case (true, _):  camera = model
        case (_, true):  camera = make
        default:         camera = model.hasPrefix(make) ? model : "\(make) \(model)"
        }

        let lens = exif[kCGImagePropertyExifLensModel] as? String ?? ""

        let focal: String
        if let fl = exif[kCGImagePropertyExifFocalLength] as? Double {
            focal = fl.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(fl))mm" : String(format: "%.1fmm", fl)
        } else { focal = "" }

        let aperture: String
        if let fn = exif[kCGImagePropertyExifFNumber] as? Double {
            aperture = String(format: "f/%.1f", fn)
        } else { aperture = "" }

        let shutter: String
        if let et = exif[kCGImagePropertyExifExposureTime] as? Double, et > 0 {
            if et >= 1 {
                shutter = "\(Int(et))s"
            } else {
                let denom = Int((1.0 / et).rounded())
                shutter = "1/\(denom)s"
            }
        } else { shutter = "" }

        let iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first ?? 0

        let rawDate = exif[kCGImagePropertyExifDateTimeOriginal] as? String ?? ""
        let date = rawDate.isEmpty ? "" : formatExifDate(rawDate)

        let gps: String
        if let lat = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
           let lon = gpsDict[kCGImagePropertyGPSLongitude] as? Double {
            let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String ?? "N"
            let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String ?? "E"
            gps = String(format: "%.4f°%@ %.4f°%@", lat, latRef, lon, lonRef)
        } else { gps = "" }

        return PhotoMeta(path: url, name: name, size: size, width: width, height: height,
                         date: date, camera: camera, lens: lens, focal: focal,
                         aperture: aperture, shutter: shutter, iso: iso,
                         gps: gps, profile: "sRGB", rating: 0)
    }

    // MARK: - Private helpers

    nonisolated private static func formatSize(_ bytes: Int) -> String {
        String(format: "%.1f MB", Double(bytes) / 1_000_000)
    }

    nonisolated private static func formatExifDate(_ s: String) -> String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        let parts = s.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return s }
        let dateParts = parts[0].split(separator: ":")
        let timeParts = parts[1].split(separator: ":")
        guard dateParts.count == 3,
              let month = Int(dateParts[1]),
              let day = Int(dateParts[2]),
              timeParts.count >= 2 else { return s }
        let year = String(dateParts[0])
        let mon = (1...12).contains(month) ? months[month - 1] : ""
        let hhmm = "\(timeParts[0]):\(timeParts[1])"
        return "\(mon) \(day), \(year)  ·  \(hhmm)"
    }
}
