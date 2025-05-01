//
//  AuthManager.swift
//  TestProjectAe
//

import GoogleSignIn
import Firebase
import FirebaseAuth
import Foundation
import FirebaseFirestore

enum NetworkError: Error {
    case errorDescription(desc: String)
}

final class AuthManager {
    
    static let shared = AuthManager()
    private init() { }
    
    typealias ResultCompletionHandler = (Result<Bool, NetworkError>) -> Void
      
    func googleSignIn(completion: @escaping ResultCompletionHandler) {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            let errorDesc = "Error: Unable to get the presenting view controller."
            completion(.failure(.errorDescription(desc: errorDesc)))
            return
        }
        let config = GIDConfiguration(clientID: Constants.clientID)
        let signIn = GIDSignIn.sharedInstance
        signIn.configuration = config
        signIn.signIn(withPresenting: presentingViewController) { signInResult, error in
            if let error = error {
                let errorDesc = error.localizedDescription
                completion(.failure(.errorDescription(desc: errorDesc)))
            }
            guard let user = signInResult?.user else { return }
            print("DEBUG: Did Log user in.. \(String(describing: user))")
            completion(.success(true))
        }
    }
    
    func firebaseAuthSignIn(email: String,
                            password: String,
                            completion:  @escaping ResultCompletionHandler) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                let errorDesc = "Wrong Credentials! Please, check again."
                completion(.failure(.errorDescription(desc: errorDesc)))
            }
            
            guard let user = result?.user else { return }
            completion(.success(true))
            print("DEBUG: Did Log user in.. \(String(describing: user.email))")
        }
    }
    
    func firebaseSignUp(email: String,
                        password: String,
                        username: String,
                        completion:  @escaping ResultCompletionHandler) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                let nsError = error as NSError
                switch nsError.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    print("wrong password")
                case AuthErrorCode.invalidEmail.rawValue:
                    print("invalid email")
                case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
                    print("accountExistsWithDifferentCredential")
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    print("email is alreay in use")
                default:
                    print("unknown error: \(nsError.localizedDescription)")
                }
                completion(.failure(.errorDescription(desc: nsError.localizedDescription)))
                return
            }
            
            guard let user = result?.user else { return }
            
            let userData = ["email": email,
                            "password": password,
                            "username": username.lowercased(),
                            "uid": user.uid]

            Firestore.firestore().collection("users")
                .document(user.uid)
                .setData(userData) { _ in
                    print("DEBUG: Did upload user data.")
                }
            completion(.success(true))
        }
    }
    
    func resetPassword(email: String,
                       completion:  @escaping ResultCompletionHandler) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("DEBUG: Failed to send pass \(error.localizedDescription)")
                let errorDescr = "Failed to send pass \(error.localizedDescription)"
                completion(.failure(.errorDescription(desc: errorDescr)))
            }
            completion(.success(true))
        }
    }
    
    func logOut(completion: @escaping ResultCompletionHandler) {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            completion(.success(true))
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            completion(.failure(.errorDescription(desc: error.localizedDescription)))
        }
    }
    
    func checkStatus(completion: @escaping ResultCompletionHandler) {
        if Auth.auth().currentUser != nil {
            completion(.success(true))
        } else {
            checkGoogePrevSession(completion: completion)
        }
    }
    
}

extension AuthManager {
    func checkGoogleCurrentStatus(completion: @escaping ResultCompletionHandler) {
        if (GIDSignIn.sharedInstance.currentUser != nil) {
            let user = GIDSignIn.sharedInstance.currentUser
            guard let user = user else { return }
            print("DEBUG: Did Log user in.. \(String(describing: user))")
            // cюда сохранить из firebase
            completion(.success(true))
        } else {
            completion(.success(false))
        }
    }
    
    func checkGoogePrevSession(completion: @escaping ResultCompletionHandler) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                let errorDescr = error.localizedDescription
                completion(.failure(.errorDescription(desc: errorDescr)))
            }
            self.checkGoogleCurrentStatus(completion: completion)
        }
    }
}
