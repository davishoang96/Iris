import SwiftUI
import AppKit
import ImageIO

struct FilmstripView: View {
    let photos: [PhotoMeta]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(photos.indices, id: \.self) { i in
                        ThumbnailCell(photo: photos[i], isSelected: i == selectedIndex)
                            .id(i)
                            .onTapGesture { selectedIndex = i }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .onChange(of: selectedIndex) { _, idx in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(idx, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
        .frame(height: 88)
        .background(Color(white: 0.11))
    }
}

// MARK: - Thumbnail cell

private struct ThumbnailCell: View {
    let photo: PhotoMeta
    let isSelected: Bool

    @State private var thumb: NSImage?

    var body: some View {
        ZStack {
            if let thumb {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 54)
                    .clipped()
            } else {
                Color(white: 0.2)
                    .frame(width: 72, height: 54)
                    .overlay {
                        ProgressView().controlSize(.mini)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.white.opacity(0.06),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .task(id: photo.id) {
            thumb = await loadThumbnail(url: photo.path)
        }
    }
}

// MARK: - Thumbnail loading

nonisolated private func loadThumbnail(url: URL) async -> NSImage? {
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
