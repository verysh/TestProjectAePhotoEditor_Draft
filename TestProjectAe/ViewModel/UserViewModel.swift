//
//  UserViewModel.swift
//  TestProjectAe
//
//

import SwiftUI
import GoogleSignIn
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Photos
import PencilKit

/// Editing mode
enum DrawingMode: String, CaseIterable, Identifiable {
    case draw, text
    var id: Self { self }
}

/// Available fonts
enum TextFont: String, CaseIterable, Identifiable {
    case system, montserrat = "Montserrat-Black", pacifico = "Pacifico-Regular"
    var id: Self { self }
}

/// Text background mode
enum TextBackground: String  {
    case none = "character", border = "a.square", fill = "a.square.fill"
    static let allValues: [TextBackground] = [.none, .border, .fill]
}

enum StateAuth {
    case start
    case loading
    case loggedIn
    case error(_ error: NetworkError)
}


final class UserViewModel: ObservableObject {
    
    @Published var isPickerPresented: Bool = false
    @Published var selectedItem: MediaItem?
    @Published var isCameraPresented: Bool = false
    
    
    // request permissions
    @Published var status: Bool? = {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            return nil
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }()
    // User
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var warning = ""
    
    
    @Published var stateAuth: StateAuth = .start
    @Published var isResetPassword = false
      
    /// Main drawing canvas
    @Published var canvas = Canvas()
    /// Canvas required for ML drawings recognition to produce perfect shapes
    @Published var mlCanvas = MLCanvas()
    
    /// Current tool picker showing on bottom
    @Published var toolPicker: PKToolPicker?
    /// Controller used to handle gestures applied to text views
    @Published var canvasController: CanvasViewController<Canvas>?
    
    /// Current editing mode
    @Published var mode: DrawingMode = .draw
    /// Font size of selected text view, in percent, actually handle point size from 12 to 64
    @Published var fontSize: Float = 50.0
    @Published var scale = 0.0
    @Published var rotation = 0.0
    
    /// Hint text showing at bottom when no text added/selected
    @Published var infoText: String = "Tap to add text"
    
    /// Current text view alignment
    @Published var textAlignment: NSTextAlignment = .center
    
    
        
    /// Available text alignments
    let textAligments: [NSTextAlignment: String] = [
        // .justified: "text.justify",
        .center: "text.aligncenter",
        .left: "text.alignleft",
        .right: "text.alignright"
    ]
    
    /// Available fill colors
    let fillColors: [UIColor] = [
        .white, UIColor.dark, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .systemPink, .systemRed, .systemOrange,
    ]
    
    /// Text colors coming with pair to display different colors on different backgrounds - white on black atd.
    let textColors: [UIColor: UIColor] = [ // fill:text
        .white: UIColor.dark,
        UIColor.dark: .white,
        .systemYellow: .white,
        .systemGreen: .white,
        .systemBlue: .white,
        .systemPurple: .white,
        .systemPink: .white,
        .systemRed: .white,
        .systemOrange: .white,
    ]
    
    /// Property showing if any change was applied to image - either drawing or text
    @Published  var canUndo = false
    /// Selected text view, used to provide tools for currently active text
    @Published var selectedTextView: UIView?
    /// Property showing if all text views are visible or not, used for hidding them for better drawing experience
    @Published  var isTextVisible = true
    /// Is export in progress
    @Published  var isProcesing = false
    @Published  var isDismissAlertPresented = false
    
    @Published var mediaSize: CGSize?
    /// Image view used for fit/fill image size calculatiions, native SwiftUI Image has no such capabilities
    @Published  var imageView = UIImageView()
    /// Image aspect mode
    @Published var contentMode: ContentMode = .fit
    
    /// Selected text background color
    @Published  var fillColor: UIColor = .white
    /// Selected text background style
    @Published  var textStyle: TextBackground = .none
    /// Selected text font
    @Published  var font: TextFont = .system
    
    
    init() {
        checkAuthStatus()
    }
   
    func googleSignInAction() {
        stateAuth = .loading
        AuthManager.shared.googleSignIn { result in
            switch result {
            case .success:
                self.stateAuth = .loggedIn
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    func firebaseSignInAction() {
        stateAuth = .loading
        AuthManager.shared.firebaseAuthSignIn(email: email,
                                              password: password) { result in
            switch result {
            case .success:
                self.warning = ""
                self.stateAuth = .loggedIn
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    func firebaseSignUpAction() {
        stateAuth = .loading
        AuthManager.shared.firebaseSignUp(email: email,
                                          password: password,
                                          username: username) { result in
            switch result {
            case .success:
                self.warning = ""
                self.stateAuth = .loggedIn
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    func firebaseResetPasswordAction() {
        stateAuth = .loading
        AuthManager.shared.resetPassword(email: email) { result in
            switch result {
            case .success:
                self.stateAuth = .start
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    
    func logOutSession() {
        AuthManager.shared.logOut { result in
            switch result {
            case .success:
                self.stateAuth = .start
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    func displayWarningIfNeeded() -> Bool {
        if let warningMessage = validView() {
            print(warningMessage)
            warning = warningMessage
            return true
        }
        return false
    }

    func disabledContinueButton() -> Bool {
        return email.isEmpty && password.isEmpty
    }
    
    func getStatusPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.status = true
            }
        }
        self.status = false
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Method called on font changes
    func onFontChanged(_ value: TextFont) {
        guard let label = selectedTextView as? TextLabel else { return }
        let size = label.font.pointSize
        switch value {
        case .system:
            label.font = .systemFont(ofSize: size)
        case .montserrat:
            label.font = .init(name: "Montserrat", size: size)
        case .pacifico:
            label.font = .init(name: "Pacifico-Regular", size: size)
        }
        
        // resize
        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
    }
    
    /// Undo previous action
    func undo() {
        canvas.undoManager?.undo()
        canvas.previous = canvas.drawing
        
        // clear for case when some of drawings were persisted on temporary canvas
        mlCanvas.drawing = PKDrawing()
        
        resetSelection()
    }
    
    /// Hide all text views, adding new text will deactivate hidden mode
    func hideTextViews() {
        isTextVisible.toggle()
        
        changeTextsVisibility(visible: isTextVisible)

        resetSelection()
    }
    
    
    /// Clear all the drawings and texts with ability to undo clearing process
    func clearAll() {
        let labels: [UIView] = canvasController?.view.subviews.filter { $0 is UILabel } ?? []
        
        if ((canvas.drawing.strokes.isEmpty || canvas.drawing.bounds.isEmpty) && labels.isEmpty) {
            // empty canvas
            return
        }
        
        // MARK: Coment code behind to also clear the undo action of clearing all
        let original = canvas.drawing
        canvas.undoManager?.registerUndo(withTarget: canvas, handler: {
            $0.drawing = original
            
            for label in labels {
                self.canvasController?.view.addSubview(label)
            }
        })
        canvas.drawing = PKDrawing()
        
        mlCanvas.drawing = PKDrawing()
        
        for label in labels {
            label.removeFromSuperview()
        }
        
        resetSelection()
    }
    
    /// Show text entering view
    func addText() {
        if (canvasController == nil) {
            canvasController = canvas.parentViewController as? CanvasViewController<Canvas>
        }
        
        canvasController?.showTextAlert(title: "Add text", text: nil, actionTitle: "Add") { [weak self] text in
            self?.addTextView(text)
        }
    }
    
    /// Method called on text background color changes
    func colorTapped() {
        guard let label = selectedTextView as? TextLabel, let old = fillColors.firstIndex(where: {
            switch (textStyle) {
            case .none, .border:
                return label.textColor == $0
            case .fill:
                return label.layer.backgroundColor == $0.cgColor
            }
        }) else { return }
        
        let index = (old + 1) < fillColors.count ? old + 1 : 0
        switch (textStyle) {
        case .none:
            label.textColor = fillColors[index]
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
            break
        case .border:
            label.textColor = fillColors[index]
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.layer.borderColor = fillColors[index].cgColor
            label.styledLayer.borderColor = fillColors[index].cgColor
            break
        case .fill:
            let color = fillColors[index]
            label.backgroundColor = color
            label.layer.backgroundColor = color.cgColor
            label.textColor = textColors[color]
            break
        }
        
        fillColor = fillColors[index]
    }
    
    /// Method called on brish size slider changes
    func onFontSizeChanged(_ value: Float) {
        guard let label = selectedTextView as? UILabel else { return }
        
        // font size from 12 to 64
        label.font = label.font.withSize(CGFloat(value * 52.0) / 100.0 + 12.0)
        
        // resize
        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
    }
    
    /// Method to align currently selected text
    func alingTextTapped() {
        guard let label = selectedTextView as? UILabel else { return }
        switch (textAlignment) {
        case .left: textAlignment = .center; break
        case .center: textAlignment = .right; break
        case .right: textAlignment = .left; break
        default: return
        }
        label.textAlignment = textAlignment
    }
    
    /// Update text view background style
    func textStyleTapped() {
        guard let label = selectedTextView as? TextLabel else { return }
        
        switch (textStyle) {
        case .none:
            textStyle = .border
            // border
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.layer.borderWidth = 3
            // label.layer.borderColor = UIColor.white.cgColor
            label.layer.borderColor = label.textColor.cgColor
            label.tag = 1
            fillColor = label.textColor
            break
        case .border:
            textStyle = .fill
            // fill
            label.textColor = textColors[.white]
            label.backgroundColor = .white
            label.layer.backgroundColor = UIColor.white.cgColor
            label.layer.borderWidth = 0
            label.tag = 2
            fillColor = .white
            break
        case .fill:
            textStyle = .none
            // simple
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.backgroundColor = .clear
            label.layer.borderWidth = 0
            label.tag = 0
            fillColor = label.textColor
            //fillColor = UIColor(cgColor: label.layer.backgroundColor ?? UIColor.white.cgColor)
            break
        }
        label.styledLayer = label.layer.copied
    }
    
    /// Helper method to hide/show all text views
    func changeTextsVisibility(visible: Bool) {
        for view in canvasController?.view.subviews ?? [] {
            if (view is UILabel) {
                view.isHidden = !visible
            }
        }
    }
    
    /// Editing mode changed - update UI
    func modeChanged(_ selected: DrawingMode) {
        if canvasController == nil {
            canvasController = canvas.parentViewController as? CanvasViewController<Canvas>
        }
        if (toolPicker == nil) {
            toolPicker = canvasController?.toolPicker
        }
        
        // show/hide PKToolPicker
        if (selected == .text) {
            toolPicker?.isRulerActive = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.toolPicker?.setVisible(false, forFirstResponder: self.canvas)
                self.canvas.isUserInteractionEnabled = false
                self.mlCanvas.isUserInteractionEnabled = false
            })
            
            let labels: [UIView] = canvasController?.view.subviews.filter { $0 is UILabel } ?? []
            infoText = labels.isEmpty ? "Tap to add text" : "Tap any text to customize"
            
            canvasController?.selectionEnabled = true
        } else {
            activateCanvas()
            
            canvas.isUserInteractionEnabled = true
            mlCanvas.isUserInteractionEnabled = true
            toolPicker?.setVisible(true, forFirstResponder: canvas)
            
            activateCanvas()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.activateCanvas()
            })
            
            canvasController?.selectionEnabled = false
        }
        resetSelection()
    }
    
    /// Set first responder to main canvas
    func activateCanvas() {
        canvas.becomeFirstResponder()
        canvas.resignFirstResponder()
        canvas.becomeFirstResponder()
    }
        
    /// Deselect text view
    func resetSelection() {
        if let view = selectedTextView {
            canvasController?.deselectSubview(view)
        }
        textAlignment = .center
    }
    
    /// Insert new text view as canvas controller subview
    func addTextView(_ text: String) {
        guard let controller = canvasController else { return }
        let label = TextLabel(frame: CGRect(x: controller.view.center.x - 128, y: controller.view.center.y - 64, width: 256, height: 128))
        label.accessibilityIdentifier = "textview_\(Int.random(in: 0..<65536))"
        label.numberOfLines = 0
        
        label.text = text
        label.textColor = .white
        label.textAlignment = .center

        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
        
        label.layer.cornerRadius = 16
        label.layer.borderWidth = 3
        label.layer.borderColor = UIColor.white.cgColor
        label.tag = 1
        label.layer.masksToBounds = true
        label.styledLayer = label.layer.copied

        label.isHidden = !isTextVisible

        // enable multiple touch and user interaction
        label.isUserInteractionEnabled = true
        label.isMultipleTouchEnabled = true
                
        canvas.undoManager?.registerUndo(withTarget: canvas, handler: { _ in
            label.removeFromSuperview()
        })
        
        controller.registerGestures(for: label)
        controller.view.addSubview(label)
        
        resetSelection()
        controller.selectSubview(label)
        
        if isTextVisible == false {
            isTextVisible = true
            changeTextsVisibility(visible: true)
        }
    }
    
    /// Text view selectiong changed
    func selectionChanged(_ view: UIView?) {
        selectedTextView = view
                                    
        let label = view as? UILabel

        let pointSize = Float(label?.font.pointSize ?? 17.0)
        fontSize = ((pointSize - 12.0) * 100.0) / 52.0
        
        textAlignment = label?.textAlignment ?? .center
        
        guard let index = label?.tag, index >= 0, index < TextBackground.allValues.count else { return }
        textStyle = TextBackground.allValues[index]
        
        switch (textStyle) {
        case .none, .border:
            fillColor = label?.textColor ?? .white
            break
        case .fill:
            fillColor = label?.backgroundColor ?? .white
            break
        }
        
        // font
        switch label?.font.fontName {
        case TextFont.montserrat.rawValue:
            font = .montserrat
        case TextFont.pacifico.rawValue:
            font = .pacifico
        default:
            font = .system
        }
        
        infoText = "Tap any text to customize"
    }
}

private extension UserViewModel {
    
    func checkAuthStatus() {
        AuthManager.shared.checkStatus { result in
            switch result {
            case .success(let res):
                self.stateAuth = res ? .loggedIn : .start
            case .failure(let error):
                self.stateAuth = .error(error)
            }
        }
    }
    
    
    func validView() -> String? {
        if email.isEmpty {
            return "Email is empty"
        }
        
        if !self.isValidEmail(email) {
            return "Email is invalid"
        }
        
        if password.isEmpty {
            return "Password is empty"
        }
        
        if self.password.count < 6 {
            return "Password should be 6 character long"
        }
        
        return nil
    }
}
