//
//  Resource.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 1/26/19.
//  Copyright © 2019 SwiftBit. All rights reserved.
//

// https://talk.objc.io/episodes/S01E134-combined-resources-part-1
// https://talk.objc.io/episodes/S01E134-combined-resources-part-2


import Foundation

protocol NetworkTransport {
    @discardableResult
    func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A, Error>) -> ()) -> Cancelable
}

enum HttpMethod<Body> {
    case get
    case post(Body)
    case delete
}

extension HttpMethod {
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .delete: return "DELETE"
        }
    }
}

struct Resource<A> {
    var urlRequest: URLRequest
    let parse: (Data) throws -> A
}

extension Resource {
    func map<B>(_ transform: @escaping (A) throws -> B) -> Resource<B> {
        return Resource<B>(urlRequest: urlRequest) {
            return try transform(self.parse($0))
        }
    }
}

extension Resource where A: Decodable {
    init(get url: URL) {
        self.urlRequest = URLRequest(url: url)
        self.parse = { data in
            try JSONDecoder().decode(A.self, from: data)
        }
    }
    
    init<Body: Encodable>(url: URL, method: HttpMethod<Body>) throws {
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.method
        switch method {
        case .get: ()
        case .delete: ()
        case .post(let body):
            self.urlRequest.httpBody = try JSONEncoder().encode(body)
        }
        self.parse = { data in
            try JSONDecoder().decode(A.self, from: data)
        }
    }
}


func dataFromHTTPResponse(data: Data?, response: URLResponse?, error: Error?) throws -> Data {
    switch (data, response, error) {
    case (_, nil, nil):
        throw ResourceError("nil response and error. Shouldn't happen.")
    case (_, _, let error?):
        throw error
    case (let data, let response?, nil):
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResourceError("response (\(response)) is not a HTTPURLResponse. Shouldn't happen")
        }
        guard httpResponse.statusCode >= 200, httpResponse.statusCode < 300 else {
            throw HTTPError(code: httpResponse.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
        guard let data = data else {
            throw ResourceError("Data is nil")
        }
        return data
    }
}

extension URLSession: NetworkTransport {
    @discardableResult
    func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A, Error>) -> ()) -> Cancelable {
        let task = dataTask(with: resource.urlRequest) { data, httpResponse, error in
            let result = Result { () -> A in
                let data = try dataFromHTTPResponse(data: data, response: httpResponse, error: error)
                return try resource.parse(data)
            }
            completion(result)
        }
        task.resume()
        return task
    }
}

struct Episode: Codable {
    var number: Int
    var title: String
    var collection: String
}

struct Collection: Codable {
    var title: String
    var id: String
}

indirect enum CombinedResource<A> {
    case single(Resource<A>)
    case _sequence(CombinedResource<Any>, (Any) -> CombinedResource<A>)
    case _zipped(CombinedResource<Any>, CombinedResource<Any>, (Any, Any) throws -> A)
}

extension CombinedResource {
    var asAny: CombinedResource<Any> {
        switch self {
        case let .single(r): return .single(r.map { $0 })
        case let ._sequence(l, transform): return ._sequence(l, { x in
            transform(x).asAny
        })
        case let ._zipped(l, r, f): return ._zipped(l, r, { x, y in
            try f(x, y)
        })
        }
    }
    
    func flatMap<B>(_ transform: @escaping (A) -> CombinedResource<B>) -> CombinedResource<B> {
        return CombinedResource<B>._sequence(self.asAny, { x in
            transform(x as! A)
        })
    }
    
    func map<B>(_ transform: @escaping (A) -> B) -> CombinedResource<B> {
        switch self {
        case let .single(r): return .single(r.map(transform))
        case let ._sequence(l, f):
            return ._sequence(l, { x in
                f(x).map(transform)
            })
        case let ._zipped(l, r, f):
            return CombinedResource<B>._zipped(l, r, { x, y in
                transform(try f(x, y))
            })
        }
    }
    
    func zipWith<B, C>(_ other: CombinedResource<B>, _ combine: @escaping (A,B) -> C) -> CombinedResource<C> {
        return CombinedResource<C>._zipped(self.asAny, other.asAny, { x, y in
            combine(x as! A, y as! B)
        })
    }
    
    func zip<B>(_ other: CombinedResource<B>) -> CombinedResource<(A,B)> {
        return zipWith(other, { ($0, $1) })
    }
}

let episodes = Resource<[Episode]>(get: URL(string: "https://talk.objc.io/episodes.json")!)
let collections = Resource<[Collection]>(get: URL(string: "https://talk.objc.io/collections.json")!)


extension NetworkTransport {
    @discardableResult
    func load<A>(_ resource: CombinedResource<A>, completion: @escaping (Result<A, Error>) -> ()) -> Cancelable {
        let handle: Cancelable
        switch resource {
        case let .single(r): handle = load(r, completion: completion)
        case let ._sequence(l, transform):
            let taskHandle = TaskHandle()
            taskHandle.task = load(l) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let x):
                    taskHandle.task = self.load(transform(x), completion: completion)
                }
            }
            handle = taskHandle
        case let ._zipped(l, r, transform):
            let group = DispatchGroup()
            var resultA: Result<Any, Error>?
            var resultB: Result<Any, Error>?
            group.enter()
            let handle1 = load(l) { resultA = $0; group.leave() }
            group.enter()
            let handle2 = load(r) { resultB = $0; group.leave() }
            handle = ZipTaskHandle(handle1, handle2)
            group.notify(queue: .global(), execute: {
                guard let x = resultA, let y = resultB else {
                    fatalError("This should not happen")
                }
                let result: Result<A, Error>
                switch (x, y) {
                case (let .success(value1), let .success(value2)):
                    result = Result { try transform(value1, value2) }
                case (let .failure(e1), let .failure(e2)):
                    result = Result<A, Error>.failure(ZipResourceError(wrappedErrors: (e1, e2)))
                    break
                case (_, let .failure(e2)):
                    result = Result<A, Error>.failure(e2)
                    break
                case (let .failure(e1), _):
                    result = Result<A, Error>.failure(e1)
                    break
                }
                completion(result)
            })
        }
        return handle
    }
}

extension Resource {
    var c: CombinedResource<A> {
        return .single(self)
    }
}


struct ZipResourceError: Error, CustomStringConvertible {
    var description: String {
        return "Two requests failed.\n - \(wrappedErrors.0)\n - \(wrappedErrors.1)"
    }
    
    let wrappedErrors: (Error, Error)
}

struct ResourceError: Error, CustomStringConvertible {
    let message: String
    init(_ message: String) {
        self.message = message
    }
    var description: String { return "ResourceError: "+message }
}

struct HTTPError: Error, CustomStringConvertible {
    let code: Int
    let message: String
    
    var description: String {
        return "Http Error \(code): \(message)"
    }
}

protocol Cancelable: class {
    func cancel()
}

extension URLSessionDataTask: Cancelable {}

class TaskHandle: Cancelable {
    weak var task: Cancelable?
    
    func cancel() {
        task?.cancel()
    }
    
    init(_ task: Cancelable? = nil) {
        self.task = task
    }
}

class ZipTaskHandle: Cancelable {
    weak var task0: Cancelable?
    weak var task1: Cancelable?
    
    init(_ task0: Cancelable, _ task1: Cancelable) {
        self.task0 = task0
        self.task1 = task1
    }
    
    func cancel() {
        task0?.cancel()
        task1?.cancel()
    }
}
