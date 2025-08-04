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
                    canvas.draw(Image(uiImage: cachedBitmap), at: CoreFoundation.CGPoint(x: Double(x) + offsetX, y: Double(y) - offsetY + 200))
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
//                    let ftBitmap = UnsafePointer<FT_Bitmap>(bitPattern: plainBitmap.pointer)!
//                    bitmap = createUIImage(from: ftBitmap.pointee)
                    bitmap = createImageBitmapFromFreetypeBitmap(width: plainBitmap.width, height: plainBitmap.rows, buffer: plainBitmap.buffer, pitch: plainBitmap.pitch)
                    BitmapCache.set(cacheKey, value: bitmap!)
                }

                if let bitmap = bitmap, let metrics = glyphSlot?.metrics {
                    let offsetX = Double(metrics.horiBearingX) / 64.0
                    let offsetY = Double(metrics.horiBearingY) / 64.0
                    let point = CGPoint(x: Double(x) + offsetX, y: Double(y) - offsetY + 200)
                    let imageRect = CGRect(origin: point, size: bitmap.size)
//                    if let imgData = bitmap.pngData {
//                        try? imgData.write(to: URL(fileURLWithPath: "\(NSTemporaryDirectory())\(cacheKey).png"))
//                    }
                    canvas.draw(Image(uiImage: bitmap), in: imageRect)
                    canvas.stroke(Path(imageRect), with: .color(.red), lineWidth: 2)
                }
            } else if gid != 1 && gid != 33 {
                throw MathDisplayException("missing glyph slot \(gid).")
            }
        }
    }
}

func createImageBitmapFromFreetypeBitmap(width: Int, height: Int, buffer: Data, pitch: Int) -> UIImage {
    let bytesPerPixel = 1
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8

    let colorSpace = CGColorSpaceCreateDeviceGray()
    let provider = CGDataProvider(data: buffer as CFData)
    let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: 8,
            bytesPerRow: pitch,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

    return UIImage(cgImage: cgImage)
}

func createUIImage(from ftBitmap: FT_Bitmap) -> CGImage? {
    guard ftBitmap.rows > 0, ftBitmap.width > 0, ftBitmap.buffer != nil,
          ftBitmap.pixel_mode == FT_PIXEL_MODE_GRAY.rawValue
    else {
        print("无效位图或不支持的像素模式")
        return nil
    }

    let width = Int(ftBitmap.width)
    let height = Int(ftBitmap.rows)
    let bytesPerPixel = 4  // RGBA
    let bytesPerRow = width * bytesPerPixel  // 无填充
    let totalBytes = bytesPerRow * height

    // 分配RGBA缓冲区（使用UnsafeMutableRawBufferPointer以安全管理内存）
    guard let rgbaBuffer = malloc(totalBytes) else {
        print("内存分配失败")
        return nil
    }
    defer {
        free(rgbaBuffer)
    }  // 确保释放

    // 复制并转换：灰度到RGBA (R=0, G=0, B=0, A=gray)，并翻转Y轴
    let srcBuffer = UnsafeMutableRawPointer(ftBitmap.buffer)!
    for y in 0..<height {
        let srcRowOffset = y * Int(ftBitmap.pitch)  // 来源行偏移（处理pitch）
        let dstRowOffset = (height - 1 - y) * bytesPerRow  // 目标行偏移（翻转Y）

        for x in 0..<width {
            // 读取源灰度值（使用load）
            let srcOffset = srcRowOffset + x
            let grayValue = srcBuffer.load(fromByteOffset: srcOffset, as: UInt8.self)

            // 计算目标像素偏移
            let dstPixelOffset = dstRowOffset + x * bytesPerPixel

            // 写入RGBA值（使用storeBytes）
            rgbaBuffer.storeBytes(of: 0, toByteOffset: dstPixelOffset, as: UInt8.self)      // R
            rgbaBuffer.storeBytes(of: 0, toByteOffset: dstPixelOffset + 1, as: UInt8.self)  // G
            rgbaBuffer.storeBytes(of: 0, toByteOffset: dstPixelOffset + 2, as: UInt8.self)  // B
            rgbaBuffer.storeBytes(of: grayValue, toByteOffset: dstPixelOffset + 3, as: UInt8.self)  // A
        }
    }

    // 创建CGDataProvider（添加release回调来释放缓冲区）
    let provider = CGDataProvider(dataInfo: rgbaBuffer, data: rgbaBuffer, size: totalBytes) { info, data, size in
       // free(info)  // 释放malloc的内存
    }

    guard let dataProvider = provider else {
        free(rgbaBuffer)  // 如果provider创建失败，手动释放
        print("CGDataProvider创建失败")
        return nil
    }

    // 创建CGImage
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)  // Alpha在最后 (RGBA)

    guard let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8, // 8位每通道
        bitsPerPixel: 32, // 32位每像素 (RGBA)
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: dataProvider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
    else {
        print("CGImage创建失败")
        return nil
    }

    return cgImage
}
