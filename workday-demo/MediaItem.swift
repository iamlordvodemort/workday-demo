//
//  Media.swift
//  workday-demo
//
//  Created by Anthony Layne on 3/29/18.
//  Copyright © 2018 Anthony Layne LLC. All rights reserved.
//

import Foundation

struct MediaItem {
    let quality: String!
    let duration: Int!
    let name: String!
    let url: String!
    let id: String!
}


extension MediaItem {
    private enum Keys: String, SerializationKey {
        case quality
        case duration
        case name
        case url
        case id
    }

    init?(serialization: Serialization) {
        guard let urlVal: String = serialization.value(forKey: Keys.url),
            let idVal: String = serialization.value(forKey: Keys.id) else { return nil }

        quality = serialization.value(forKey: Keys.quality)
        duration = serialization.value(forKey: Keys.duration)
        name = serialization.value(forKey: Keys.name)
        url = urlVal
        id = idVal
    }
}
