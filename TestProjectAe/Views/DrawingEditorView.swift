//


import SwiftUI
import PencilKit
import AVKit
import Photos

struct DrawingEditorView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: UserViewModel
    @Environment(\.undoManager) private var undoManager
    private let undoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerCheckpoint)
    
    private var animationArrow: Animation {
        Animation
            .easeInOut(duration: 0.2)
    }
    
    @State var media: MediaItem
    let onClose: () -> Void
    
    init(media: MediaItem, onClose: @escaping () -> Void) {
        self.media = media
        self.onClose = onClose
        
       setPickerAppearance()
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar
                ZStack(alignment: .center) {
                    // Font picker
                    if (viewModel.canUndo && viewModel.selectedTextView != nil) {
                        if viewModel.mode == .text {
                            Picker("Font", selection: $viewModel.font) {
                                Text("Default Font")
                                    .font(.system(size: 20))
                                    .tag(TextFont.system)
                                Text("Montserrat")
                                    .font(Font.custom("Montserrat", size: 20))
                                    .tag(TextFont.montserrat)
                                Text("Pacifico")
                                    .font(Font.custom("Pacifico-Regular", size: 20))
                                    .tag(TextFont.pacifico)
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(width: UIScreen.main.bounds.width, height: 56).clipped()
                            .frame(width: 128, height: 32).clipped()
                            .onChange(of: viewModel.font,
                                      perform: viewModel.onFontChanged)
                        }
                    }
                    
                    HStack {
                        // Undo button
                        Button(action: viewModel.undo) {
                            CircleIcon(systemName: "arrow.uturn.backward", disabled: !viewModel.canUndo)
                                .padding(.all, 4)
                        }
                        .animation(.spring())
                        .disabled(!viewModel.canUndo)
                        .onReceive(undoObserver) { _ in
                            viewModel.canUndo = viewModel.canvas.undoManager?.canUndo ?? false
                        }
                        
                        // Hide all text views button
                        if (viewModel.mode == .text) {
                            Button(action: viewModel.hideTextViews) {
                                CircleIcon(systemName: viewModel.isTextVisible ? "eye.slash" : "eye", disabled: !viewModel.canUndo)
                                    .padding(.all, 4)
                            }.disabled(!viewModel.canUndo)
                        }
                        
                        Spacer()
                        
                        if let img = media.image {
                            ShareLink(item: Image(uiImage: img), preview: SharePreview("Share image", image: img)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .foregroundColor(Color(.white))
                        }
                        
                        Spacer()
                        Button(action: viewModel.clearAll) {
                            Text("Clear All")
                                .frame(height: 36)
                                .padding(.horizontal, 12)
                                .foregroundColor(viewModel.canUndo ? .light: .gray)
                                .background(viewModel.canUndo ? Color.darkHighlight : Color(red: 44/255, green: 44/255, blue: 44/255))
                                .clipShape(Rectangle())
                                .cornerRadius(36)
                                .padding(.all, 4)
                        }
                        .disabled(!viewModel.canUndo)
                    }
                    .padding(.all, 8)
                    .animation(.spring())
                }
                .disabled(viewModel.isProcesing)
                
                Spacer()
                
                // Media view
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .local)
                    let size = calculateCanvasSize(bounds: geometry.size)
                    
                    
                    Group {
                        if let img = media.image {
                            ImageView(
                                image: Binding(get: { img }, set: { _ in }),
                                imageView: viewModel.imageView,
                                contentMode: Binding(
                                    get: { viewModel.contentMode == .fit ? .scaleAspectFit : .scaleAspectFill },
                                    set: { _ in }
                                )
                            )
                            .rotationEffect(.degrees(viewModel.rotation))
                            .transformEffect(
                                CGAffineTransform(scaleX: viewModel.scale, y: viewModel.scale)
                            )
                            .animation(animationArrow, value: 1)
                            .onChange(of: media) { media in
                                // get image size for .fit content mode
                                calculateImageSize(frame)
                            }
                            .onAppear {
                                // get image size for .fit content mode
                                calculateImageSize(frame)
                            }
                        }
                    }
                    .allowsHitTesting(false) // required to passthough touch events to ML Canvas
                    .background(
                        // ML canvas
                        CanvasView(canvas: $viewModel.mlCanvas, shouldBecameFirstResponder: false)
                            .frame(width: size.width, height: size.height)
                    )
                    .overlay(
                        // Main drawing canvas
                        CanvasView(canvas: $viewModel.canvas, onChanged: { drawing in }, onSelectionChanged: viewModel.selectionChanged)
                            .onAppear {
                                viewModel.mlCanvas.mainCanvas = viewModel.canvas
                                viewModel.canvas.mlCanvas = viewModel.mlCanvas
                            }
                            .frame(width: size.width, height: size.height)
                    )
                }
                
                if let img = media.image {
                    FilterScrollView(
                        inputImage: img,
                        filteredImageHandler: { filteredImage in
                            media.image = filteredImage
                        }
                    )
                }
                
                Spacer()
                slidersActions
                Spacer()
                
                // Bottom tool bar
                VStack(spacing: 0) {
                    HStack {
                        // Close button
                        Button(action: {
                            if (viewModel.canUndo) {
                                viewModel.isDismissAlertPresented = true
                            } else {
                                close()
                            }
                        }) {
                            CircleIcon(systemName: "xmark").padding(.all, 4)
                        }
                        
                        // Mode switcher
                        Picker("Mode", selection: $viewModel.mode) {
                            Text("Draw").tag(DrawingMode.draw)
                            Text("Text").tag(DrawingMode.text)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.mode, perform: viewModel.modeChanged)
                        
                        // Save button
                        Button(action: export) {
                            CircleIcon(systemName: "arrow.down", disabled: !viewModel.canUndo, hidden: viewModel.isProcesing)
                                .padding(.all, 4)
                                .overlay(
                                    viewModel.isProcesing ? ProgressView().foregroundColor(.light) : nil
                                )
                        }.disabled(!viewModel.canUndo)
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                    .background(Color.dark)
                    .disabled(viewModel.isProcesing)
                    
                    HStack {
                        if (viewModel.mode == .draw) {
                            // Spacer()
                            viewModel.isDismissAlertPresented ? AnyView(Color.dark) : AnyView(Color(red: 29/255, green: 28/255, blue: 30/255)
                                .onTapGesture {
                                    viewModel.activateCanvas()
                                })
                        } else {
                            ZStack(alignment: .center) {
                                Color.dark.blendMode(BlendMode.sourceAtop).edgesIgnoringSafeArea(.all)
                                if (viewModel.selectedTextView != nil) {
                                    HStack {
                                        
                                        // Text background color picker
                                        Button(action: viewModel.colorTapped) {
                                            Circle()
                                                .fill(Color(viewModel.fillColor))
                                                .frame(width: 33, height: 33)
                                                .overlay(
                                                    Circle().stroke(Color.light, lineWidth: 3)
                                                )
                                                .padding(.leading, 14)
                                                .padding(.trailing, 5)
                                        }
                                        
                                        // Text Background switcher
                                        Button(action: viewModel.textStyleTapped) {
                                            Image(systemName: "character")
                                                .frame(width: 34, height: 34)
                                                .foregroundColor(viewModel.textStyle == .fill ? .dark : .light)
                                                .background(viewModel.textStyle == .fill ? Color.light : Color.darkHighlight)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle().stroke(viewModel.textStyle == .none ? Color.darkHighlight : Color.light, lineWidth: 2)
                                                )
                                        }
                                        .padding(.vertical, 4)
                                        
                                        // Brush size slider
                                        FontSlider(
                                            progress: $viewModel.fontSize,
                                            foregroundColor: .light,
                                            backgroundColor: .darkHighlight
                                        )
                                        .frame(height: 36)
                                        .onChange(of: viewModel.fontSize, perform: viewModel.onFontSizeChanged)
                                        
                                        Spacer()
                                        
                                        // Alignment switcher
                                        Button(action: viewModel.alingTextTapped) {
                                            CircleIcon(systemName: viewModel.textAligments[viewModel.textAlignment] ?? "text.aligncenter")
                                                .padding(.all, 4)
                                        }
                                        
                                        Button(action: viewModel.addText) {
                                            CircleIcon(systemName: "plus")
                                        }
                                        .padding(.leading, 4)
                                        .padding(.trailing, 14)
                                    }
                                } else {
                                    // Text hint
                                    Text(!viewModel.isTextVisible ? "Hide text mode is active" : viewModel.infoText).fontWeight(.bold).foregroundColor(.light)
                                        .onTapGesture {
                                            if viewModel.isTextVisible {
                                                viewModel.addText()
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .frame(height: 75.0)
                    .animation(viewModel.mode == .draw ? .easeIn(duration: 0.05).delay(viewModel.mode == .text ? 0.0 : 0.4) : nil, value: viewModel.mode)
                }
            }
            .background(Color.dark.edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .alert(isPresented: $viewModel.isDismissAlertPresented) {
            // Cancelation alert
            Alert(
                title: Text("Are you sure?"),
                message: Text("Changes will not be saved"),
                primaryButton: .cancel(Text("Cancel")),
                secondaryButton: .destructive(Text("Leave"), action: {
                    close()
                })
            )
        }
    }
    
    private var slidersActions: some View {
        VStack(alignment: .leading) {
            scaleSlider
            rotateSlider
        }
        .padding()
    }
    
    private var scaleSlider: some View {
        VStack(alignment: .leading) {
            Text("Scale")
            Slider(value: $viewModel.scale, in: 0...2)
                .frame(height: 24)
        }
    }
    
    private var rotateSlider: some View {
        VStack(alignment: .leading) {
            Text("Rotate")
            Slider(value: $viewModel.rotation, in: 0...360)
                .frame(height: 24)
        }
    }
    
    /// Leave editor view, clean up local states
    func close() {
        defer { onClose() }
        viewModel.mode = .draw
        
        viewModel.toolPicker?.isRulerActive = false
        viewModel.toolPicker?.setVisible(false, forFirstResponder:  viewModel.canvas)
        viewModel.canvas.isUserInteractionEnabled = false
        viewModel.mlCanvas.isUserInteractionEnabled = false
        
        viewModel.contentMode = .fit
        viewModel.isTextVisible = true
        viewModel.mediaSize = nil
        
        let labels: [UIView] =  viewModel.canvasController?.view.subviews.filter { $0 is UILabel } ?? []
        
        if (( viewModel.canvas.drawing.strokes.isEmpty ||  viewModel.canvas.drawing.bounds.isEmpty) && labels.isEmpty) {
            // empty canvas
            return
        }
        
        viewModel.canvas.drawing = PKDrawing()
        viewModel.mlCanvas.drawing = PKDrawing()
        viewModel.canvas.undoManager?.removeAllActions()
        
        for label in labels {
            label.removeFromSuperview()
        }
        
        viewModel.resetSelection()
    }
    
    /// Save drawings and texts with selected video or image to user's media library
    func export() {
        withAnimation {
            viewModel.isProcesing = true
        }
        
        if (viewModel.canvasController == nil) {
            viewModel.canvasController = viewModel.canvas.parentViewController as? CanvasViewController<Canvas>
        }
        guard let canvasController = viewModel.canvasController else { return }
        
        // render controller view (contains drawing and text views)
        let renderer = UIGraphicsImageRenderer(size: canvasController.view.bounds.size)
        let markup = renderer.image { ctx in
            canvasController.view.drawHierarchy(in: canvasController.view.bounds, afterScreenUpdates: true)
        }
        // optionally drawing may be exported directly from canvas
        // let markup = canvas.drawing.image(from: canvas.bounds, scale: 1.0)
        
        if let img = media.image, media.type == .image {
            MediaProcessor.exportImage(image: img, markup: markup, contentMode: viewModel.contentMode, imageView: viewModel.imageView)
            
            withAnimation { viewModel.isProcesing = false }
            close()
        }
    }
    
    func calculateCanvasSize(bounds: CGSize) -> CGSize {
        if media.type == .image  {
            if viewModel.contentMode == .fill {
                return bounds
            } else {
                return viewModel.imageView.aspectFitSize
            }
        }
        
        // video
        return CGSize(
            width: viewModel.mediaSize?.width ?? bounds.width,
            height: viewModel.mediaSize?.height ?? bounds.height
        )
    }
    //
    //    /// Calculate image fit size
    func calculateImageSize(_ frame: CGRect) {
        guard media.type == .image && viewModel.contentMode == .fit else { return }
        guard let img = media.image else { return }
        let size = img.size
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if size.height >= size.width {
            newHeight = frame.size.height
            newWidth = ((size.width / (size.height)) * newHeight)
            
            if CGFloat(newWidth) > (frame.size.width) {
                let diff = (frame.size.width) - newWidth
                newHeight = newHeight + CGFloat(diff) / newHeight * newHeight
                newWidth = frame.size.width
            }
        } else {
            newWidth = frame.size.width
            newHeight = (size.height / size.width) * newWidth
            
            if newHeight > frame.size.height {
                let diff = Float((frame.size.height) - newHeight)
                newWidth = newWidth + CGFloat(diff) / newWidth * newWidth
                newHeight = frame.size.height
            }
        }
        
        viewModel.mediaSize = CGSize(width: newWidth, height: newHeight)
    }
}

private extension DrawingEditorView {
    func setPickerAppearance() {
        UIPickerView.appearance().backgroundColor = UIColor(red: 17/255, green: 16/255, blue: 14/255, alpha: 1.0)
        
        // segmented picker style
        let appearance = UISegmentedControl.appearance()
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.dark], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.light], for: .normal)
        UISegmentedControl.appearance().backgroundColor = UIColor(red: 21/255, green: 21/255, blue: 17/255, alpha: 1.0) // visible as 44,44,44
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
    }
}

//#Preview {
//    DrawingEditorView(media: MediaItem(type: .image, image: UIImage(named: "venice"), video: nil, videoUrl: nil), onClose: { })
//}
