//
//  Preferences.swift
//  b2
//
//  Created by slice on 6/16/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Foundation

// https://danieltull.co.uk/blog/2019/10/09/type-safe-user-defaults
struct PreferenceKey<Value> {
    public let name: String
    public let `default`: Value

    public init(_ name: String, defaultingTo defaultValue: Value) {
        self.name = name
        self.default = defaultValue
    }
}

extension PreferenceKey where Value == Int {
    static let imageGridThumbnailSize = Self("imageGridThumbnailSize", defaultingTo: 150)
    static let imageGridSpacing = Self("imageGridSpacing", defaultingTo: 1)
}

extension PreferenceKey where Value == Bool {
    static let compactTagsEnabled = Self("compactTagsEnabled", defaultingTo: false)
}

extension Notification.Name {
    static let preferencesChanged = Self(rawValue: "zone.slice.Preferences.preferencesChanged")
}

class Preferences {
    static let shared = Preferences()

    private let defaults: UserDefaults

    init(defaultsDatabase defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }

    func set<Value>(_ key: PreferenceKey<Value>, to value: Value) {
        self.defaults.set(value, forKey: key.name)
        NotificationCenter.default.post(Notification(name: .preferencesChanged))
    }

    func get<Value>(_ key: PreferenceKey<Value>) -> Value {
        guard let value = self.defaults.value(forKey: key.name) as? Value? else {
            fatalError("Failed to cast preference \"\(key.name)\" to expected type")
        }

        guard let value = value else {
            return key.default
        }

        return value
    }
}
