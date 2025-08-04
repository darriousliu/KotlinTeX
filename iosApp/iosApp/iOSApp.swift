import SwiftUI

@main
struct iOSApp: App {
    @State var mathList: MTMathList?
    @State var parseError: MTParseError?
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MTMathView(mathList: mathList, parseError: parseError)
            }.onAppear {
                let result = parseMathList("\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)")
                mathList = result.0
                parseError = result.1
            }
        }
    }
}
