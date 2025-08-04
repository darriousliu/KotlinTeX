


class GlyphMetrics: Pointer {
    var width: Int {
        FreeType.glyphMetricsGetWidth1(pointer)
    }

    var height: Int {
        FreeType.glyphMetricsGetHeight1(pointer)
    }

    var horiAdvance: Int {
        FreeType.glyphMetricsGetHoriAdvance1(pointer)
    }

    var vertAdvance: Int {
        FreeType.glyphMetricsGetVertAdvance1(pointer)
    }

    var horiBearingX: Int {
        FreeType.glyphMetricsGetHoriBearingX1(pointer)
    }

    var horiBearingY: Int {
        FreeType.glyphMetricsGetHoriBearingY1(pointer)
    }

    var vertBearingX: Int {
        FreeType.glyphMetricsGetVertBearingX1(pointer)
    }

    var vertBearingY: Int {
        FreeType.glyphMetricsGetVertBearingY1(pointer)
    }
}
