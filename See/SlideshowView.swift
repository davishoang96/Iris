import SwiftUI
import AppKit

struct SlideshowView: View {
    let photo: PhotoMeta
    let onClose: () -> Void

    @State private var nsImage: NSImage?

    var body: some View {
        ZStack {
            Color.black

            if let img = nsImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(32)
                    .shadow(color: .black.opacity(0.8), radius: 60, x: 0, y: 30)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color(white: 0.6))
            }

            VStack {
                Spacer()
                Text("click anywhere  ·  esc to exit")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
        .onTapGesture { onClose() }
        .onKeyPress(.escape) { onClose(); return .handled }
        .focusable()
        .task(id: photo.id) {
            nsImage = await Task.detached { loadDisplayImage(url: photo.path) }.value
        }
    }
}
