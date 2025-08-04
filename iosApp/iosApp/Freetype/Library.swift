import Foundation

/**
 * Each library is completely independent from the others; it is the root of a set of objects like fonts, faces, sizes, etc.
 */
class Library: Pointer {
    /**
     * Destroy the library object and all of it's childrens, including faces, sizes, etc.
     */
    func delete() -> Bool {
        return doneFreeType(pointer)
    }

    /**
     * Create a new Face object from file<br></br>
     * It will return null in case of error.
     */
    func newFace(file: String, faceIndex: Int) -> Face? {
        do {
            let byteArray = try readAssetFile(path: file)
            return newFace(file: byteArray, faceIndex: faceIndex)
        } catch {
            print(error)
        }
        return nil
    }

    /**
     * Create a new Face object from a byte[]<br></br>
     * It will return null in case of error.
     */
    func newFace(file: Data, faceIndex: Int) -> Face? {
        let buffer = FreeType.newBuffer(size: file.count)
        buffer.limit(buffer.getPosition() + file.count)
        buffer.fill(bytes: file)
        return newFace(file: buffer, faceIndex: faceIndex)
    }

    /**
     * Create a new Face object from a ByteBuffer.<br></br>
     * It will return null in case of error.<br></br>
     * Take care that the ByteByffer must be a direct buffer created with Utils.newBuffer and filled with Utils.fillBuffer.
     */
    func newFace(file: NativeBinaryBuffer, faceIndex: Int) -> Face? {
        let face = FreeType.newMemoryFace1(pointer, data: file,length: Int32(file.remaining()), faceIndex: faceIndex)
        if face == 0 {
            FreeType.deleteBuffer(file)
            return nil
        }
        return Face(pointer: face, data: file)
    }

    /**
     * Returns a LibraryVersion object containing the information about the version of FreeType
     */
    var version: LibraryVersion {
        return FreeType.libraryVersion1(pointer)
    }
}
