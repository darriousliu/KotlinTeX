import Foundation

class MTFont {
    let name: String
    let fontSize: Float
    var mathTable: MTFontMathTable!

    init(name: String, fontSize: Float, isCopy: Bool = false) {
        self.name = name
        self.fontSize = fontSize

        let fontPath = "compose-resources/composeResources/io.github.darriousliu.katex.core.resources/files/fonts/\(name).otf"

        if !isCopy {
            mathTable = try! MTFontMathTable(font: self, fontPath: fontPath)
        }
    }

    func findGlyphForCharacterAtIndex(index: Int, str: String) -> CGGlyph {
        // Do we need to check with our font to see if this glyph is in the font?
        let codepoint = Utils.codePointAt(sequence: Array(str), index: index)
        let gid = mathTable.getGlyphForCodepoint(codepoint: codepoint)
        return CGGlyph(gid: gid)
    }

    func getGidListForString(str: String) -> [Int] {
        let ca = Array(str)
        var ret: [Int] = []

        var i = 0
        while i < ca.count {
            let codepoint = Utils.codePointAt(sequence: ca, index: i)
            i += Utils.charCount(codePoint: codepoint)
            let gid = mathTable.getGlyphForCodepoint(codepoint: codepoint)
            if gid == 0 {
                print("getGidListForString codepoint \(codepoint) mapped to missing glyph")
            }
            ret.append(gid)
        }
        return ret
    }

    func copyFontWithSize(size: Float) -> MTFont {
        let copyFont = MTFont(name: self.name, fontSize: size, isCopy: true)
        copyFont.mathTable = self.mathTable.copyFontTableWithSize(size: size)
        return copyFont
    }

    func getGlyphName(gid: Int) -> String {
        return mathTable.getGlyphName(gid: gid)
    }

    func getGlyphWithName(glyphName: String) -> Int {
        return mathTable.getGlyphWithName(glyphName: glyphName)
    }
}

