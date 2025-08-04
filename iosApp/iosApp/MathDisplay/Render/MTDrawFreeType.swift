import Foundation
import SwiftUI

class MTDrawFreeType {
    let mathFont: MTFontMathTable

    init(mathFont: MTFontMathTable) {
        self.mathFont = mathFont
    }

    func drawGlyph(canvas: GraphicsContext, gid: Int, x: Float, y: Float) throws {  // 假设 Canvas 是 CGContext
        let face = mathFont.checkFontSize()

        // 先用 NO_RENDER 模式获取字形信息
        if gid != 0 && !face.loadGlyph(glyphIndex: gid, flags: FreeTypeConstants.FT_LOAD_NO_BITMAP) {
            let glyphSlot = face.glyphSlot
            if let metrics = glyphSlot?.metrics {
                let estimatedWidth = Int(Float(metrics.width) / 64.0)
                let estimatedHeight = Int(Float(metrics.height) / 64.0)
                let cacheKey = "\(gid)-\(mathFont.font.name)-\(mathFont.font.fontSize)-\(estimatedWidth)x\(estimatedHeight)"

                if let cachedBitmap = BitmapCache.get(cacheKey) {
                    let offsetX = Double(metrics.horiBearingX) / 64.0
                    let offsetY = Double(metrics.horiBearingY) / 64.0
                    canvas.draw(Image(uiImage: cachedBitmap), at: CoreFoundation.CGPoint(x: Double(x) + offsetX, y: Double(y) - offsetY))
                    return
                }
            }
        }

        // 加载并渲染
        if gid != 0 && !face.loadGlyph(glyphIndex: gid, flags: FreeTypeConstants.FT_LOAD_RENDER) {
            let glyphSlot = face.glyphSlot
            if let plainBitmap = glyphSlot?.bitmap, plainBitmap.width > 0, plainBitmap.rows > 0 {
                let cacheKey = "\(gid)-\(mathFont.font.name)-\(mathFont.font.fontSize)-\(plainBitmap.width)x\(plainBitmap.rows)"

                var bitmap = BitmapCache.get(cacheKey)
                if bitmap == nil {
                    bitmap = createImageBitmapFromFreetypeBitmap(width: plainBitmap.width, height: plainBitmap.rows, buffer: plainBitmap.buffer)
                    BitmapCache.set(cacheKey, value: bitmap!)
                }

                if let bitmap = bitmap, let metrics = glyphSlot?.metrics {
                    let offsetX = Double(metrics.horiBearingX) / 64.0
                    let offsetY = Double(metrics.horiBearingY) / 64.0
                    canvas.draw(Image(uiImage: bitmap), at: CoreFoundation.CGPoint(x: Double(x) + offsetX, y: Double(y) - offsetY))
                }
            } else if gid != 1 && gid != 33 {
                throw MathDisplayException("missing glyph slot \(gid).")
            }
        }
    }
}

func createImageBitmapFromFreetypeBitmap(width: Int, height: Int, buffer: NativeBinaryBuffer) -> UIImage {
    let bytesPerPixel = 1
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8

    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
        fatalError("Failed to create CGContext")
    }

    // 将 FreeType 的字形位图数据复制到 CGContext
    buffer.withPointer { pointer in
       context.data?.copyMemory(from: pointer.baseAddress!, byteCount: width * height)
    }

    guard let cgImage = context.makeImage() else {
        fatalError("Failed to create CGImage from CGContext")
    }

    return UIImage(cgImage: cgImage)
}
