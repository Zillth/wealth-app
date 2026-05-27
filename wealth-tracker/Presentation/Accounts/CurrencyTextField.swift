import SwiftUI

/// A themed text field that prepends a `$` sign and auto-formats
/// the integer part with comma thousands separators as the user types.
/// The binding always holds the display string (e.g. "10,000.50");
/// callers must strip commas before parsing: `s.replacingOccurrences(of: ",", with: "")`.
struct CurrencyTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 4) {
            Text("$")
                .foregroundStyle(Color.appPrimary)
            TextField(label, text: $text)
                .keyboardType(.decimalPad)
                .foregroundStyle(Color.appPrimary)
                .onChange(of: text) { _, newValue in
                    let reformatted = reformat(newValue)
                    if reformatted != newValue { text = reformatted }
                }
                .onAppear {
                    let reformatted = reformat(text)
                    if reformatted != text { text = reformatted }
                }
        }
    }

    // MARK: - Formatting

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .decimal
        f.groupingSeparator    = ","
        f.usesGroupingSeparator = true
        f.locale               = Locale(identifier: "en_US")
        return f
    }()

    private func reformat(_ input: String) -> String {
        // Collect digit characters and track a single decimal point
        var intDigits  = ""
        var decDigits  = ""
        var seenDot    = false

        for ch in input {
            if ch.isNumber {
                if seenDot { decDigits.append(ch) }
                else        { intDigits.append(ch) }
            } else if ch == "." && !seenDot {
                seenDot = true
            }
        }

        // Nothing typed yet
        guard !intDigits.isEmpty || seenDot else { return "" }

        // Format integer part with comma groups
        let intValue     = Int(intDigits) ?? 0
        let formattedInt = Self.formatter.string(from: NSNumber(value: intValue)) ?? intDigits
        // When user starts with "." alone, show "0."
        let base = intDigits.isEmpty ? "0" : formattedInt

        return seenDot ? "\(base).\(decDigits)" : formattedInt
    }
}
