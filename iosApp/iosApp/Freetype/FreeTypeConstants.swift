


class FreeTypeConstants {
    /* FT_LOAD_* (Load Char flags) */
    static let FT_LOAD_DEFAULT = 0x0
    static let FT_LOAD_NO_SCALE = (1 << 0)
    static let FT_LOAD_NO_HINTING = (1 << 1)
    static let FT_LOAD_RENDER = (1 << 2)
    static let FT_LOAD_NO_BITMAP = (1 << 3)
    static let FT_LOAD_VERTICAL_LAYOUT = (1 << 4)
    static let FT_LOAD_FORCE_AUTOHINT = (1 << 5)
    static let FT_LOAD_CROP_BITMAP = (1 << 6)
    static let FT_LOAD_PEDANTIC = (1 << 7)
    static let FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH = (1 << 9)
    static let FT_LOAD_NO_RECURSE = (1 << 10)
    static let FT_LOAD_IGNORE_TRANSFORM = (1 << 11)
    static let FT_LOAD_MONOCHROME = (1 << 12)
    static let FT_LOAD_LINEAR_DESIGN = (1 << 13)
    static let FT_LOAD_NO_AUTOHINT = (1 << 15)
    static let FT_LOAD_COLOR = (1 << 20)
    static let FT_LOAD_COMPUTE_METRICS = (1 << 21)

    /* FT_FSTYPE_* (FSType flags) */
    static let FT_FSTYPE_INSTALLABLE_EMBEDDING = 0x0000
    static let FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING = 0x0002
    static let FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING = 0x0004
    static let FT_FSTYPE_EDITABLE_EMBEDDING = 0x0008
    static let FT_FSTYPE_NO_SUBSETTING = 0x0100
    static let FT_FSTYPE_BITMAP_EMBEDDING_ONLY = 0x0200

    /* FT_Encoding */
    static let FT_ENCODING_NONE = 0x0
    static let FT_ENCODING_MS_SYMBOL = 1937337698 // s y m b
    static let FT_ENCODING_UNICODE = 1970170211 // u n i c
    static let FT_ENCODING_SJIS = 1936353651 // s j i s
    static let FT_ENCODING_GB2312 = 1734484000 // g b
    static let FT_ENCODING_BIG5 = 1651074869 // b i g 5
    static let FT_ENCODING_WANSUNG = 2002873971 // w a n s
    static let FT_ENCODING_JOHAB = 1785686113 // j o h a
    static let FT_ENCODING_ADOBE_STANDARD = 1094995778 // A D O B
    static let FT_ENCODING_ADOBE_EXPERT = 1094992453 // A D B E
    static let FT_ENCODING_ADOBE_CUSTOM = 1094992451 // A D B C
    static let FT_ENCODING_ADOBE_LATIN_1 = 1818326065 // l a t 1
    static let FT_ENCODING_OLD_LATIN_2 = 1818326066 // l a t 2
    static let FT_ENCODING_APPLE_ROMAN = 1634889070 // a r m n

    enum FT_Render_Mode {
        case FT_RENDER_MODE_NORMAL
        case FT_RENDER_MODE_LIGHT
        case FT_RENDER_MODE_MONO
        case FT_RENDER_MODE_LCD
        case FT_RENDER_MODE_LCD_V

        case FT_RENDER_MODE_MAX

        var ordinal: Int {
            switch self {
            case .FT_RENDER_MODE_NORMAL:
                return 0
            case .FT_RENDER_MODE_LIGHT:
                return 1
            case .FT_RENDER_MODE_MONO:
                return 2
            case .FT_RENDER_MODE_LCD:
                return 3
            case .FT_RENDER_MODE_LCD_V:
                return 4
            case .FT_RENDER_MODE_MAX:
                return 5
            }
        }
    }

    enum FT_Size_Request_Type {
        case FT_SIZE_REQUEST_TYPE_NOMINAL
        case FT_SIZE_REQUEST_TYPE_REAL_DIM
        case FT_SIZE_REQUEST_TYPE_BBOX
        case FT_SIZE_REQUEST_TYPE_CELL
        case FT_SIZE_REQUEST_TYPE_SCALES

        case FT_SIZE_REQUEST_TYPE_MAX
        
        var ordinal: Int {
            switch self {
            case .FT_SIZE_REQUEST_TYPE_NOMINAL:
                return 0
            case .FT_SIZE_REQUEST_TYPE_REAL_DIM:
                return 1
            case .FT_SIZE_REQUEST_TYPE_BBOX:
                return 2
            case .FT_SIZE_REQUEST_TYPE_CELL:
                return 3
            case .FT_SIZE_REQUEST_TYPE_SCALES:
                return 4
            case .FT_SIZE_REQUEST_TYPE_MAX:
                return 5
            }
        }

        static let entries: [FT_Size_Request_Type] = [
            .FT_SIZE_REQUEST_TYPE_NOMINAL,
            .FT_SIZE_REQUEST_TYPE_REAL_DIM,
            .FT_SIZE_REQUEST_TYPE_BBOX,
            .FT_SIZE_REQUEST_TYPE_CELL,
            .FT_SIZE_REQUEST_TYPE_SCALES,
            .FT_SIZE_REQUEST_TYPE_MAX
        ]
    }

    enum FT_Kerning_Mode {
        case FT_KERNING_DEFAULT
        case FT_KERNING_UNFITTED
        case FT_KERNING_UNSCALED
        
        var ordinal: Int {
            switch self {
            case .FT_KERNING_DEFAULT:
                return 0
            case .FT_KERNING_UNFITTED:
                return 1
            case .FT_KERNING_UNSCALED:
                return 2
            }
        }
    }
}
