//
//  MediaResource.swift
//  workday-demo
//
//  Created by Anthony Layne on 3/29/18.
//  Copyright © 2018 Anthony Layne LLC. All rights reserved.
//

import Foundation

struct MediaResource: ApiResource {
    var methodPath: String

    init(id itemId: String) {
        methodPath  = "/media/\(itemId)"
    }
    
    func makeModel(serialization: Serialization) -> MediaItem? {
        return MediaItem(serialization: serialization)
    }
}
