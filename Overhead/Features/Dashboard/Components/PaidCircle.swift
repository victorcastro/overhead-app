import SwiftUI

struct PaidCircle: View {
    let isPaid: Bool

    var body: some View {
        ZStack {
            if isPaid {
                Circle().fill(Theme.positive)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black)
            } else {
                Circle().strokeBorder(Theme.circleStroke, lineWidth: 1.5)
            }
        }
        .frame(width: 22, height: 22)
    }
}
