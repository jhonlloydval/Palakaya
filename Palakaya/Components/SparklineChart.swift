import SwiftUI

struct SparklineChart: View {
    var data: [Int]
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pad: CGFloat = 4
            let minV = Double(data.min() ?? 0)
            let maxV = Double(data.max() ?? 1)
            let range = max(maxV - minV, 1)

            let points: [CGPoint] = data.enumerated().map { i, v in
                let x = pad + CGFloat(i) * (w - pad * 2) / CGFloat(max(data.count - 1, 1))
                let y = h - pad - CGFloat((Double(v) - minV) / range) * (h - pad * 2)
                return CGPoint(x: x, y: y)
            }

            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for p in points.dropFirst() { path.addLine(to: p) }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            if let last = points.last {
                Circle().fill(color).frame(width: 8, height: 8).position(last)
            }
        }
        .frame(height: 64)
    }
}
