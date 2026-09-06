import SwiftUI

struct SettingsNumberRow: View {
    let title: String
    @Binding var value: Int
    @FocusState private var isFocused: Bool
    let range: ClosedRange<Int>
    var unit: String

    init(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String = "") {
        self.title = title
        self._value = value
        self.range = range
        self.unit = unit
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            TextField(title, value: $value, format: .number.grouping(.never))
                .labelsHidden()
                .accessibilityLabel(title)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 80)
                .focused($isFocused)
                .onSubmit { clampValue() }
                .onChange(of: isFocused) { _, focused in
                    if !focused { clampValue() }
                }
            if !unit.isEmpty {
                Text(unit).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
            }
            Stepper(title, value: $value, in: range)
                .labelsHidden()
                .accessibilityLabel(title)
        }
    }
    private func clampValue() {
        value = min(max(value, range.lowerBound), range.upperBound)
    }
}
