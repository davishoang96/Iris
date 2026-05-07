import SwiftUI

struct InfoPanelView: View {
    let photo: PhotoMeta

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Information")
                    .padding(.bottom, 10)

                Text(photo.nameWithoutExtension)
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(-0.3)
                    .lineLimit(3)
                    .padding(.bottom, 20)

                sectionHeader("Camera")
                    .padding(.bottom, 6)
                if !photo.camera.isEmpty   { infoRow("Camera",  photo.camera,   mono: false) }
                if !photo.lens.isEmpty     { infoRow("Lens",    photo.lens,     mono: false) }
                if !photo.focal.isEmpty    { infoRow("Focal",   photo.focal,    mono: true) }
                if !photo.aperture.isEmpty { infoRow("ƒ",       photo.aperture, mono: true) }
                if !photo.shutter.isEmpty  { infoRow("Shutter", photo.shutter,  mono: true) }
                if photo.iso > 0           { infoRow("ISO",     "\(photo.iso)", mono: true) }

                Spacer().frame(height: 16)

                sectionHeader("File")
                    .padding(.bottom, 6)
                infoRow("Filename", photo.name, mono: true)
                if photo.width > 0 {
                    infoRow("Dimensions", "\(photo.width) × \(photo.height)", mono: true)
                }
                if !photo.size.isEmpty    { infoRow("Size",     photo.size,    mono: true) }
                if !photo.date.isEmpty    { infoRow("Captured", photo.date,    mono: false) }
                if !photo.profile.isEmpty { infoRow("Profile",  photo.profile, mono: false) }

                if !photo.gps.isEmpty {
                    Spacer().frame(height: 16)
                    sectionHeader("Location")
                        .padding(.bottom, 6)
                    infoRow("Coords", photo.gps, mono: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .frame(width: 280)
        .background(.background)
        .overlay(alignment: .leading) { Divider() }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.88)
            .foregroundStyle(.tertiary)
    }

    private func infoRow(_ label: String, _ value: String, mono: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(.tertiary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(mono
                    ? .system(size: 12, design: .monospaced)
                    : .system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) { Divider() }
    }
}
