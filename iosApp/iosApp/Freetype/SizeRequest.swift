


class SizeRequest {
    private var type: Int
    let width: Int
    let height: Int
    let horiResolution: Int
    let vertResolution: Int

    init(type: FreeTypeConstants.FT_Size_Request_Type, width: Int, height: Int, horiResolution: Int, vertResolution: Int) {
        self.type = type.ordinal
        self.width = width
        self.height = height
        self.horiResolution = horiResolution
        self.vertResolution = vertResolution
    }

    func getType() -> FreeTypeConstants.FT_Size_Request_Type? {
        return FreeTypeConstants.FT_Size_Request_Type.entries[type]
    }

    func setType(type: FreeTypeConstants.FT_Size_Request_Type) {
        self.type = type.ordinal
    }
}
