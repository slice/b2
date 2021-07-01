//
//  URL+Slash.swift
//  b2
//
//  Created by slice on 6/30/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Foundation

extension URL {
  static public func / (url: URL, component: String) -> URL {
    return url.appendingPathComponent(component)
  }
}
