import Foundation

class Bitmap: Pointer {
    var width: Int {
        return FreeType.bitmapGetWidth1(pointer)
    }
    var rows: Int {
        return FreeType.bitmapGetRows1(pointer)
    }
    var pitch: Int {
        return FreeType.bitmapGetPitch1(pointer)
    }
    var numGrays: Int16 {
        return FreeType.bitmapGetNumGrays1(pointer)
    }
    var paletteMode: Character {
        return FreeType.bitmapGetPaletteMode1(pointer)
    }
    var pixelMode: Character {
        return FreeType.bitmapGetPixelMode1(pointer)
    }
    var buffer: Data {
        return FreeType.bitmapGetBuffer1(pointer)
    }
}
