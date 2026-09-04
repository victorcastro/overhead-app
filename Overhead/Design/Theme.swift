import SwiftUI

enum Theme {
    static let background = Color.black
    static let card = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let separator = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    static let control = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)
    static let accent = Color(red: 10 / 255, green: 132 / 255, blue: 255 / 255)
    static let positive = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
    static let destructive = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)

    private static let label = Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255)
    static let primaryText = Color.white
    static let secondaryText = label.opacity(0.5)
    static let mutedText = label.opacity(0.4)
    static let headerText = label.opacity(0.55)
    static let circleStroke = label.opacity(0.35)

    static let cardRadius: CGFloat = 14
    static let horizontalPadding: CGFloat = 16
}

extension View {
    func cardBackground() -> some View {
        background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(Theme.headerText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }
}

struct CardList<Data: RandomAccessCollection, Row: View>: View where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let row: (Data.Element) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.separator)
                        .frame(height: 1)
                }
                row(element)
            }
        }
        .cardBackground()
    }
}
