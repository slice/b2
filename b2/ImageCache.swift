//
//  ImageCache.swift
//  b2
//
//  Created by slice on 6/20/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa
import os.log

class ImageCache: NSObject, NSCacheDelegate {
    static let shared = ImageCache()

    var cache: NSCache<NSNumber, NSImage> = NSCache()
    private let log = Logger(subsystem: loggingSubsystem, category: "image-cache")

    override init() {
        super.init()
        self.cache.delegate = self
    }

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        let image = obj as! NSImage
        self.log.info("\(image) will be evicted")
    }

    func image(forID id: Int) -> NSImage? {
        return self.cache.object(forKey: NSNumber(value: id))
    }

    func insert(_ image: NSImage, forID id: Int) {
        self.log.info("inserting image (id: \(id)) into cache")
        self.cache.setObject(image, forKey: NSNumber(value: id))
    }

    deinit {
        self.log.info("\(self) deinit")
    }
}
