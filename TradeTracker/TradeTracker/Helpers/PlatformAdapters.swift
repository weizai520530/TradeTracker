import SwiftUI

// Cross-platform shims for APIs that exist only on iOS.
// On macOS these are no-ops (or use the closest semantic equivalent).

extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func uppercaseAutoInput() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.characters)
        #else
        self
        #endif
    }

    // macOS sheets don't auto-size to their content the way iOS does,
    // so give them a sensible minimum so Lists/Forms have room to render.
    @ViewBuilder
    func sheetSizing() -> some View {
        #if os(macOS)
        self.frame(minWidth: 480, minHeight: 600)
        #else
        self
        #endif
    }
}

extension ToolbarItemPlacement {
    static var leadingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .navigation
        #endif
    }

    static var trailingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .primaryAction
        #endif
    }
}
