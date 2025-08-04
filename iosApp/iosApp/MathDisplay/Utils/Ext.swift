import Foundation
import SwiftUICore

extension Float {
    func toFixed(n: Int) -> String {
        let str = String(format: "%.0\(n)f", self)
        let dotIndex = str.firstIndex(of: ".") ?? str.endIndex
        var decimalPart = String(str[dotIndex..<str.endIndex]).dropFirst()  // 去掉点
        if decimalPart.count < n {
            decimalPart += String(repeating: "0", count: n - decimalPart.count)
        } else if decimalPart.count > n {
            decimalPart = decimalPart.prefix(n)
        }
        return String(str[..<dotIndex]) + "." + decimalPart
    }
}

extension GraphicsContext {
    func save() {
        withCGContext { context in
            context.saveGState()
        }
    }
    func restore() {
        withCGContext { context in
            context.restoreGState()
        }
    }
    func drawArc(left: Float, top: Float, right: Float, bottom: Float, startAngle: Float, sweepAngle: Float, useCenter: Bool, color: Color) {
        let centerX = (left + right) / 2
        let centerY = (top + bottom) / 2
        let radiusX = (right - left) / 2
        let radiusY = (bottom - top) / 2

        let startAngleRad = startAngle * .pi / 180
        let endAngleRad = (startAngle + sweepAngle) * .pi / 180

        var path = Path()
        if useCenter {
            path.addArc(center: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)),
                        radius: CGFloat(radiusX),
                        startAngle: Angle(radians: Double(startAngleRad)),
                        endAngle: Angle(radians: Double(endAngleRad)),
                        clockwise: false)
            path.addLine(to: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)))
        } else {
            path.addArc(center: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)),
                        radius: CGFloat(radiusX),
                        startAngle: Angle(radians: Double(startAngleRad)),
                        endAngle: Angle(radians: Double(endAngleRad)),
                        clockwise: false)
        }

        self.stroke(path, with: .color(color), lineWidth: 1.0)
    }

    func drawLine(x1: Float, y1: Float, x2: Float, y2: Float,lineWidth: Float, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: CGFloat(x1), y: CGFloat(y1)))
        path.addLine(to: CGPoint(x: CGFloat(x2), y: CGFloat(y2)))
        self.stroke(path, with: .color(color), lineWidth: CGFloat(lineWidth))
    }
}
