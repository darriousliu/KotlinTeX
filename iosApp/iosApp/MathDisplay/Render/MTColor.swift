import Foundation
import SwiftUICore

struct MTColor {
    static let BLACK = Int(0xFF000000)
    static let DARK_GRAY = Int(0xFF444444)
    static let GRAY = Int(0xFF888888)
    static let LIGHT_GRAY = Int(0xFFCCCCCC)
    static let WHITE = Int(0xFFFFFFFF)
    static let RED = Int(0xFFFF0000)
    static let GREEN = Int(0xFF00FF00)
    static let BLUE = Int(0xFF0000FF)
    static let YELLOW = Int(0xFFFFFF00)
    static let CYAN = Int(0xFF00FFFF)
    static let MAGENTA = Int(0xFFFF00FF)
    static let TRANSPARENT = 0

    /**
     * 通用字符串转Color
     * 支持 #RGB/#ARGB/#RRGGBB/#AARRGGBB，部分英文色名
     */
    static func parseColor(_ colorString: String?) -> Int {
        let str = (colorString ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // 支持常用英文色名
        let namedColors: [String: Int] = [
            "black": BLACK,
            "white": WHITE,
            "red": RED,
            "green": GREEN,
            "blue": BLUE,
            "yellow": YELLOW,
            "cyan": CYAN,
            "magenta": MAGENTA,
            "gray": GRAY,
        ]
        let colorInt: Int = {
            if str.hasPrefix("#") {
                // 去掉 #
                let hex = String(str.dropFirst())
                switch hex.count {
                case 3: // #RGB
                    let r = String(repeating: hex[hex.startIndex], count: 2)
                    let g = String(repeating: hex[hex.index(after: hex.startIndex)], count: 2)
                    let b = String(repeating: hex[hex.index(hex.startIndex, offsetBy: 2)], count: 2)
                    return Int(0xFF000000) |
                        (Int(r, radix: 16)! << 16) |
                        (Int(g, radix: 16)! << 8) |
                        Int(b, radix: 16)!
                case 4: // #ARGB
                    let a = String(repeating: hex[hex.startIndex], count: 2)
                    let r = String(repeating: hex[hex.index(after: hex.startIndex)], count: 2)
                    let g = String(repeating: hex[hex.index(hex.startIndex, offsetBy: 2)], count: 2)
                    let b = String(repeating: hex[hex.index(hex.startIndex, offsetBy: 3)], count: 2)
                    return (Int(a, radix: 16)! << 24) |
                        (Int(r, radix: 16)! << 16) |
                        (Int(g, radix: 16)! << 8) |
                        Int(b, radix: 16)!
                case 6: // #RRGGBB
                    return Int(0xFF000000) | Int(hex, radix: 16)!
                case 8: // #AARRGGBB
                    return Int(hex, radix: 16)!
                default:
                    fatalError("Unknown color format: \(colorString ?? "")")
                }
            } else if let namedColor = namedColors[str.lowercased()] {
                return namedColor
            } else {
                fatalError("Unknown color format: \(colorString ?? "")")
            }
        }()
        return colorInt
    }

    static func parseColor(_ colorInt: Int) -> Color {
        let a = (colorInt >> 24) & 0xFF
        let r = (colorInt >> 16) & 0xFF
        let g = (colorInt >> 8) & 0xFF
        let b = colorInt & 0xFF
        return Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0, opacity: Double(a) / 255.0)
    }
}
