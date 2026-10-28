import SwiftUI

// Keep macOS 26's appearance while providing native material controls on Sequoia.
struct PastelGlassContainer<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing, content: content)
        } else {
            content()
        }
    }
}

extension View {
    /// The macOS 15.7.3 crash report shows TooltipResponder reading an invalid
    /// AttributeGraph value. Avoid registering SwiftUI tooltips on Sequoia;
    /// preserve their existing behavior on macOS 26 and accessibility hints below.
    @ViewBuilder
    func pastelHelp(_ message: String) -> some View {
        if #available(macOS 26.0, *) {
            help(message)
        } else {
            accessibilityHint(Text(message))
        }
    }

    @ViewBuilder
    func pastelSafeAreaBar<Content: View>(
        edge: VerticalEdge,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(macOS 26.0, *) {
            safeAreaBar(edge: edge, spacing: spacing, content: content)
        } else {
            safeAreaInset(edge: edge, spacing: spacing, content: content)
        }
    }

    @ViewBuilder
    func pastelGlassEffect<S: Shape>(
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S
    ) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            background(.regularMaterial, in: shape)
                .background(tint ?? .clear, in: shape)
                .overlay {
                    shape.stroke(.primary.opacity(0.12), lineWidth: 0.5)
                        .allowsHitTesting(false)
                }
        }
    }

    @ViewBuilder
    func pastelGlassEffectID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            self
        }
    }

    @ViewBuilder
    func pastelGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if prominent {
                buttonStyle(.borderedProminent)
            } else {
                buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    func pastelScrollEdgeEffect(hard: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            scrollEdgeEffectStyle(hard ? .hard : .soft, for: .top)
        } else {
            self
        }
    }

    @ViewBuilder
    func pastelBackgroundExtensionEffect() -> some View {
        if #available(macOS 26.0, *) {
            backgroundExtensionEffect()
        } else {
            self
        }
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder
    func pastelHiddenSharedBackground() -> some ToolbarContent {
        if #available(macOS 26.0, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
