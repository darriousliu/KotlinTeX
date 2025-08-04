import Foundation

class CharMap: Pointer {
    func getCharMapIndex() -> Int {
        return FreeType.getCharMapIndex1(pointer)
    }
}
