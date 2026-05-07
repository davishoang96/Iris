import SwiftUI
import AppKit

struct ViewerToolbar: View {
    @ObservedObject var library: LibraryViewModel
    @ObservedObject var transform: TransformViewModel
    @ObservedObject var preferences: PreferencesViewModel
    @Binding var infoOpen: Bool
    @Binding var slideshowActive: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                leftSection
                Spacer(minLength: 12)
                centerSection
                Spacer(minLength: 12)
                rightSection
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: Left — folder + nav + counter

    private var leftSection: some View {
        HStack(spacing: 0) {
            Button(action: library.openFolder) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if let folder = library.folderURL {
                        Text(folder.lastPathComponent)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            tbDivider

            TBButton(systemImage: "chevron.left",  help: "Previous  ←") { library.navigate(-1) }
                .disabled(!library.hasPhotos)
            TBButton(systemImage: "chevron.right", help: "Next  →")     { library.navigate(+1) }
                .disabled(!library.hasPhotos)

            if library.hasPhotos {
                Text("\(library.selectedIndex + 1)  /  \(library.photos.count)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: Center — filename

    @ViewBuilder
    private var centerSection: some View {
        if let photo = library.selectedPhoto {
            VStack(spacing: 1) {
                Text(photo.nameWithoutExtension)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.1)
                    .lineLimit(1)
                Text(photo.name)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: Right — transforms + zoom + actions

    private var rightSection: some View {
        HStack(spacing: 0) {
            TBButton(systemImage: "rotate.left",  help: "Rotate Left  ⌘L")  { transform.rotation -= .degrees(90) }
                .disabled(!library.hasPhotos)
            TBButton(systemImage: "rotate.right", help: "Rotate Right  ⌘R") { transform.rotation += .degrees(90) }
                .disabled(!library.hasPhotos)

            TBButton(systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                     help: "Flip Horizontal") { transform.flipH.toggle() }
                .disabled(!library.hasPhotos)
            TBButton(systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                     help: "Flip Vertical") { transform.flipV.toggle() }
                .disabled(!library.hasPhotos)

            tbDivider

            TBButton(systemImage: "minus.magnifyingglass", help: "Zoom Out  −") { transform.nudgeZoom(-0.1) }
                .disabled(!library.hasPhotos)

            Text(zoomLabel)
                .font(.system(size: 11.5, design: .monospaced).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40)
                .multilineTextAlignment(.center)

            TBButton(systemImage: "plus.magnifyingglass", help: "Zoom In  +") { transform.nudgeZoom(+0.1) }
                .disabled(!library.hasPhotos)

            TBButton(systemImage: "arrow.up.left.and.arrow.down.right",
                     help: "Fit to Window  F",
                     active: transform.zoomMode == .fit,
                     action: { transform.setFit() })
                .disabled(!library.hasPhotos)

            TBButton(systemImage: "1.square",
                     help: "Actual Size  1",
                     active: transform.zoomMode == .hundred,
                     action: { transform.setHundred() })
                .disabled(!library.hasPhotos)

            tbDivider

            TBButton(systemImage: "play.fill", help: "Slideshow") { slideshowActive = true }
                .disabled(!library.hasPhotos)

            tbDivider

            TBButton(systemImage: "filmstrip",
                     help: "Toggle Filmstrip",
                     active: preferences.filmstripOpen,
                     action: { preferences.filmstripOpen.toggle() })
                .disabled(!library.hasPhotos)

            TBButton(systemImage: "info.circle",
                     help: "Info Panel  I",
                     active: infoOpen,
                     action: { infoOpen.toggle() })
                .disabled(!library.hasPhotos)
        }
    }

    private var zoomLabel: String {
        switch transform.zoomMode {
        case .fit:     return "Fit"
        case .hundred: return "1:1"
        case .custom:  return "\(Int((transform.zoom * 100).rounded()))%"
        }
    }

    private var tbDivider: some View {
        Color.primary.opacity(0.12)
            .frame(width: 1, height: 18)
            .padding(.horizontal, 8)
    }
}

// MARK: - Toolbar button

struct TBButton: View {
    let systemImage: String
    let help: String
    var active: Bool = false
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(active
                            ? Color.primary.opacity(0.12)
                            : (hovered ? Color.primary.opacity(0.07) : Color.clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
    }
}

// MARK: - PhotoMeta helpers

extension PhotoMeta {
    var nameWithoutExtension: String {
        URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
    }
}
