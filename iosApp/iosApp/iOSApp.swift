import SwiftUI

@main
struct iOSApp: App {
    @State var mathList: MTMathList?
    @State var parseError: MTParseError?
    @State var image: UIImage?
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MTMathView(mathList: mathList, parseError: parseError)
//                Canvas { context, size in
//                    if let image = image {
//                        context.draw(Image(uiImage: image), in: CGRect(origin: .zero, size: CGSize(width: 31, height: 50)))
//                    }
//                }.background(.red)
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .background(.red)
            .onAppear {
                 let result = parseMathList("x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}")
                 mathList = result.0
                 parseError = result.1
                // 从tmp目录加载图片
//                let file = NSTemporaryDirectory() + "19-latinmodern-math-75.0-31x50.png"
//                image = UIImage(contentsOfFile: file)
            }
        }
    }
}
