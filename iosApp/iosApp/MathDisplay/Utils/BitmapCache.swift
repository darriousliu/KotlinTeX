import Foundation
import UIKit

class BitmapCache {
    private static var cache = NSCache<NSString, UIImage>()

    static func get(_ key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    static func set(_ key: String, value: UIImage) {
        cache.setObject(value, forKey: key as NSString)
    }

    static func resize(_ newSize: Int) {
        cache.totalCostLimit = newSize
    }

    static func clear() {
        cache.removeAllObjects()
    }
}
