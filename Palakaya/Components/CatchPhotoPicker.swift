import SwiftUI
import PhotosUI
import UIKit

/// Lets the fisher take a photo of the catch or pick one from the gallery, and shows it once added.
/// The photo is shrunk to a small JPEG so it does not fill up the phone.
struct CatchPhotoPicker: View {
    @Binding var photo: Data?
    @State private var libraryItem: PhotosPickerItem?
    @State private var showCamera = false

    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        if let photo, let image = UIImage(data: photo) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Photo of your catch")
                Button { self.photo = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                }
                .padding(8)
                .accessibilityLabel("Remove photo")
            }
        } else {
            HStack(spacing: 10) {
                if cameraAvailable {
                    Button { showCamera = true } label: { option("camera.fill", "Take photo") }
                        .buttonStyle(.plain)
                }
                PhotosPicker(selection: $libraryItem, matching: .images) {
                    option("photo.on.rectangle", cameraAvailable ? "From gallery" : "Add a photo")
                }
                .buttonStyle(.plain)
            }
            .onChange(of: libraryItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        photo = Self.compressed(image)
                    }
                    libraryItem = nil
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCapture { image in photo = Self.compressed(image) }
                    .ignoresSafeArea()
            }
        }
    }

    private func option(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(.pkDark)
            Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(.pkText)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundColor(.pkBorder))
        .contentShape(Rectangle())
    }

    /// Longest side at most 1280 px, JPEG quality 0.6 (about 150–300 KB).
    static func compressed(_ image: UIImage) -> Data? {
        let maxSide: CGFloat = 1280
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.6)
    }
}

private struct CameraCapture: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture
        init(_ parent: CameraCapture) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

/// The catch photo at the top of a catch or listing, or a wave placeholder when there is none.
struct CatchPhotoBanner: View {
    var photo: Data?
    var body: some View {
        if let photo, let image = UIImage(data: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("Photo of this catch")
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.pkSurface2).frame(height: 144)
                Image(systemName: "water.waves").font(.system(size: 36)).foregroundColor(.pkAqua)
            }
        }
    }
}

/// Another fisher's catch photo, loaded from the cloud, or the wave placeholder.
struct RemoteCatchPhoto: View {
    var url: String?
    var body: some View {
        if let url, let link = URL(string: url) {
            AsyncImage(url: link) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        Color.pkSurface2
                        if phase.error == nil { ProgressView() }
                        else { Image(systemName: "water.waves").font(.system(size: 36)).foregroundColor(.pkAqua) }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("Photo of this catch")
        } else {
            CatchPhotoBanner(photo: nil)
        }
    }
}
