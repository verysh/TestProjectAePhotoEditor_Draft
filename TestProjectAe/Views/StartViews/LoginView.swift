//


import SwiftUI

struct LoginView: View {

    @EnvironmentObject var viewModel: UserViewModel
    
    var body: some View {
        switch viewModel.stateAuth {
        case .start:
            signInView
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
    
    private var signInView: some View {
        VStack {
            AuthHeaderView(title1: "Hello,", title2: "Welcome!!!")
            
            VStack(spacing: 40) {
                CustomInputField(imageName: "envelope",
                                 placeholderText: "Email",
                                 textCase: .lowercase,
                                 keyboardType: .emailAddress,
                                 textContentType: .emailAddress,
                                 text: $viewModel.email)
                
                
                CustomInputField(imageName: "lock",
                                 placeholderText: "Password",
                                 textCase: .lowercase,
                                 keyboardType: .default,
                                 textContentType: .password,
                                 isSecureField: true,
                                 text: $viewModel.password)
            }
            .padding(.horizontal, 32)
            .padding(.top, 44)
            
            HStack {
                Spacer()
                
                NavigationLink {
                    ResetPasswordView()
                        .navigationBarHidden(true)
                } label: {
                    ModifiedContent(
                                    content: Text("Forgot Password?"),
                                    modifier: ForgotPasswordLabel()
                                )
                }
            }
            
            Button {
                print("Sign In")
                if !viewModel.displayWarningIfNeeded() {
                    viewModel.firebaseSignInAction()
                }
            } label: {
                ModifiedContent(
                                content: Text("Sign In"),
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
            
            googleSignInButton
            
            Spacer()
            
            NavigationLink  {
                RegistrationView()
                    .navigationBarHidden(true)
            } label: {
                HStack {
                    Text("Don't have an account?")
                        .font(.footnote)
                    
                    Text("Sign Up")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
            .padding(.bottom, 32)
            .foregroundColor(Color.themeColor)

        }
        .ignoresSafeArea()
    }
    
    private var googleSignInButton: some View {
        Button {
            viewModel.googleSignInAction()
        } label: {
            HStack {
                Image(uiImage: .googleIcon)
                    .resizable()
                    .frame(width: 44.0, height: 44.0)
                Text("Sign in  with Google")
            }
        }
    }
    
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct ErrorView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: UserViewModel
    let errorTitle: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .foregroundColor(.white)
            .overlay {
                
                VStack {
                    Text(errorTitle)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        viewModel.stateAuth = .start
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            }
    }
}
