import SwiftUI

struct MetaBarView: View {
    @ObservedObject var state: AppViewModel

    var body: some View {
        HStack(spacing: 28) {
            if let photo = state.library.selectedPhoto {
                metaCell(label: "File", value: photo.name, mono: true)
                if photo.width > 0 {
                    metaCell(label: "Resolution", value: "\(photo.width) × \(photo.height)", mono: true)
                }
                if !photo.size.isEmpty {
                    metaCell(label: "Size", value: photo.size, mono: true)
                }
                if !photo.date.isEmpty {
                    metaCell(label: "Captured", value: photo.date, mono: false)
                }
            }

            Spacer(minLength: 0)

            if state.library.hasPhotos {
                HStack(spacing: 12) {
                    if let photo = state.library.selectedPhoto {
                        starRating(photo.rating)
                        Color.primary.opacity(0.18)
                            .frame(width: 1, height: 16)
                    }
                    Text("\(state.library.selectedIndex + 1) of \(state.library.photos.count)")
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 46)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    private func metaCell(label: String, value: String, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(mono
                    ? .system(size: 12, design: .monospaced)
                    : .system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func starRating(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1 ... 5, id: \.self) { n in
                Image(systemName: n <= rating ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundStyle(n <= rating ? Color.yellow : Color.primary.opacity(0.25))
            }
        }
    }
}
