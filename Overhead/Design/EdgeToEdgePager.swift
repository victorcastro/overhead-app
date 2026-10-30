import SwiftUI

private struct PagerInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

extension EnvironmentValues {
    var pagerInsets: EdgeInsets {
        get { self[PagerInsetsKey.self] }
        set { self[PagerInsetsKey.self] = newValue }
    }
}

private struct EdgeToEdgePager: ViewModifier {
    @State private var insets = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .environment(\.pagerInsets, insets)
            .ignoresSafeArea(.container, edges: .horizontal)
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.safeAreaInsets
            } action: { newValue in
                insets = newValue
            }
    }
}

extension View {
    func edgeToEdgePager() -> some View {
        modifier(EdgeToEdgePager())
    }

    func pagerContentPadding(_ inset: CGFloat = Theme.horizontalPadding) -> some View {
        modifier(PagerContentPadding(inset: inset))
    }
}

private struct PagerContentPadding: ViewModifier {
    @Environment(\.pagerInsets) private var insets
    let inset: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.leading, insets.leading + inset)
            .padding(.trailing, insets.trailing + inset)
    }
}
