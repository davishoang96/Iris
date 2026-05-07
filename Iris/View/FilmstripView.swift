import SwiftUI
import AppKit

struct FilmstripView: View {
    @ObservedObject var library: LibraryViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(library.photos.indices, id: \.self) { i in
                        ThumbnailCell(photo: library.photos[i], index: i, isSelected: i == library.selectedIndex)
                            .id(i)
                            .onTapGesture { library.selectedIndex = i }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
            .onChange(of: library.selectedIndex) { _, idx in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(idx, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(library.selectedIndex, anchor: .center)
            }
        }
        .frame(height: 88)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Thumbnail cell

private struct ThumbnailCell: View {
    let photo: PhotoMeta
    let index: Int
    let isSelected: Bool

    @State private var thumb: NSImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let thumb {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(white: 0.2)
                        .overlay { ProgressView().controlSize(.mini) }
                }
            }
            .frame(width: 64, height: 64)
            .opacity(isSelected ? 1.0 : 0.85)

            Text(String(format: "%02d", index + 1))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .opacity(isSelected ? 1.0 : 0.7)
                .padding(.leading, 4)
                .padding(.bottom, 3)
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isSelected ? Color.primary : Color.primary.opacity(0.18),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .offset(y: isSelected ? -2 : 0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .task(id: photo.id) {
            thumb = await ImageLoadingService.loadThumbnail(url: photo.path)
        }
    }
}
