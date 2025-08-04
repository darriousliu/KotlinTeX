import Foundation

class GlyphSlot: Pointer {
    var bitmap: Bitmap? {
        get {
            let bitmap = FreeType.glyphSlotGetBitmap1(pointer)
            if (bitmap == 0) {
                return nil
            }
            return Bitmap(bitmap)
        }
    }

    var linearHoriAdvance: Int {
        get {
            return FreeType.glyphSlotGetLinearHoriAdvance1(pointer)
        }
    }

    var linearVertAdvance: Int {
        get {
            return FreeType.glyphSlotGetLinearVertAdvance1(pointer)
        }
    }

    var advance: Advance {
        get {
            let array = FreeType.glyphSlotGetAdvance1(pointer)
            return Advance(x: array[0], y: array[1])
        }
    }

    var format: Int {
        get {
            return FreeType.glyphSlotGetFormat1(pointer)
        }
    }

    var bitmapLeft: Int {
        get {
            return FreeType.glyphSlotGetBitmapLeft1(pointer)
        }
    }

    var bitmapTop: Int {
        get {
            return FreeType.glyphSlotGetBitmapTop1(pointer)
        }
    }

    var metrics: GlyphMetrics? {
        get {
            let metrics = FreeType.glyphSlotGetMetrics1(pointer)
            if (metrics == 0) {
                return nil
            }
            return GlyphMetrics(metrics)
        }
    }

    func renderGlyph(renderMode: FreeTypeConstants.FT_Render_Mode) -> Bool {
        return FreeType.renderGlyph1(pointer, renderMode: Int32(renderMode.ordinal))
    }
}

class Advance: CustomStringConvertible {
    let x: Int
    let y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    var description: String {
        return "(\(x),\(y))"
    }
}
