import Foundation

class NativeBinaryBuffer {
    private var data: Data
    private var position: Int = 0
    private var limit: Int

    var size: Int {
        return data.count
    }

    var short: Int16 {
        guard remaining() >= 2 else { fatalError("Buffer underflow") }
        let p = position
        let uval = (UInt16(data[p]) << 8) | UInt16(data[p + 1])
        position += 2
        return Int16(bitPattern: uval)
    }

    var int: Int32 {
        guard remaining() >= 4 else { fatalError("Buffer underflow") }
        let p = position
        let uval = (UInt32(data[p]) << 24) | (UInt32(data[p + 1]) << 16) | (UInt32(data[p + 2]) << 8) | UInt32(data[p + 3])
        position += 4
        return Int32(bitPattern: uval)
    }
    
    convenience init(size: Int) {
        self.init(data: Data(count: size))
    }

    init(data: Data) {
        self.data = data
        self.limit = data.count
    }
    
    func withPointer<T>(action: (UnsafeMutableRawBufferPointer) -> T) -> T {
        return data.withUnsafeMutableBytes(action)
    }

    func getPosition() -> Int {
        return position
    }

    func position(_ newPosition: Int) {
        guard newPosition >= 0 && newPosition <= limit else { fatalError("Illegal argument") }
        position = newPosition
    }

    func limit(_ newLimit: Int) {
        guard newLimit >= 0 && newLimit <= data.count else { fatalError("Illegal argument") }
        limit = newLimit
        if position > limit {
            position = limit
        }
    }

    func remaining() -> Int {
        return limit - position
    }

    func fill(bytes: Data) {
        precondition(bytes.count <= size)
        position = 0
        guard bytes.count <= remaining() else { fatalError("Buffer overflow") }
        data.replaceSubrange(0..<bytes.count, with: bytes)
        position = 0
    }

    func getData() -> Data {
        data
    }

    func free() {
    }
}
