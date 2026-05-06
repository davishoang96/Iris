import Foundation

struct PhotoMeta: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let name: String
    let size: String
    let width: Int
    let height: Int
    let date: String
    let camera: String
    let lens: String
    let focal: String
    let aperture: String
    let shutter: String
    let iso: Int
    let gps: String
    let profile: String
    let rating: Int
}
