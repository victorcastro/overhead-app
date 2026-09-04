import SwiftUI

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.control)
                Capsule()
                    .fill(Theme.positive)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}
