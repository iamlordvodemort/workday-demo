//
//  NetworkRequest.swift
//  workday-demo
//
//  Created by Anthony Layne on 3/29/18.
//  Copyright © 2018 Anthony Layne LLC. All rights reserved.
//

import Foundation
import UIKit

extension Data {

    var utf8String: String? {
        return string(as: .utf8)
    }
    func string(as encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
}

protocol NetworkRequest: class {
    associatedtype Model
    func load(withCompletion completion: @escaping (Model?) -> Void)
    func decode(_ data: Data) -> Model?
}

extension NetworkRequest {
    fileprivate func load(_ url: URL, withCompletion completion: @escaping (Model?) -> Void) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: url, completionHandler: { [weak self] (data: Data?,
            response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(self?.decode(data))
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

class ApiRequest<Resource: ApiResource> {
    let resource: Resource

    init(resource: Resource) {
        self.resource = resource
    }
}

extension ApiRequest: NetworkRequest {
    func decode(_ data: Data) -> [Resource.Model]? {
        return resource.makeModel(data: data)
    }

    func load(withCompletion completion: @escaping ([Resource.Model]?) -> Void) {
        load(resource.url, withCompletion: completion)
    }
}

//: MARK: - HealthCheckRequest

class HealthCheckRequest {
    let url: URL

    init() {
        url = URL(string: "https://media-rest-service.herokuapp.com/healthcheck")!
    }
}

extension HealthCheckRequest: NetworkRequest {
    func decode(_ data: Data) -> Bool? {
        guard let s = data.utf8String else { return false }
        debugPrint("server status: \(s)")
        switch s {
        case "OK":
            return true
        default:
            return false
        }
    }

    func load(withCompletion completion: @escaping (Bool?) -> Void) {
        load(url, withCompletion: completion)
    }
}

//: MARK: - FetchAllItemsRequest

class FetchAllItemsRequest {
    let url: URL

    init() {
        url = URL(string: "https://media-rest-service.herokuapp.com/media")!
    }
}

extension FetchAllItemsRequest: NetworkRequest {
    func decode(_ data: Data) -> [String]? {
        var itemsArray = [String]()
        do {
            if let items = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let array = items["media_items"] as! [String]
                let arraySlice = array.prefix(upTo: 2)
                let newArray = Array(arraySlice)
                itemsArray = newArray
            }
        } catch {
            debugPrint("could not parse data")
        }
//        debugPrint("items array: \(itemsArray)")
        return itemsArray
    }

    func load(withCompletion completion: @escaping ([String]?) -> Void) {
        load(url, withCompletion: completion)
    }
}
