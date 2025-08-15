package com.pvporbit.freetype

internal object Utils {
    fun isHighSurrogate(c: Char) = (c.code in 0xD800..0xDBFF)

    fun isLowSurrogate(c: Char) = (c.code in 0xDC00..0xDFFF)

    fun codePointAt(sequence: CharArray, index: Int): Int {
        val ch1 = sequence[index]
        if (isHighSurrogate(ch1) && index + 1 < sequence.size) {
            val ch2 = sequence[index + 1]
            if (isLowSurrogate(ch2)) {
                return ((ch1.code - 0xD800) shl 10) + (ch2.code - 0xDC00) + 0x10000
            }
        }
        return ch1.code
    }

    fun codePointToChars(codePoint: Int): CharArray {
        return when (codePoint) {
            in 0..0xFFFF -> {
                charArrayOf(codePoint.toChar())
            }

            in 0x10000..0x10FFFF -> {
                val cpPrime = codePoint - 0x10000
                val high = 0xD800 + (cpPrime shr 10)
                val low = 0xDC00 + (cpPrime and 0x3FF)
                charArrayOf(high.toChar(), low.toChar())
            }

            else -> {
                throw IllegalArgumentException("Invalid Unicode code point: $codePoint")
            }
        }
    }

    /**
     * 统计字符串在 UTF-16 单元索引 [beginIndex, endIndex) 区间内的 Unicode code point 数量。
     */
    fun String.codePointCount(beginIndex: Int, endIndex: Int): Int {
        require(beginIndex in 0..length) { "beginIndex out of range" }
        require(endIndex in beginIndex..length) { "endIndex out of range" }

        var count = 0
        var i = beginIndex
        while (i < endIndex) {
            val ch = this[i]
            if (ch.isHighSurrogate() && i + 1 < endIndex && this[i + 1].isLowSurrogate()) {
                // 发现一个代理对，算作一个 code point
                i += 2
            } else {
                i += 1
            }
            count += 1
        }
        return count
    }

    fun charCount(codePoint: Int): Int =
        when (codePoint) {
            in 0..0xFFFF -> 1
            in 0x10000..0x10FFFF -> 2
            else -> throw IllegalArgumentException("Invalid Unicode code point: $codePoint")
        }

}

expect fun readAssetFile(path: String): ByteArray
