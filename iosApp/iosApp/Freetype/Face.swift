import Foundation

class Face: Pointer {
    private var data: NativeBinaryBuffer?

    init(pointer: Int, data: NativeBinaryBuffer? = nil) {
        self.data = data
        super.init(pointer)
    }

    func delete() -> Bool {
        if let data = data {
            FreeType.deleteBuffer(data)
        }
        return FreeType.doneFace1(pointer)
    }

    func loadMathTable() -> MTFreeTypeMathTable {
        // Temporary buffer size of font.
        let buffer = FreeType.newBuffer(size: data!.remaining())
        let fm = MTFreeTypeMathTable(pointer: pointer, data: buffer)
        FreeType.deleteBuffer(buffer)
        return fm
    }

    var ascender: Int {
        return FreeType.faceGetAscender1(pointer)
    }

    var descender: Int {
        return FreeType.faceGetDescender1(pointer)
    }

    var faceFlags: Int {
        return FreeType.faceGetFaceFlags1(pointer)
    }

    var faceIndex: Int {
        return FreeType.faceGetFaceIndex1(pointer)
    }

    var familyName: String {
        return FreeType.faceGetFamilyName1(pointer)
    }

    var height: Int {
        return FreeType.faceGetHeight1(pointer)
    }

    var maxAdvanceHeight: Int {
        return FreeType.faceGetMaxAdvanceHeight1(pointer)
    }

    var maxAdvanceWidth: Int {
        return FreeType.faceGetMaxAdvanceWidth1(pointer)
    }

    var numFaces: Int {
        return FreeType.faceGetNumFaces1(pointer)
    }

    var numGlyphs: Int {
        return FreeType.faceGetNumGlyphs1(pointer)
    }

    var styleFlags: Int {
        return FreeType.faceGetStyleFlags1(pointer)
    }

    var styleName: String {
        return FreeType.faceGetStyleName1(pointer)
    }

    var underlinePosition: Int {
        return FreeType.faceGetUnderlinePosition1(pointer)
    }

    var underlineThickness: Int {
        return FreeType.faceGetUnderlineThickness1(pointer)
    }

    var unitsPerEM: Int {
        return FreeType.faceGetUnitsPerEM1(pointer)
    }

    func getCharIndex(_ code: Int) -> Int {
        return FreeType.getCharIndex1(pointer, code: Int32(code))
    }

    func hasKerning() -> Bool {
        return FreeType.hasKerning1(pointer)
    }

    func selectSize(_ strikeIndex: Int) -> Bool {
        return FreeType.selectSize1(pointer, strikeIndex: strikeIndex)
    }

    func setCharSize(charWidth: Int, charHeight: Int, horiResolution: Int, vertResolution: Int) -> Bool {
        return FreeType.setCharSize1(pointer,
                                    charWidth: charWidth,
                                    charHeight: charHeight,
                                     horizResolution: horiResolution,
                                    vertResolution: vertResolution)
    }

    func loadGlyph(glyphIndex: Int, flags: Int) -> Bool {
        return FreeType.loadGlyph1(pointer, glyphIndex: glyphIndex, loadFlags: flags)
    }

    func loadChar(_ c: Character, flags: Int) -> Bool {
        return FreeType.loadChar1(pointer, c: c, flags: flags)
    }

    func getKerning(left: Character, right: Character) -> Kerning {
        return getKerning(left: left, right: right, mode: .FT_KERNING_DEFAULT)
    }

    func getKerning(left: Character, right: Character, mode: FreeTypeConstants.FT_Kerning_Mode) -> Kerning {
        return FreeType.getKerning1(pointer, left: left, right: right, mode: Int32(mode.ordinal))
    }

    func setPixelSizes(width: Float, height: Float) -> Bool {
        return FreeType.setPixelSizes1(pointer, width: Int(width), height: Int(height))
    }

    var glyphSlot: GlyphSlot? {
        let glyph = FreeType.faceGetGlyph1(pointer)
        if glyph == 0 {
            return nil
        }
        return GlyphSlot(glyph)
    }

    var size: Size? {
        let sizePointer = FreeType.faceGetSize1(pointer)
        if sizePointer == 0 {
            return nil
        }
        return Size(sizePointer)
    }

    func checkTrueTypePatents() -> Bool {
        return FreeType.faceCheckTrueTypePatents1(pointer)
    }

    func setUnpatentedHinting(_ newValue: Bool) -> Bool {
        return FreeType.faceSetUnpatentedHinting1(pointer, value: newValue)
    }

    func referenceFace() -> Bool {
        return FreeType.referenceFace1(pointer)
    }

    func requestSize(sr: SizeRequest) -> Bool {
        return FreeType.requestSize1(pointer, sizeRequest: sr)
    }

    var firstChar: [Int] {
        return FreeType.getFirstChar1(pointer)
    }

    var firstCharAsCharcode: Int {
        return firstChar[0]
    }

    var firstCharAsGlyphIndex: Int {
        return firstChar[1]
    }

    func getNextChar(charcode: Int) -> Int { // I will not create getNextCharAsCharcode to do charcode++.
        return FreeType.getNextChar1(pointer, charcode: charcode)
    }

    func getGlyphIndexByName(_ name: String) -> Int {
        return FreeType.getNameIndex1(pointer, name: name)
    }

    func getTrackKerning(pointSize: Int, degree: Int) -> Int {
        return FreeType.getTrackKerning1(pointer, pointSize: pointSize, degree: degree)
    }

    func getGlyphName(glyphIndex: Int) -> String {
        return FreeType.getGlyphName1(pointer, glyphIndex: Int32(glyphIndex))
    }

    var postscriptName: String {
        return FreeType.getPostscriptName1(pointer)
    }

    func selectCharMap(encoding: Int) -> Bool {
        return FreeType.selectCharMap1(pointer, encoding: Int32(encoding))
    }

    func setCharMap(_ charMap: CharMap) -> Bool {
        return FreeType.setCharMap1(pointer, charMap: charMap)
    }

    var fSTypeFlags: Int16 {
        return FreeType.getFSTypeFlags1(pointer)
    }
}
