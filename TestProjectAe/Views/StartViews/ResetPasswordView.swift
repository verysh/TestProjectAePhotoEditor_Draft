//

import SwiftUI

struct ResetPasswordView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: UserViewModel
    
    var body: some View {
        switch viewModel.stateAuth {
        case .start:
            resetPassView
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
    
    private var resetPassView: some View {
        VStack {
            AuthHeaderView(title1: "Forgot password,", title2: "Type email and reset")
            
            VStack(spacing: 40) {
                CustomInputField(imageName: "envelope",
                                 placeholderText: "Email",
                                 textCase: .lowercase,
                                 keyboardType: .emailAddress,
                                 textContentType: .emailAddress,
                                 text: $viewModel.email)
            }
            .padding(32)
            if !viewModel.isResetPassword {
                Button {
                    print("Reset")
                    if viewModel.isValidEmail(viewModel.email) {
                        viewModel.firebaseResetPasswordAction()
                    }
                } label: {
                    ModifiedContent(
                                    content: Text("Reset"),
                                    modifier: BlueCapsuleBackground()
                                )
                }
                .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 0)
                .disabled(viewModel.email.isEmpty)
                .opacity(viewModel.email.isEmpty ? 0.6 : 1)
            }
            
            if !viewModel.isValidEmail(viewModel.email) && !viewModel.email.isEmpty  {
                ModifiedContent(
                                content: Text("Warning!\n Correct the email!"),
                                modifier: WarningLabel()
                            )
            }
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack {
                    if !viewModel.isResetPassword {
                        Text("Already have an account?")
                            .font(.footnote)
                    }
                    
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

#Preview {
    ResetPasswordView()
}
