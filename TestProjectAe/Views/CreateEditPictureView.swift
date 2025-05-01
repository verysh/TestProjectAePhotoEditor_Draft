//


import SwiftUI

struct CreateEditPictureView: View {
    
    @EnvironmentObject var viewModel: UserViewModel
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            logOutBtn
                .padding()
            Spacer()
            centerViews
            Spacer()
            if let selectedMedia = viewModel.selectedItem {
                DrawingEditorView(media: selectedMedia, onClose: {
                    viewModel.selectedItem = nil
                    viewModel.isPickerPresented = true
                })
            }
        }
        .sheet(isPresented: $viewModel.isPickerPresented) {
            ImagePicker(didFinishSelection: { media in
                viewModel.selectedItem = media
                viewModel.isPickerPresented = false
            })
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private var centerViews: some View {
        VStack(spacing: 16) {
            Button {
                if viewModel.status == true {
                    viewModel.isPickerPresented = true
                } else if viewModel.status == nil {
                    viewModel.getStatusPhotoLibrary()
                    viewModel.isPickerPresented = true
                }
            } label: {
                ModifiedContent(
                    content: Text("Select An Image"),
                    modifier: BlueCapsuleBackground()
                )
            }
            Spacer()
                .frame(height: 15)
            Button {
                viewModel.isCameraPresented = true
            } label: {
                ModifiedContent(
                    content: Text("Take A Picture"),
                    modifier: BlueCapsuleBackground()
                )
            }
            .sheet(isPresented: $viewModel.isCameraPresented) {
                CaptureImageView(isShown: $viewModel.isCameraPresented, capturedImage: $viewModel.selectedItem)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.clear)
    }
  
    private var logOutBtn: some View {
        Button(action: viewModel.logOutSession) {
            ModifiedContent(
                content: Text("Log Out"),
                modifier: LogOutLabel()
            )
        }
    }
}

#Preview {
    CreateEditPictureView()
}
