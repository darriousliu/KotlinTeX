import SwiftUI
import Combine

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

        ScrollView(.horizontal, showsIndicators: true) {
            Canvas { context, size in
                let parseError = state.parseError
                let displayList = state.displayList

                if let parseError = parseError, parseError.errorCode != .ErrorNone, displayErrorInline {
                    drawError(parseError.errorDesc, errorFontSize, .red, context, size)
                } else if let displayList = displayList {
                    drawMathFormula(displayList, textColor, textAlignment, context, size)
                }
                print(size)
                print(UIScreen.main.bounds.width)
            }
            .frame(width: state.calculatedWidth, height: state.calculatedHeight)
            .background {
                LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
            }
        }
    }

    private func computeState() -> MTMathViewState {
        guard let mathList = mathList else {
            return MTMathViewState(displayList: nil, calculatedWidth: 0, calculatedHeight: 0, parseError: parseError)
        }

        // 1. 更新字体
        let newFont = (font ?? MTFontManager.defaultFont()).copyFontWithSize(size: Float(fontSize))

        // 2. 更新显示列表
        let newDisplayList: MTMathListDisplay? = {
            let style: MTLineStyle = (mode == .display) ? .kMTLineStyleDisplay : .kMTLineStyleText
            return MTTypesetter.createLineForMathList(mathList: mathList, font: newFont, style: style)
        }()

        // 3. 计算尺寸
        let (width, height): (CGFloat, CGFloat) = {
            if let newDisplayList = newDisplayList {
                let width = newDisplayList.width + 1
                let height = newDisplayList.ascent + newDisplayList.descent + 1
                return (CGFloat(width), CGFloat(height))
            } else if let parseError = parseError, parseError.errorCode != .ErrorNone, displayErrorInline {
                let errorTextSize = CGFloat(errorFontSize)
                let estimatedWidth = CGFloat(parseError.errorDesc.count) * CGFloat(errorTextSize * 0.6)
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

    }

    private func drawMathFormula(_ displayList: MTMathListDisplay, _ textColor: Color, _ textAlignment: MTTextAlignment, _ context: GraphicsContext, _ size: CGSize) {
        var context = context
        // 根据对齐方式计算 X 位置
        let textX: Float = {
            switch textAlignment {
            case .left: return 0
            case .center: return Float((size.width - CGFloat(displayList.width)) / 2)
            case .right: return Float(size.width - CGFloat(displayList.width))
            }
        }()

        // 计算 Y 位置（垂直居中）
        var eqHeight = displayList.ascent + displayList.descent
        if eqHeight < Float(size.height) / 2 {
            eqHeight = Float(size.height / 2)
        }
        let textY = (Float(size.height) - eqHeight) / 2 + displayList.descent

        // 设置位置
        displayList.position.x = textX
        displayList.position.y = textY

        // 绘制（翻转 Y 轴以匹配数学坐标系）
        context.scaleBy(x: 1, y: -1)
        displayList.draw(canvas: context)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.red))
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
//}

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

private let DefaultFontSize: Float = 75
private let DefaultErrorFontSize: Float = 75
