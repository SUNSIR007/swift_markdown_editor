import SwiftUI

struct PlatformRoundedTextField: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.textFieldStyle(.roundedBorder)
        #elseif os(macOS)
        content.textFieldStyle(RoundedBorderTextFieldStyle())
        #else
        content
        #endif
    }
}

extension View {
    func platformRoundedTextField() -> some View {
        modifier(PlatformRoundedTextField())
    }
}
