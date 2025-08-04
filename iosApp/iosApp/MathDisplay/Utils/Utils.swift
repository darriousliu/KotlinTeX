import Foundation

class Utils {

    static func isHighSurrogate(_ c: Character) -> Bool {
        return c.unicodeScalars.first!.value >= 0xD800 && c.unicodeScalars.first!.value <= 0xDBFF
    }

    static func isLowSurrogate(_ c: Character) -> Bool {
        return c.unicodeScalars.first!.value >= 0xDC00 && c.unicodeScalars.first!.value <= 0xDFFF
    }

    static func codePointAt(sequence: [Character], index: Int) -> Int {
        let ch1 = sequence[index]
        if isHighSurrogate(ch1) && index + 1 < sequence.count {
            let ch2 = sequence[index + 1]
            if isLowSurrogate(ch2) {
                return ((Int(ch1.unicodeScalars.first!.value) - 0xD800) << 10) +
                    (Int(ch2.unicodeScalars.first!.value) - 0xDC00) + 0x10000
            }
        }
        return Int(ch1.unicodeScalars.first!.value)
    }

    static func codePointToChars(codePoint: Int) -> [Character] {
        switch codePoint {
        case 0...0xFFFF:
            return [Character(UnicodeScalar(codePoint)!)]
        case 0x10000...0x10FFFF:
            let cpPrime = codePoint - 0x10000
            let high = 0xD800 + (cpPrime >> 10)
            let low = 0xDC00 + (cpPrime & 0x3FF)
            return [Character(UnicodeScalar(high)!), Character(UnicodeScalar(low)!)]
        default:
            fatalError("Invalid Unicode code point: \(codePoint)")
        }
    }
}

extension String {
    /**
     * 统计字符串在 UTF-16 单元索引 [beginIndex, endIndex) 区间内的 Unicode code point 数量。
     */
    func codePointCount(beginIndex: Int, endIndex: Int) -> Int {
        precondition(beginIndex >= 0 && beginIndex <= self.count, "beginIndex out of range")
        precondition(endIndex >= beginIndex && endIndex <= self.count, "endIndex out of range")

        var count = 0
        var i = beginIndex
        while i < endIndex {
            let ch = self[self.index(self.startIndex, offsetBy: i)]
            if Utils.isHighSurrogate(ch) && i + 1 < endIndex &&
                   Utils.isLowSurrogate(self[self.index(self.startIndex, offsetBy: i + 1)]) {
                // 发现一个代理对，算作一个 code point
                i += 2
            } else {
                i += 1
            }
            count += 1
        }
        return count
    }
    
    /// 从字符串中获取指定整数索引处的字符（从0开始）。
        /// - Parameter index: 整数索引（0 <= index < count），如果无效返回nil。
        /// - Returns: 指定位置的Character，或nil（如果索引越界）。
        func character(at index: Int) -> Character {
            // 从startIndex偏移index距离，获取String.Index
            let stringIndex = self.index(self.startIndex, offsetBy: index)
            
            // 使用下标访问字符
            return self[stringIndex]
        }
}

extension Utils {
    static func charCount(codePoint: Int) -> Int {
        switch codePoint {
        case 0...0xFFFF:
            return 1
        case 0x10000...0x10FFFF:
            return 2
        default:
            fatalError("Invalid Unicode code point: \(codePoint)")
        }
    }
}

func readAssetFile(path: String) throws -> Data {
    guard let url = Bundle.main.url(forResource: path, withExtension: nil) else {
        fatalError("Asset file not found: \(path)")
    }

    do {
        return try Data(contentsOf: url)
    } catch {
        fatalError("Failed to read asset file at \(url): \(error)")
    }
}
