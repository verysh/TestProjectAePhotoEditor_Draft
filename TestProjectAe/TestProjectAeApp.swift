//
//  TestProjectAeApp.swift
//  TestProjectAe
//
//  Created by Vladimir Eryshev on 28.04.2025.
//

import SwiftUI
import Firebase

@main
struct TestProjectAeApp: App {
    
    @StateObject var viewModel = UserViewModel()
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                LoginView()
             }
            .environmentObject(viewModel)
        }
    }
}
