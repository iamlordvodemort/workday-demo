//
//  ApiResource.swift
//  workday-demo
//
//  Created by Anthony Layne on 3/29/18.
//  Copyright © 2018 Anthony Layne LLC. All rights reserved.
//

import Foundation

struct ApiWrapper {
    let items: [Serialization]
}

extension ApiWrapper {
    private enum Keys: String, SerializationKey {
        case items = "id"
    }

    init(serialization: Serialization) {
        items = serialization.value(forKey: Keys.items) ?? []
    }
}

protocol ApiResource {
    associatedtype Model
    var methodPath: String { get }
    func makeModel(serialization: Serialization) -> Model
}

extension ApiResource {
    var url: URL {
        let baseUrl = "https://media-rest-service.herokuapp.com"
        let url = baseUrl + methodPath
        return URL(string: url)!
    }

    func makeModel(data: Data) -> [Model]? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
            return nil
        }
        guard let jsonSerialization = json as? Serialization else {
            return nil
        }
        let wrapper = ApiWrapper(serialization: jsonSerialization)
        return wrapper.items.map(makeModel(serialization:))
    }
}
