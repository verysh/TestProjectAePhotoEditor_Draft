//


import SwiftUI

struct RegistrationView: View {

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: UserViewModel
    
    var body: some View {
        switch viewModel.stateAuth {
        case .start:
            signUpView
        case .loading:
            ProgressView("Loading...")
                .frame(width: 120, height: 120, alignment: .center)
                .font(.system(size: 14))
        case .loggedIn:
            CreateEditPictureView()
        case .error(let error):
            switch error {
            case .errorDescription(let desc):
                ErrorView(errorTitle: desc)
            }
        }
    }
    
    private var signUpView: some View {
        VStack {
            AuthHeaderView(title1: "Get started,", title2: "Create your account")
            
            VStack(spacing: 40) {
                CustomInputField(imageName: "envelope",
                                 placeholderText: "Email",
                                 textCase: .lowercase,
                                 keyboardType: .emailAddress,
                                 textContentType: .emailAddress,
                                 text: $viewModel.email)
                
                CustomInputField(imageName: "person",
                                 placeholderText: "Username",
                                 textCase: .lowercase,
                                 keyboardType: .default,
                                 textContentType: .username,
                                 text: $viewModel.username)
                
                CustomInputField(imageName: "lock",
                                 placeholderText: "Password",
                                 textContentType: .newPassword,
                                 isSecureField: true,
                                 text: $viewModel.password)
            }
            .padding(32)
            
            Button {
                print("Sign Up")
                if !viewModel.displayWarningIfNeeded() {
                    viewModel.firebaseSignUpAction()
                }
            } label: {
                ModifiedContent(
                                content: Text("Sign Up"),
                                modifier: BlueCapsuleBackground()
                            )
            }
            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
            .disabled(viewModel.disabledContinueButton())
            .opacity(viewModel.disabledContinueButton() ? 0.6 : 1)
            
            if !viewModel.warning.isEmpty {
                ModifiedContent(
                                content: Text("Warning!\n \(viewModel.warning)"),
                                modifier: WarningLabel()
                            )
            }
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    Text("Already have an account?")
                        .font(.footnote)
                    
                    Text("Sign In")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
            .padding(.bottom, 32)

        }
        .ignoresSafeArea()
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
