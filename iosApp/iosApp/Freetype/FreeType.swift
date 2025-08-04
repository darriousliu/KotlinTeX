import Foundation

class FreeType {
    class func newLibrary() -> Library? {
        let library = initLibrary()
        if library == 0 {
            print("Failed to initialize FreeType2 library.")
            return nil
        }
        print("Successfully initialized FreeType2 library.\(library)")
        return Library(library)
    }


    class func doneFreeType1(_ library: Int) -> Bool {
        return doneFreeType(library)
    }

    class func libraryVersion1(_ library: Int) -> LibraryVersion {
        let intArray = libraryVersion(library)
        if let intArray = intArray {
            let major = intArray.advanced(by: 0).pointee
            let minor = intArray.advanced(by: 1).pointee
            let patch = intArray.advanced(by: 2).pointee
            free(intArray)
            return LibraryVersion(major: Int(major), minor: Int(minor), patch: Int(patch))
        } else {
            return LibraryVersion(major: 0, minor: 0, patch: 0)
        }
    }

    class func newMemoryFace1(
        _ library: Int,
        data: NativeBinaryBuffer?,
        length: Int32,
        faceIndex: Int
    ) -> Int {
        precondition(data != nil, "data.ptr is null")
        return data!.withPointer { pointer in
            return newMemoryFace(library, pointer.baseAddress?.assumingMemoryBound(to: Int8.self), length, faceIndex)
        }
    }

    class func loadMathTable1(_ face: Int, data: NativeBinaryBuffer?, length: Int) -> Bool {
        precondition(data != nil, "data.ptr is null")
        return data!.withPointer { pointer in
            return loadMathTable(face, pointer.baseAddress?.assumingMemoryBound(to: Int8.self), Int32(length))
        }
    }

    class func faceGetAscender1(_ face: Int) -> Int {
        return Int(faceGetAscender(face))
    }

    class func faceGetDescender1(_ face: Int) -> Int {
        return Int(faceGetDescender(face))
    }

    class func faceGetFaceFlags1(_ face: Int) -> Int {
        return faceGetFaceFlags(face)
    }

    class func faceGetFaceIndex1(_ face: Int) -> Int {
        return faceGetFaceIndex(face)
    }

    class func faceGetFamilyName1(_ face: Int) -> String {
        if let name = faceGetFamilyName(face) {
            return String(cString: name)
        } else {
            return ""
        }
    }

    class func faceGetHeight1(_ face: Int) -> Int {
        return Int(faceGetHeight(face))
    }

    class func faceGetMaxAdvanceHeight1(_ face: Int) -> Int {
        return Int(faceGetMaxAdvanceHeight(face))
    }

    class func faceGetMaxAdvanceWidth1(_ face: Int) -> Int {
        return Int(faceGetMaxAdvanceWidth(face))
    }

    class func faceGetNumFaces1(_ face: Int) -> Int {
        return faceGetNumFaces(face)
    }

    class func faceGetNumGlyphs1(_ face: Int) -> Int {
        return faceGetNumGlyphs(face)
    }

    class func faceGetStyleFlags1(_ face: Int) -> Int {
        return faceGetStyleFlags(face)
    }

    class func faceGetStyleName1(_ face: Int) -> String {
        if let name = faceGetStyleName(face) {
            return String(cString: name)
        } else {
            return ""
        }
    }

    class func faceGetUnderlinePosition1(_ face: Int) -> Int {
        return Int(faceGetUnderlinePosition(face))
    }

    class func faceGetUnderlineThickness1(_ face: Int) -> Int {
        return Int(faceGetUnderlineThickness(face))
    }

    class func faceGetUnitsPerEM1(_ face: Int) -> Int {
        return Int(faceGetUnitsPerEM(face))
    }

    class func faceGetGlyph1(_ face: Int) -> Int {
        return faceGetGlyph(face)
    }

    class func faceGetSize1(_ face: Int) -> Int {
        return faceGetSize(face)
    }

    class func getTrackKerning1(
        _ face: Int,
        pointSize: Int,
        degree: Int
    ) -> Int {
        return getTrackKerning(face, Int32(pointSize), Int32(degree))
    }

    class func getKerning1(
        _ face: Int,
        left: Character,
        right: Character,
        mode: Int32
    ) -> Kerning {
        if let longArray = getKerning(face, Int32(left.asciiValue ?? 0), Int32(right.asciiValue ?? 0), mode) {
            let horizontalKerning = Int(longArray.advanced(by: 0).pointee)
            let verticalKerning = Int(longArray.advanced(by: 1).pointee)
            free(longArray)
            return Kerning(horizontalKerning: horizontalKerning, verticalKerning: verticalKerning)
        } else {
            return Kerning(horizontalKerning: 0, verticalKerning: 0)
        }
    }

    class func doneFace1(_ face: Int) -> Bool {
        return doneFace(face)
    }

    class func referenceFace1(_ face: Int) -> Bool {
        return referenceFace(face)
    }

    class func hasKerning1(_ face: Int) -> Bool {
        return hasKerning(face)
    }

    class func getPostscriptName1(_ face: Int) -> String {
        let face = UnsafeMutablePointer<FT_Face>(bitPattern: face)?.pointee
        if let name = FT_Get_Postscript_Name(face) {
            return String(cString: name)
        } else {
            return ""
        }
    }

    class func selectCharMap1(_ face: Int, encoding: Int32) -> Bool {
        return selectCharMap(face, encoding)
    }

    class func setCharMap1(
        _ face: Int,
        charMap: CharMap
    ) -> Bool {
        return setCharMap(face, charMap.pointer)
    }

    class func faceCheckTrueTypePatents1(_ face: Int) -> Bool {
        return faceCheckTrueTypePatents(face)
    }

    class func faceSetUnpatentedHinting1(
        _ face: Int,
        value: Bool
    ) -> Bool {
        return faceSetUnpatentedHinting(face, value)
    }

    class func getFirstChar1(_ face: Int) -> [Int] {
        if let uLongArray = getFirstChar(face) {
            let firstChar = Int(uLongArray.advanced(by: 0).pointee)
            let firstGlyphIndex = Int(uLongArray.advanced(by: 1).pointee)
            free(uLongArray)
            return [firstChar, firstGlyphIndex]
        } else {
            return [0, 0]
        }
    }

    class func getNextChar1(_ face: Int, charcode: Int) -> Int {
        return Int(getNextChar(face, charcode))
    }

    class func getCharIndex1(_ face: Int, code: Int32) -> Int {
        return Int(getCharIndex(face, code))
    }

    class func getNameIndex1(_ face: Int, name: String) -> Int {
        return Int(getNameIndex(face, name))
    }

    class func getGlyphName1(_ face: Int, glyphIndex: Int32) -> String {
        let face = UnsafeMutablePointer<FT_Face>(bitPattern: face)?.pointee
        let nameBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: 100) // 分配100字节缓冲区
        // 调用C函数
        FT_Get_Glyph_Name(face, UInt32(glyphIndex), nameBuffer, 100)
        // 转换为Swift字符串
        let glyphName = String(cString: nameBuffer)
        nameBuffer.deallocate()
        return glyphName
    }

    class func getFSTypeFlags1(_ face: Int) -> Int16 {
        return Int16(getFSTypeFlags(face))
    }

    class func selectSize1(_ face: Int, strikeIndex: Int) -> Bool {
        return selectSize(face, Int32(strikeIndex))
    }

    class func loadChar1(_ face: Int, c: Character, flags: Int) -> Bool {
        return loadChar(face, Int32(c.asciiValue!), Int32(flags))
    }

    class func requestSize1(_ face: Int, sizeRequest: SizeRequest) -> Bool {
        return requestSize(
            face,
            Int32(sizeRequest.width),
            Int32(sizeRequest.height),
            Int32(sizeRequest.horiResolution),
            Int32(sizeRequest.vertResolution),
            Int32(sizeRequest.getType()?.ordinal ?? 0)
        )
    }

    class func setPixelSizes1(_ face: Int, width: Int, height: Int) -> Bool {
        return setPixelSizes(face, Int32(width), Int32(height))
    }

    class func loadGlyph1(_ face: Int, glyphIndex: Int, loadFlags: Int) -> Bool {
        return loadGlyph(face, Int32(glyphIndex), Int32(loadFlags))
    }

    class func setCharSize1(_ face: Int, charWidth: Int, charHeight: Int, horizResolution: Int, vertResolution: Int) -> Bool {
//        let face = UnsafeMutablePointer<FT_Face>(bitPattern: face)?.pointee
//        return FT_Set_Char_Size(face, charWidth, charHeight, FT_UInt(horizResolution), FT_UInt(vertResolution))==0
        return setCharSize(face, Int32(charWidth), Int32(charHeight), Int32(horizResolution), Int32(vertResolution))
    }

    class func sizeGetMetrics1(_ size: Int) -> Int {
        return sizeGetMetrics(size)
    }

    class func sizeMetricsGetAscender1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetAscender(sizeMetrics)
    }

    class func sizeMetricsGetDescender1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetDescender(sizeMetrics)
    }

    class func sizeMetricsGetHeight1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetHeight(sizeMetrics)
    }

    class func sizeMetricsGetMaxAdvance1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetMaxAdvance(sizeMetrics)
    }

    class func sizeMetricsGetXPPEM1(_ sizeMetrics: Int) -> Int {
        return Int(sizeMetricsGetXPPEM(sizeMetrics))
    }

    class func sizeMetricsGetXScale1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetXScale(sizeMetrics)
    }

    class func sizeMetricsGetYPPEM1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetYPPEM(sizeMetrics)
    }

    class func sizeMetricsGetYScale1(_ sizeMetrics: Int) -> Int {
        return sizeMetricsGetYScale(sizeMetrics)
    }

    class func glyphSlotGetLinearHoriAdvance1(_ glyphSlot: Int) -> Int {
        return glyphSlotGetLinearHoriAdvance(glyphSlot)
    }

    class func glyphSlotGetLinearVertAdvance1(_ glyphSlot: Int) -> Int {
        return glyphSlotGetLinearVertAdvance(glyphSlot)
    }

    class func glyphSlotGetAdvance1(_ glyphSlot: Int) -> [Int] {
        if let longArray = glyphSlotGetAdvance(glyphSlot) {
            defer {
                free(longArray)
            }
            return [longArray[0], longArray[1]]
        } else {
            return [0, 0]
        }
    }

    class func glyphSlotGetFormat1(_ glyphSlot: Int) -> Int {
        return Int(glyphSlotGetFormat(glyphSlot))
    }

    class func glyphSlotGetBitmapLeft1(_ glyphSlot: Int) -> Int {
        return Int(glyphSlotGetBitmapLeft(glyphSlot))
    }

    class func glyphSlotGetBitmapTop1(_ glyphSlot: Int) -> Int {
        return Int(glyphSlotGetBitmapTop(glyphSlot))
    }

    class func glyphSlotGetBitmap1(_ glyphSlot: Int) -> Int {
        return glyphSlotGetBitmap(glyphSlot)
    }

    class func glyphSlotGetMetrics1(_ glyphSlot: Int) -> Int {
        return glyphSlotGetMetrics(glyphSlot)
    }

    class func renderGlyph1(_ glyphSlot: Int, renderMode: Int32) -> Bool {
        return renderGlyph(glyphSlot, renderMode)
    }

    class func glyphMetricsGetWidth1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetWidth(glyphMetrics)
    }

    class func glyphMetricsGetHeight1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetHeight(glyphMetrics)
    }

    class func glyphMetricsGetHoriAdvance1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetHoriAdvance(glyphMetrics)
    }

    class func glyphMetricsGetVertAdvance1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetVertAdvance(glyphMetrics)
    }

    class func glyphMetricsGetHoriBearingX1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetHoriBearingX(glyphMetrics)
    }

    class func glyphMetricsGetHoriBearingY1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetHoriBearingY(glyphMetrics)
    }

    class func glyphMetricsGetVertBearingX1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetVertBearingX(glyphMetrics)
    }

    class func glyphMetricsGetVertBearingY1(_ glyphMetrics: Int) -> Int {
        return glyphMetricsGetVertBearingY(glyphMetrics)
    }

    class func bitmapGetWidth1(_ bitmap: Int) -> Int {
        return Int(bitmapGetWidth(bitmap))
    }

    class func bitmapGetRows1(_ bitmap: Int) -> Int {
        return Int(bitmapGetRows(bitmap))
    }

    class func bitmapGetPitch1(_ bitmap: Int) -> Int {
        return Int(bitmapGetPitch(bitmap))
    }

    class func bitmapGetNumGrays1(_ bitmap: Int) -> Int16 {
        return Int16(bitmapGetNumGrays(bitmap))
    }

    class func bitmapGetPaletteMode1(_ bitmap: Int) -> Character {
        return Character(UnicodeScalar(Int(bitmapGetPaletteMode(bitmap)))!)
    }

    class func bitmapGetPixelMode1(_ bitmap: Int) -> Character {
        return Character(UnicodeScalar(Int(bitmapGetPixelMode(bitmap)))!)
    }

    class func bitmapGetBuffer1(_ bitmap: Int) -> NativeBinaryBuffer {
        let array = bitmapGetBuffer(bitmap)
        return array.ptr.withMemoryRebound(to: UInt8.self, capacity: Int(array.length)) { buffer in
            NativeBinaryBuffer(data: Data(bytes: buffer, count: Int(array.length)))
        }
    }

    class func getCharMapIndex1(_ charMap: Int) -> Int {
        return Int(getCharMapIndex(charMap))
    }

    class func newBuffer(size: Int) -> NativeBinaryBuffer {
        return NativeBinaryBuffer(size: size)
    }
    
    class func deleteBuffer(_ data: NativeBinaryBuffer) {
        
    }
}
