//

import SwiftUI
import AVKit

enum MediaType {
    case image
}

struct MediaItem: Equatable {
    let type: MediaType
    var image: UIImage?
    
    static func ==(lhs: MediaItem, rhs: MediaItem) -> Bool {
        guard lhs.type == rhs.type else { return false }
        switch lhs.type {
        case .image:
            return lhs.image == rhs.image
        default:
            break
        }
    }
}

/// Default UIImagePicker ported to SwiftUI, may be presented as fullscreen view or in sheet
struct ImagePicker: UIViewControllerRepresentable {
    
    var didFinishSelection: (MediaItem) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()

        imagePicker.allowsEditing = false
        imagePicker.videoExportPreset = AVAssetExportPresetPassthrough
        imagePicker.videoQuality = .typeHigh
        imagePicker.sourceType = .photoLibrary
        if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            imagePicker.mediaTypes = mediaTypes // ["public.image", "public.movie"]
        }
        imagePicker.overrideUserInterfaceStyle = .dark
        // imagePicker.modalPresentationStyle = .overCurrentContext
        imagePicker.delegate = context.coordinator
 
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) { }
    
    func makeCoordinator() -> Coordinator { Coordinator(handler: didFinishSelection) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UINavigationBarDelegate {
        
        var handler: (MediaItem) -> Void
        
        init(handler: @escaping (MediaItem) -> Void) {
            self.handler = handler
        }
  
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                handler(MediaItem(type: .image, image: image))
            } 
            // picker.dismiss(animated: true, completion: nil)
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(didFinishSelection: { _ in })
    }
}
