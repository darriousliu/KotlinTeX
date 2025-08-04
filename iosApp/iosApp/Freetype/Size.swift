

class Size: Pointer {
    var metrics: SizeMetrics? {
        get {
            let sizeMetrics = FreeType.sizeGetMetrics1(pointer)
            if sizeMetrics <= 0 {
                return nil
            }
            return SizeMetrics(sizeMetrics)
        }
    }
}
