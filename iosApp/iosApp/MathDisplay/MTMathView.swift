import SwiftUI
import Combine

/**
 * MTMathView Swift implementation - Fixed version
 * 
 * Key fixes applied to match Kotlin version behavior:
 * 1. Removed incorrect screen density scaling in coordinate calculations
 * 2. Fixed width/height calculation to match Kotlin logic exactly  
 * 3. Implemented proper drawError function
 * 4. Removed debug red fill that was masking rendering issues
 * 5. Added MTMathViewLatex for LaTeX string input (like Kotlin version)
 */

/**
 * 共享数据类，用于管理 MTMathView 的状态
 */
private struct MTMathViewState {
    let displayList: MTMathListDisplay?
    let calculatedWidth: CGFloat
    let calculatedHeight: CGFloat
    let parseError: MTParseError?
}

struct MathItem {
    let displayList: MTMathListDisplay? // 预计算的显示对象
    let width: CGFloat
    let height: CGFloat
    let latex: String
    let parseError: MTParseError?
}

/**
 * 显示数学公式的组件，通过指定的公式对象、字体、颜色等属性来渲染相应的内容。
 *
 * @param mathList 数学公式对象，定义需要显示的数学公式。如果为空，则不渲染公式。
 * @param modifier 修饰符。
 * @param parseError 解析错误信息，当存在公式解析错误时用于描述具体的错误内容。
 * @param fontSize 公式中字体的大小，默认使用组件内部定义的默认字体大小。
 * @param textColor 公式渲染的颜色，默认为黑色。
 * @param font 数学公式的字体类型，若为 nil 则使用默认数学字体。
 * @param mode 数学公式的显示模式，包括“Display”模式和“Text”模式。
 * @param textAlignment 数学公式的对齐方式，可设置为左对齐、右对齐或居中显示。
 * @param displayErrorInline 是否内联显示解析错误，当解析错误存在且该值为 true 时显示错误信息。
 * @param errorFontSize 错误信息字体的大小，仅在解析错误需要显示时有效。
 */
struct MTMathView: View {
    let mathList: MTMathList?
    let parseError: MTParseError?
    let fontSize: Float
    let textColor: Color
    let font: MTFont?
    let mode: MTMathViewMode
    let textAlignment: MTTextAlignment
    let displayErrorInline: Bool
    let errorFontSize: Float

    init(mathList: MTMathList?, parseError: MTParseError? = nil, fontSize: Float = DefaultFontSize, textColor: Color = .black, font: MTFont? = nil, mode: MTMathViewMode = .display, textAlignment: MTTextAlignment = .left, displayErrorInline: Bool = false, errorFontSize: Float = DefaultErrorFontSize) {
        self.mathList = mathList
        self.parseError = parseError
        self.fontSize = fontSize
        self.textColor = textColor
        self.font = font
        self.mode = mode
        self.textAlignment = textAlignment
        self.displayErrorInline = displayErrorInline
        self.errorFontSize = errorFontSize
    }

    var body: some View {
        // 状态管理
        let state: MTMathViewState = computeState()

        Canvas { context, size in
            let parseError = state.parseError
            let displayList = state.displayList

            if let parseError = parseError, parseError.errorCode != .ErrorNone, displayErrorInline {
                drawError(parseError.errorDesc, errorFontSize, .red, context, size)
            } else if let displayList = displayList {
                drawMathFormula(displayList, textColor, textAlignment, context, size)
            }
        }
        .frame(width: state.calculatedWidth, height: state.calculatedHeight)
    }

    private func computeState() -> MTMathViewState {
        guard let mathList = mathList else {
            return MTMathViewState(displayList: nil, calculatedWidth: 0, calculatedHeight: 0, parseError: parseError)
        }

        // 1. 更新字体 - No screen scale needed here, fontSize is already in correct units
        let newFont = (font ?? MTFontManager.defaultFont()).copyFontWithSize(size: fontSize)

        // 2. 更新显示列表
        let newDisplayList: MTMathListDisplay? = {
            let style: MTLineStyle = (mode == .display) ? .kMTLineStyleDisplay : .kMTLineStyleText
            return MTTypesetter.createLineForMathList(mathList: mathList, font: newFont, style: style)
        }()

        // 3. 计算尺寸 - Match Kotlin logic exactly
        let (width, height): (CGFloat, CGFloat) = {
            if let newDisplayList = newDisplayList {
                // +1 for padding, just like in Kotlin version
                let width = CGFloat(newDisplayList.width + 1)
                let height = CGFloat(newDisplayList.ascent + newDisplayList.descent + 1)
                return (width, height)
            } else if let parseError = parseError, parseError.errorCode != .ErrorNone, displayErrorInline {
                let errorTextSize = CGFloat(errorFontSize)
                let estimatedWidth = CGFloat(parseError.errorDesc.count) * errorTextSize * 0.6
                return (estimatedWidth, errorTextSize * 1.2)
            } else {
                return (0, 0)
            }
        }()

        // 4. 一次性更新所有状态，避免中间状态
        return MTMathViewState(
            displayList: newDisplayList,
            calculatedWidth: width,
            calculatedHeight: height,
            parseError: parseError
        )
    }

    private func drawError(_ errorMessage: String, _ errorFontSize: Float, _ errorColor: Color, _ context: GraphicsContext, _ size: CGSize) {
        // Create a Text view for the error message
        let errorText = Text(errorMessage)
            .font(.system(size: CGFloat(errorFontSize)))
            .foregroundColor(errorColor)
        
        // Calculate center position
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Draw the error text centered
        context.draw(errorText, at: centerPoint, anchor: .center)
    }

    private func drawMathFormula(_ displayList: MTMathListDisplay, _ textColor: Color, _ textAlignment: MTTextAlignment, _ context: GraphicsContext, _ size: CGSize) {
        var context = context
        
        // Set text color (convert SwiftUI Color to a format the display list can use)
        // displayList.textColor = textColor // This might need adjustment based on how textColor is handled
        
        // 根据对齐方式计算 X 位置 - Match Kotlin logic exactly
        let textX: Float = {
            switch textAlignment {
            case .left: return 0
            case .center: return Float((size.width - CGFloat(displayList.width)) / 2)
            case .right: return Float(size.width - CGFloat(displayList.width))
            }
        }()

        // 计算 Y 位置（垂直居中） - Match Kotlin logic exactly
        var eqHeight = displayList.ascent + displayList.descent
        if eqHeight < Float(size.height) / 2 {
            eqHeight = Float(size.height) / 2
        }
        let textY = (Float(size.height) - eqHeight) / 2 + displayList.descent

        // 设置位置
        displayList.position = MTCGPoint(x: textX, y: textY)

        // 绘制（翻转 Y 轴以匹配数学坐标系）
        context.scaleBy(x: 1, y: -1)
        displayList.draw(canvas: context)
        
        // Debug red fill removed - was masking the actual rendering
        // context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.red))
    }
}

/**
 * 外部计算MTMathListDisplay后直接渲染数学公式到Canvas的组件，
 * 在Lazy组件中推荐使用本组件，避免解析计算。
 *
 * @param mathItem 数学公式对象，包含LaTeX字符串、宽高等信息。
 * @param modifier 修饰符。
 * @param textAlignment 文本对齐方式，可设置为左对齐、居中或右对齐，默认值为左对齐（KMTTextAlignmentLeft）。
 * @param errorFontSize 错误信息的字体大小，仅在渲染错误信息时使用，默认值为DefaultErrorFontSize。
 */
//struct MTMathViewCanvas: View {
//    let mathItem: MathItem
//    let modifier: AnyView
//    let textAlignment: MTTextAlignment
//    let errorFontSize: CGFloat
//
//    var body: some View {
//        Canvas { context, size in
//            if mathItem.displayList == nil || (mathItem.parseError?.errorCode != .none ?? false) {
//                // 绘制错误信息
//                drawError(
//                    mathItem.parseError?.errorDesc ?? "",
//                    errorFontSize,
//                    .red,
//                    context
//                )
//            } else if let displayList = mathItem.displayList {
//                // 绘制数学公式
//                drawMathFormula(
//                    displayList,
//                    Color(displayList.textColor),
//                    textAlignment,
//                    context
//                )
//            }
//        }
//        .modifier(modifier)
//        .frame(width: mathItem.width, height: mathItem.height)
//    }
///**
 * Compose 版本的数学公式显示组件
 *
 * 支持 LaTeX 格式的数学公式渲染
 *
 * @param latex LaTeX 格式的数学公式字符串
 * @param fontSize 字体大小
 * @param textColor 文本颜色
 * @param font 字体，默认使用 MTFontManager.defaultFont()
 * @param mode 显示模式：Display 模式或 Text 模式
 * @param textAlignment 文本对齐方式
 * @param displayErrorInline 是否内联显示解析错误
 * @param errorFontSize 错误文本的字体大小
 */
struct MTMathViewLatex: View {
    let latex: String
    let fontSize: Float
    let textColor: Color
    let font: MTFont?
    let mode: MTMathViewMode
    let textAlignment: MTTextAlignment
    let displayErrorInline: Bool
    let errorFontSize: Float
    
    @State private var mathList: MTMathList?
    @State private var parseError: MTParseError?
    
    init(latex: String, fontSize: Float = DefaultFontSize, textColor: Color = .black, font: MTFont? = nil, mode: MTMathViewMode = .display, textAlignment: MTTextAlignment = .left, displayErrorInline: Bool = true, errorFontSize: Float = DefaultErrorFontSize) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.font = font
        self.mode = mode
        self.textAlignment = textAlignment
        self.displayErrorInline = displayErrorInline
        self.errorFontSize = errorFontSize
    }
    
    var body: some View {
        MTMathView(
            mathList: mathList,
            parseError: parseError,
            fontSize: fontSize,
            textColor: textColor,
            font: font,
            mode: mode,
            textAlignment: textAlignment,
            displayErrorInline: displayErrorInline,
            errorFontSize: errorFontSize
        )
        .onAppear {
            parseLatex()
        }
        .onChange(of: latex) { _ in
            parseLatex()
        }
    }
    
    private func parseLatex() {
        if !latex.isEmpty {
            let result = parseMathList(latex)
            mathList = result.0
            parseError = result.1
        } else {
            mathList = nil
            parseError = nil
        }
    }
}

func parseMathList(_ latex: String) -> (MTMathList?, MTParseError) {
    if !latex.isEmpty {
        let parseError = MTParseError()
        let list = MTMathListBuilder.Factory.buildFromString(latex, error: parseError)
        let mathList = parseError.errorCode != MTParseErrors.ErrorNone ? nil : list
        return (mathList, parseError)
    } else {
        return (nil, MTParseError())
    }
}

/**
 * 数学显示模式
 */
enum MTMathViewMode {
    /// Display 模式，相当于 TeX 中的 $$
    case display
    /// Text 模式，相当于 TeX 中的 $
    case text
}

/**
 * 文本对齐方式
 */
enum MTTextAlignment {
    /// 左对齐
    case left
    /// 居中对齐
    case center
    /// 右对齐
    case right
}

private let DefaultFontSize: Float = 20
private let DefaultErrorFontSize: Float = 20
