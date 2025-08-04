import SwiftUI

let kDefaultFontSize: Float = 20.0

class MTFontManager {
    private static var nameToFontMap: [String: MTFont] = [:]

    static func font(withName name: String, size: Float) -> MTFont {
        if let existingFont = nameToFontMap[name] {
            if existingFont.fontSize == size {
                return existingFont
            } else {
                return existingFont.copyFontWithSize(size: size)
            }
        } else {
            let newFont = MTFont(name: name, fontSize: size)
            nameToFontMap[name] = newFont
            return newFont
        }
    }

    static func latinModernFont(withSize size: Float) -> MTFont {
        return font(withName: "latinmodern-math", size: size)
    }

    static func xitsFont(withSize size: Float) -> MTFont {
        return font(withName: "xits-math", size: size)
    }

    static func termesFont(withSize size: Float) -> MTFont {
        return font(withName: "texgyretermes-math", size: size)
    }

    static func defaultFont() -> MTFont {
        return latinModernFont(withSize: kDefaultFontSize)
    }
}
