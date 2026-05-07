import SwiftUI
import AppKit

struct ViewerToolbar: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            // Three-column layout
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
            // Folder breadcrumb
            Button(action: state.openFolder) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if let folder = state.folderURL {
                        Text(folder.lastPathComponent)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            tbDivider

            // Prev / Next
            TBButton(systemImage: "chevron.left",  help: "Previous  ←") { state.navigate(-1) }
                .disabled(!state.hasPhotos)
            TBButton(systemImage: "chevron.right", help: "Next  →")     { state.navigate(+1) }
                .disabled(!state.hasPhotos)

            if state.hasPhotos {
                Text("\(state.selectedIndex + 1)  /  \(state.photos.count)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: Center — filename

    @ViewBuilder
    private var centerSection: some View {
        if let photo = state.selectedPhoto {
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
            // Rotate
            TBButton(systemImage: "rotate.left",  help: "Rotate Left  ⌘L") { state.rotation -= .degrees(90) }
                .disabled(!state.hasPhotos)
            TBButton(systemImage: "rotate.right", help: "Rotate Right  ⌘R") { state.rotation += .degrees(90) }
                .disabled(!state.hasPhotos)

            // Flip
            TBButton(systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                     help: "Flip Horizontal") { state.flipH.toggle() }
                .disabled(!state.hasPhotos)
            TBButton(systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                     help: "Flip Vertical") { state.flipV.toggle() }
                .disabled(!state.hasPhotos)

            tbDivider

            // Zoom controls
            TBButton(systemImage: "minus.magnifyingglass", help: "Zoom Out  −") { state.nudgeZoom(-0.1) }
                .disabled(!state.hasPhotos)

            Text(zoomLabel)
                .font(.system(size: 11.5, design: .monospaced).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40)
                .multilineTextAlignment(.center)

            TBButton(systemImage: "plus.magnifyingglass",  help: "Zoom In  +") { state.nudgeZoom(+0.1) }
                .disabled(!state.hasPhotos)

            TBButton(systemImage: "arrow.up.left.and.arrow.down.right",
                     help: "Fit to Window  F",
                     active: state.zoomMode == .fit,
                     action: { state.setFit() })
                .disabled(!state.hasPhotos)

            TBButton(systemImage: "1.square",
                     help: "Actual Size  1",
                     active: state.zoomMode == .hundred,
                     action: { state.setHundred() })
                .disabled(!state.hasPhotos)

            tbDivider

            // Slideshow + Info
            TBButton(systemImage: "play.fill", help: "Slideshow") { state.slideshowActive = true }
                .disabled(!state.hasPhotos)

            tbDivider

            TBButton(systemImage: "filmstrip",
                     help: "Toggle Filmstrip",
                     active: state.filmstripOpen,
                     action: { state.filmstripOpen.toggle() })
                .disabled(!state.hasPhotos)

            TBButton(systemImage: "info.circle",
                     help: "Info Panel  I",
                     active: state.infoOpen,
                     action: { state.infoOpen.toggle() })
                .disabled(!state.hasPhotos)
        }
    }

    private var zoomLabel: String {
        switch state.zoomMode {
        case .fit:     return "Fit"
        case .hundred: return "1:1"
        case .custom:  return "\(Int((state.zoom * 100).rounded()))%"
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
