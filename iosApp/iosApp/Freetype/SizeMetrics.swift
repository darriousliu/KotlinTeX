


class SizeMetrics: Pointer {
    var ascender: Int {
        return FreeType.sizeMetricsGetAscender1(pointer)
    }

    var descender: Int {
        return FreeType.sizeMetricsGetDescender1(pointer)
    }

    var height: Int {
        return FreeType.sizeMetricsGetHeight1(pointer)
    }

    var maxAdvance: Int {
        return FreeType.sizeMetricsGetMaxAdvance1(pointer)
    }

    var xppem: Int {
        return FreeType.sizeMetricsGetXPPEM1(pointer)
    }

    var yppem: Int {
        return FreeType.sizeMetricsGetYPPEM1(pointer)
    }

    var xScale: Int {
        return FreeType.sizeMetricsGetXScale1(pointer)
    }

    var yScale: Int {
        return FreeType.sizeMetricsGetYScale1(pointer)
    }
}
