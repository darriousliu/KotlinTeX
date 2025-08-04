import Foundation

struct MTGlyphPart {
    var glyph: Int = 0
    var fullAdvance: Float = 0.0
    var startConnectorLength: Float = 0.0
    var endConnectorLength: Float = 0.0
    var isExtender: Bool = false
}

struct BoundingBox {
    var lowerLeftX: Float = 0.0
    var lowerLeftY: Float = 0.0
    var upperRightX: Float = 0.0
    var upperRightY: Float = 0.0
    
    var width: Float { upperRightX - lowerLeftX }
    var height: Float { upperRightY - lowerLeftY }
    
    init() {}
    
    init(minX: Float, minY: Float, maxX: Float, maxY: Float) {
        lowerLeftX = minX
        lowerLeftY = minY
        upperRightX = maxX
        upperRightY = maxY
    }
    
    init(numbers: [Float]) {
        lowerLeftX = numbers[0]
        lowerLeftY = numbers[1]
        upperRightX = numbers[2]
        upperRightY = numbers[3]
    }
    
    func contains(x: Float, y: Float) -> Bool {
        return x >= lowerLeftX && x <= upperRightX && y >= lowerLeftY && y <= upperRightY
    }
}

class MTFontMathTable {
    var font: MTFont
    var unitsPerEm: Int = 1
    var fontSize: Float = 0.0
    var freeFace: Face!  // 假设 Face 是 FreeType 类型
    var freeTypeMathTable: MTFreeTypeMathTable!  // 假设已定义

    init(font: MTFont, fontPath: String? = nil) throws {
        self.font = font
        fontSize = font.fontSize
        
        if let path = fontPath {
            print("Loading math table from \(path)")
            /* --- Init FreeType --- */
            /* get singleton */
            guard let library = FreeType.newLibrary() else {
                throw MathDisplayException("Error initializing FreeType.")
            }
            print("FreeType library version: \(library.version)")

            freeFace = library.newFace(file: path, faceIndex: 0)!
            print("FreeType face loaded: \(freeFace.familyName) (\(freeFace.faceIndex))")
            checkFontSize()
            unitsPerEm = freeFace.unitsPerEM

            freeTypeMathTable = freeFace.loadMathTable()
        }
    }

    func checkFontSize() -> Face {
        freeFace.setCharSize(charWidth: 0, charHeight: Int(fontSize * 64), horiResolution: 0, vertResolution: 0)
        return freeFace
    }

    // Lightweight copy
    func copyFontTableWithSize(size: Float) -> MTFontMathTable {
        let copyTable = try! MTFontMathTable(font: font, fontPath: nil)
        copyTable.fontSize = size
        copyTable.unitsPerEm = self.unitsPerEm
        copyTable.freeFace = self.freeFace
        copyTable.freeTypeMathTable = self.freeTypeMathTable

        return copyTable
    }

    func getGlyphName(gid: Int) -> String {
        let g = self.freeFace.getGlyphName(glyphIndex: gid)
        return g
    }

    func getGlyphWithName(glyphName: String) -> Int {
        let g = self.freeFace.getGlyphIndexByName(glyphName)
        return g
    }

    func getGlyphForCodepoint(codepoint: Int) -> Int {
        let g = self.freeFace.getCharIndex(codepoint)
        return g
    }

    func getAdvancesForGlyphs(glyphs: [Int], advances: inout [Float], count: Int) {
        for i in 0..<count {
            if !freeFace.loadGlyph(glyphIndex: glyphs[i], flags: FT_LOAD_NO_SCALE) {
                if let glyphSlot = freeFace.glyphSlot {
                    let advance = glyphSlot.advance
                    advances[i] = fontUnitsToPt(fontUnits: advance.x)
                }
            }
        }
    }

    func unionBounds(u: inout BoundingBox, b: BoundingBox) {
        u.lowerLeftX = min(u.lowerLeftX, b.lowerLeftX)
        u.lowerLeftY = min(u.lowerLeftY, b.lowerLeftY)
        u.upperRightX = max(u.upperRightX, b.upperRightX)
        u.upperRightY = max(u.upperRightY, b.upperRightY)
    }

    //  Good description and picture
    // https://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
    func getBoundingRectsForGlyphs(
        glyphs: [Int],
        boundingRects: inout [BoundingBox?]?,
        count: Int
    ) -> BoundingBox {
        var enclosing: BoundingBox = .init()

        for i in 0..<count {
            if !freeFace.loadGlyph(glyphIndex: glyphs[i], flags: FT_LOAD_NO_SCALE) {
                var nb = BoundingBox()
                if let glyphSlot = freeFace.glyphSlot, let metrics = glyphSlot.metrics {
                    let w = fontUnitsToPt(fontUnits: metrics.width)
                    let h = fontUnitsToPt(fontUnits: metrics.height)
                    //let HoriAdvance = fontUnitsToPt(metrics.getHoriAdvance())
                    //let VertAdvance = fontUnitsToPt(metrics.getVertAdvance())
                    let horiBearingX = fontUnitsToPt(fontUnits: metrics.horiBearingX)
                    let horiBearingY = fontUnitsToPt(fontUnits: metrics.horiBearingY)
                    //let VertBearingX = fontUnitsToPt(metrics.getVertBearingX())
                    //let VertBearingY = fontUnitsToPt(metrics.getVertBearingY())
                    //print("\(a) \(metrics) \(w) \(h) \(HoriAdvance) \(VertAdvance) \(horiBearingX) \(horiBearingY) \(VertBearingX) \(VertBearingY)")
                    nb.lowerLeftX = horiBearingX
                    nb.lowerLeftY = horiBearingY - h
                    nb.upperRightX = horiBearingX + w
                    nb.upperRightY = horiBearingY
                    //print("nb \(nb)")
                }

                unionBounds(u: &enclosing, b: nb)
                if var boundingRects = boundingRects {
                    boundingRects[i] = nb
                }
            }
        }
        return enclosing
    }

    private func fontUnitsToPt(fontUnits: Int64) -> Float {
        return Float(fontUnits) * fontSize / Float(unitsPerEm)
    }

    private func fontUnitsToPt(fontUnits: Int) -> Float {
        return Float(fontUnits) * fontSize / Float(unitsPerEm)
    }

    func fontUnitsBox(b: BoundingBox) -> BoundingBox {
        var rb = BoundingBox()
        rb.lowerLeftX = fontUnitsToPt(fontUnits: Int(b.lowerLeftX))
        rb.lowerLeftY = fontUnitsToPt(fontUnits: Int(b.lowerLeftY))
        rb.upperRightX = fontUnitsToPt(fontUnits: Int(b.upperRightX))
        rb.upperRightY = fontUnitsToPt(fontUnits: Int(b.upperRightY))
        return rb
    }

    func muUnit() -> Float {
        return fontSize / 18
    }

    func constantFromTable(constName: String) -> Float {
        return fontUnitsToPt(fontUnits: freeTypeMathTable.getConstant(name: constName))
    }

    func percentFromTable(percentName: String) -> Float {
        return Float(freeTypeMathTable.getConstant(name: percentName)) / 100.0
    }

    var fractionNumeratorDisplayStyleShiftUp: Float {
        return constantFromTable(constName: "FractionNumeratorDisplayStyleShiftUp")
    }

    var fractionNumeratorShiftUp: Float {
        return constantFromTable(constName: "FractionNumeratorShiftUp")
    }

    var fractionDenominatorDisplayStyleShiftDown: Float {
        return constantFromTable(constName: "FractionDenominatorDisplayStyleShiftDown")
    }

    var fractionDenominatorShiftDown: Float {
        return constantFromTable(constName: "FractionDenominatorShiftDown")
    }

    var fractionNumeratorDisplayStyleGapMin: Float {
        return constantFromTable(constName: "FractionNumDisplayStyleGapMin")
    }

    var fractionNumeratorGapMin: Float {
        return constantFromTable(constName: "FractionNumeratorGapMin")
    }

    var fractionDenominatorDisplayStyleGapMin: Float {
        return constantFromTable(constName: "FractionDenomDisplayStyleGapMin")
    }

    var fractionDenominatorGapMin: Float {
        return constantFromTable(constName: "FractionDenominatorGapMin")
    }

    var fractionRuleThickness: Float {
        return constantFromTable(constName: "FractionRuleThickness")
    }

    var skewedFractionHorizontalGap: Float {
        return constantFromTable(constName: "SkewedFractionHorizontalGap")
    }

    var skewedFractionVerticalGap: Float {
        return constantFromTable(constName: "SkewedFractionVerticalGap")
    }

    // FractionDelimiterSize and FractionDelimiterDisplayStyleSize are not constants
    // specified in the OpenType Math specification. Rather these are proposed LuaTeX extensions
    // for the TeX parameters \sigma_20 (delim1) and \sigma_21 (delim2). Since these do not
    // exist in the fonts that we have, we use the same approach as LuaTeX and use the fontSize
    // to determine these values. The constants used are the same as LuaTeX and KaTeX and match the
    // metrics values of the original TeX fonts.
    // Note: An alternative approach is to use DelimitedSubFormulaMinHeight for \sigma21 and use a factor
    // of 2 to get \sigma 20 as proposed in Vieth paper.
    // The XeTeX implementation sets \sigma21 = fontSize and \sigma20 = DelimitedSubFormulaMinHeight which
    // will produce smaller delimiters.
    // Of all the approaches we've implemented LuaTeX's approach since it mimics LaTeX most accurately.
    var fractionDelimiterSize: Float {
        return 1.01 * fontSize
    }

    var fractionDelimiterDisplayStyleSize: Float {
        // Modified constant from 2.4 to 2.39, it matches KaTeX and looks better.
        return 2.39 * fontSize
    }

    // Sub/Superscripts
    var superscriptShiftUp: Float {
        return constantFromTable(constName: "SuperscriptShiftUp")
    }

    var superscriptShiftUpCramped: Float {
        return constantFromTable(constName: "SuperscriptShiftUpCramped")
    }

    var subscriptShiftDown: Float {
        return constantFromTable(constName: "SubscriptShiftDown")
    }

    var superscriptBaselineDropMax: Float {
        return constantFromTable(constName: "SuperscriptBaselineDropMax")
    }

    var subscriptBaselineDropMin: Float {
        return constantFromTable(constName: "SubscriptBaselineDropMin")
    }

    var superscriptBottomMin: Float {
        return constantFromTable(constName: "SuperscriptBottomMin")
    }

    var subscriptTopMax: Float {
        return constantFromTable(constName: "SubscriptTopMax")
    }

    var subSuperscriptGapMin: Float {
        return constantFromTable(constName: "SubSuperscriptGapMin")
    }

    var superscriptBottomMaxWithSubscript: Float {
        return constantFromTable(constName: "SuperscriptBottomMaxWithSubscript")
    }

    var spaceAfterScript: Float {
        return constantFromTable(constName: "SpaceAfterScript")
    }

    var radicalRuleThickness: Float {
        return constantFromTable(constName: "RadicalRuleThickness")
    }

    var radicalExtraAscender: Float {
        return constantFromTable(constName: "RadicalExtraAscender")
    }

    var radicalVerticalGap: Float {
        return constantFromTable(constName: "RadicalVerticalGap")
    }

    var radicalDisplayStyleVerticalGap: Float {
        return constantFromTable(constName: "RadicalDisplayStyleVerticalGap")
    }

    var radicalKernBeforeDegree: Float {
        return constantFromTable(constName: "RadicalKernBeforeDegree")
    }

    var radicalKernAfterDegree: Float {
        return constantFromTable(constName: "RadicalKernAfterDegree")
    }

    var radicalDegreeBottomRaisePercent: Float {
        return percentFromTable(percentName: "RadicalDegreeBottomRaisePercent")
    }

    // Limits
    var upperLimitGapMin: Float {
        return constantFromTable(constName: "UpperLimitGapMin")
    }

    var upperLimitBaselineRiseMin: Float {
        return constantFromTable(constName: "UpperLimitBaselineRiseMin")
    }

    var lowerLimitGapMin: Float {
        return constantFromTable(constName: "LowerLimitGapMin")
    }

    var lowerLimitBaselineDropMin: Float {
        return constantFromTable(constName: "LowerLimitBaselineDropMin")
    }

    // not present in OpenType fonts.
    var limitExtraAscenderDescender: Float {
        return 0.0
    }

    // Constants
    var axisHeight: Float {
        return constantFromTable(constName: "AxisHeight")
    }

    var scriptScaleDown: Float {
        return percentFromTable(percentName: "ScriptPercentScaleDown")
    }

    var scriptScriptScaleDown: Float {
        return percentFromTable(percentName: "ScriptScriptPercentScaleDown")
    }

    var mathLeading: Float {
        return constantFromTable(constName: "MathLeading")
    }

    var delimitedSubFormulaMinHeight: Float {
        return constantFromTable(constName: "DelimitedSubFormulaMinHeight")
    }

    // Accents
    var accentBaseHeight: Float {
        return constantFromTable(constName: "AccentBaseHeight")
    }

    var flattenedAccentBaseHeight: Float {
        return constantFromTable(constName: "FlattenedAccentBaseHeight")
    }

    // Large Operators
    var displayOperatorMinHeight: Float {
        return constantFromTable(constName: "DisplayOperatorMinHeight")
    }

    // Over and Underbar
    var overbarExtraAscender: Float {
        return constantFromTable(constName: "OverbarExtraAscender")
    }

    var overbarRuleThickness: Float {
        return constantFromTable(constName: "OverbarRuleThickness")
    }

    var overbarVerticalGap: Float {
        return constantFromTable(constName: "OverbarVerticalGap")
    }

    var underbarExtraDescender: Float {
        return constantFromTable(constName: "UnderbarExtraDescender")
    }

    var underbarRuleThickness: Float {
        return constantFromTable(constName: "UnderbarRuleThickness")
    }

    var underbarVerticalGap: Float {
        return constantFromTable(constName: "UnderbarVerticalGap")
    }

    // Stacks
    var stackBottomDisplayStyleShiftDown: Float {
        return constantFromTable(constName: "StackBottomDisplayStyleShiftDown")
    }

    var stackBottomShiftDown: Float {
        return constantFromTable(constName: "StackBottomShiftDown")
    }

    var stackDisplayStyleGapMin: Float {
        return constantFromTable(constName: "StackDisplayStyleGapMin")
    }

    var stackGapMin: Float {
        return constantFromTable(constName: "StackGapMin")
    }

    var stackTopDisplayStyleShiftUp: Float {
        return constantFromTable(constName: "StackTopDisplayStyleShiftUp")
    }

    var stackTopShiftUp: Float {
        return constantFromTable(constName: "StackTopShiftUp")
    }

    var stretchStackBottomShiftDown: Float {
        return constantFromTable(constName: "StretchStackBottomShiftDown")
    }

    var stretchStackGapAboveMin: Float {
        return constantFromTable(constName: "StretchStackGapAboveMin")
    }

    var stretchStackGapBelowMin: Float {
        return constantFromTable(constName: "StretchStackGapBelowMin")
    }

    var stretchStackTopShiftUp: Float {
        return constantFromTable(constName: "StretchStackTopShiftUp")
    }

    // Variants
    func getVerticalVariantsForGlyph(glyph: CGGlyph) -> [Int] {
        return freeTypeMathTable.getVerticalVariantsForGlyph(gid: glyph.gid)
    }

    func getHorizontalVariantsForGlyph(glyph: CGGlyph) -> [Int] {
        return freeTypeMathTable.getHorizontalVariantsForGlyph(gid: glyph.gid)
    }

    func getLargerGlyph(glyph: Int) -> Int {
        let glyphName = font.getGlyphName(gid: glyph)
        // Find the first variant with a different name.
        let variantGlyphs = freeTypeMathTable.getVerticalVariantsForGlyph(gid: glyph)
        for vGlyph in variantGlyphs {
            let vName = font.getGlyphName(gid: vGlyph)
            if vName != glyphName {
                return font.getGlyphWithName(glyphName: vName)
            }
        }
        // We did not find any variants of this glyph so return it.
        return glyph
    }

    // Italic Correction
    func getItalicCorrection(gid: Int) -> Float {
        return fontUnitsToPt(fontUnits: freeTypeMathTable.getItalicCorrection(gid: gid))
    }

    // Top Accent Adjustment
    func getTopAccentAdjustment(glyph: Int) -> Float {
        if let value = freeTypeMathTable.getTopAccentAttachment(gid: glyph) {
            return fontUnitsToPt(fontUnits: value)
        } else {
            // testWideAccent test case covers this

            // If no top accent is defined then it is the center of the advance width.
            let glyphs = [glyph]
            var advances: [Float] = [0.0]

            getAdvancesForGlyphs(glyphs: glyphs, advances: &advances, count: 1)
            return advances[0] / 2
        }
    }

// Glyph Assembly
    var minConnectorOverlap: Float {
        return fontUnitsToPt(fontUnits: freeTypeMathTable.minConnectorOverlap)
    }

    func getVerticalGlyphAssemblyForGlyph(glyph: Int) -> [MTGlyphPart]? {
        guard let assemblyInfo = freeTypeMathTable.getVerticalGlyphAssemblyForGlyph(gid: glyph) else {
            // No vertical assembly defined for glyph
            return nil
        }

        var rv = [MTGlyphPart]()
        for pi in assemblyInfo {
            var part = MTGlyphPart()
            part.fullAdvance = fontUnitsToPt(fontUnits: pi.fullAdvance)
            part.endConnectorLength = fontUnitsToPt(fontUnits: pi.endConnectorLength)
            part.startConnectorLength = fontUnitsToPt(fontUnits: pi.startConnectorLength)
            part.isExtender = pi.partFlags == 1
            part.glyph = Int(pi.glyph)
            rv.append(part)
        }

        return rv
    }
}
