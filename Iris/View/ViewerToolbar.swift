import SwiftUI
import AppKit

struct ViewerToolbar: View {
    @ObservedObject var state: AppViewModel

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
            Button(action: state.library.openFolder) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if let folder = state.library.folderURL {
                        Text(folder.lastPathComponent)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            tbDivider

            TBButton(systemImage: "chevron.left",  help: "Previous  ←") { state.library.navigate(-1) }
                .disabled(!state.library.hasPhotos)
            TBButton(systemImage: "chevron.right", help: "Next  →")     { state.library.navigate(+1) }
                .disabled(!state.library.hasPhotos)

            if state.library.hasPhotos {
                Text("\(state.library.selectedIndex + 1)  /  \(state.library.photos.count)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: Center — filename

    @ViewBuilder
    private var centerSection: some View {
        if let photo = state.library.selectedPhoto {
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
            TBButton(systemImage: "rotate.left",  help: "Rotate Left  ⌘L") { state.transform.rotation -= .degrees(90) }
                .disabled(!state.library.hasPhotos)
            TBButton(systemImage: "rotate.right", help: "Rotate Right  ⌘R") { state.transform.rotation += .degrees(90) }
                .disabled(!state.library.hasPhotos)

            TBButton(systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                     help: "Flip Horizontal") { state.transform.flipH.toggle() }
                .disabled(!state.library.hasPhotos)
            TBButton(systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                     help: "Flip Vertical") { state.transform.flipV.toggle() }
                .disabled(!state.library.hasPhotos)

            tbDivider

            TBButton(systemImage: "minus.magnifyingglass", help: "Zoom Out  −") { state.transform.nudgeZoom(-0.1) }
                .disabled(!state.library.hasPhotos)

            Text(zoomLabel)
                .font(.system(size: 11.5, design: .monospaced).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40)
                .multilineTextAlignment(.center)

            TBButton(systemImage: "plus.magnifyingglass",  help: "Zoom In  +") { state.transform.nudgeZoom(+0.1) }
                .disabled(!state.library.hasPhotos)

            TBButton(systemImage: "arrow.up.left.and.arrow.down.right",
                     help: "Fit to Window  F",
                     active: state.transform.zoomMode == .fit,
                     action: { state.transform.setFit() })
                .disabled(!state.library.hasPhotos)

            TBButton(systemImage: "1.square",
                     help: "Actual Size  1",
                     active: state.transform.zoomMode == .hundred,
                     action: { state.transform.setHundred() })
                .disabled(!state.library.hasPhotos)

            tbDivider

            TBButton(systemImage: "play.fill", help: "Slideshow") { state.slideshowActive = true }
                .disabled(!state.library.hasPhotos)

            tbDivider

            TBButton(systemImage: "filmstrip",
                     help: "Toggle Filmstrip",
                     active: state.preferences.filmstripOpen,
                     action: { state.preferences.filmstripOpen.toggle() })
                .disabled(!state.library.hasPhotos)

            TBButton(systemImage: "info.circle",
                     help: "Info Panel  I",
                     active: state.infoOpen,
                     action: { state.infoOpen.toggle() })
                .disabled(!state.library.hasPhotos)
        }
    }

    private var zoomLabel: String {
        switch state.transform.zoomMode {
        case .fit:     return "Fit"
        case .hundred: return "1:1"
        case .custom:  return "\(Int((state.transform.zoom * 100).rounded()))%"
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
