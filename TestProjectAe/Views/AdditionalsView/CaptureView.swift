//


import SwiftUI
import Foundation

struct CaptureImageView {
    @Binding var isShown: Bool
//    @Binding var capturedImage: UIImage?
    @Binding var capturedImage: MediaItem?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, capturedImage: $capturedImage)
    }
}

extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CaptureImageView>) {
        
    }
}

extension CaptureImageView {
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var isShown: Bool
        @Binding var capturedImage: MediaItem?
        
        init(isShown: Binding<Bool>, capturedImage: Binding<MediaItem?>) {
            _isShown = isShown
            _capturedImage = capturedImage
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let uiImage = info[.originalImage] as? UIImage else { return }
            capturedImage?.image = uiImage
            isShown = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isShown = false
        }
    }
}
