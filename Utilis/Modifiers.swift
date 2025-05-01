//

import SwiftUI

struct BlueCapsuleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 340, height: 50)
            .background(Color.themeColor)
            .clipShape(Capsule())
            .padding()
    }
}

struct WarningLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .font(.headline)
            .foregroundColor(.red)
            .frame(width: 340, height: 50)
            .padding()
    }
}
  
struct ForgotPasswordLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color.themeColor)
            .padding(.top)
            .padding(.trailing, 24)
    }
}

struct LogOutLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 36)
            .padding(.horizontal, 12)
            .foregroundColor(.light)
            .background(Color.darkHighlight)
            .clipShape(Rectangle())
            .cornerRadius(36)
            .padding(.all, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

