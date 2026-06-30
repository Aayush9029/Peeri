import SwiftUI

struct HoverableActionButton: View {
    let icon: String
    let tooltip: String
    var hoverColor: Color = .primary
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(isHovered ? hoverColor : .secondary)
                .frame(width: 32, height: 32)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    HStack {
        HoverableActionButton(icon: "pause.fill", tooltip: "Pause") {}
        HoverableActionButton(icon: "folder", tooltip: "Show in Finder") {}
        HoverableActionButton(icon: "trash", tooltip: "Delete", hoverColor: .red) {}
    }
    .padding()
}
