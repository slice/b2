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

    var cache: NSCache<NSString, NSImage> = NSCache()
    private let log = Logger(subsystem: loggingSubsystem, category: "image-cache")

    override init() {
        super.init()
        self.cache.delegate = self
    }

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        let image = obj as! NSImage
        self.log.info("\(image) will be evicted")
    }

    func image(forGlobalID id: String) -> NSImage? {
        return self.cache.object(forKey: NSString(string: id))
    }

    func insert(_ image: NSImage, forGlobalID id: String) {
        self.log.info("inserting image (id: \(id)) into cache")
        self.cache.setObject(image, forKey: NSString(string: id))
    }

    deinit {
        self.log.info("\(self) deinit")
    }
}
