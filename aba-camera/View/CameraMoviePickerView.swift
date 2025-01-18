// 参考: https://dev.classmethod.jp/articles/swiftui-image-picker-phpicker/

import UniformTypeIdentifiers
import SwiftUI

struct CameraMoviePickerView: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("videoHighQuality") var videoHighQuality: Bool = false
    @Binding var videoUrl: URL?
    @Binding var cancelled: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera

        picker.delegate = context.coordinator
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = videoHighQuality ? .typeHigh : .typeMedium

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        let parent: CameraMoviePickerView

        init(_ parent: CameraMoviePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

            guard let videoUrl = info[.mediaURL] as? URL else {
                return
            }

            parent.videoUrl = videoUrl
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.cancelled = true
        }
    }
}
