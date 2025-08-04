enum MTParseErrors {
    case ErrorNone

    /// The braces { } do not match.
    case MismatchBraces

    /// A command in the string is not recognized.
    case InvalidCommand

    /// An expected character such as ] was not found.
    case CharacterNotFound

    /// The \left or \right command was not followed by a delimiter.
    case MissingDelimiter

    /// The delimiter following \left or \right was not a valid delimiter.
    case InvalidDelimiter

    /// There is no \right corresponding to the \left command.
    case MissingRight

    /// There is no \left corresponding to the \right command.
    case MissingLeft

    /// The environment given to the \begin command is not recognized
    case InvalidEnv

    /// A command is used which is only valid inside a \begin,\end environment
    case MissingEnv

    /// There is no \begin corresponding to the \end command.
    case MissingBegin

    /// There is no \end corresponding to the \begin command.
    case MissingEnd

    /// The number of columns do not match the environment
    case InvalidNumColumns

    /// Internal error, due to a programming mistake.
    case InternalError

    /// Limit control applied incorrectly
    case InvalidLimits
}

class MTParseError {
    var errorCode: MTParseErrors = .ErrorNone
    var errorDesc: String = ""
    
    convenience init() {
        self.init(errorCode: .ErrorNone, errorDesc: "")
    }
    
    init(errorCode: MTParseErrors, errorDesc: String) {
        self.errorCode = errorCode
        self.errorDesc = errorDesc
    }
    
    func copyFrom(src: MTParseError?) {
        if let s = src {
            errorCode = s.errorCode
            errorDesc = s.errorDesc
        }
    }
}
