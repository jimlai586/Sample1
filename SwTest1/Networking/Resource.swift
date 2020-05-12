//
//  Resource.swift
//  SwTest1
//
//  Created by JimLai on 2020/4/11.
//  Copyright © 2020 stargate. All rights reserved.
//

import UIKit

typealias P = Params
enum Params: String {
    case none
}

enum NetError: Error {
    case pre, httpRespCode(Int?), payload
}

protocol ResDecodable {
    static func decode(_ data: Data) -> Self?
}

protocol Resource: class {
    associatedtype DataType: ResDecodable
    var url: String { get set }
    var success: ((DataType) -> ())? { get set }
    var fail: ((Error) -> ())? { get set }
    func onSuccess(_ cb: @escaping (DataType) -> ()) -> Self
    func onFailure(_ cb: @escaping (Error) -> ()) -> Self
    func dataTask(_ req: URLRequest) -> URLSessionTask
    func preError()
    func post(urlParams: [Params: String]) -> Self
    func get() -> Self
}

extension Resource {
    @discardableResult
    func onSuccess(_ cb: @escaping (DataType) -> ()) -> Self {
        success = cb
        return self
    }
    
    @discardableResult
    func onFailure(_ cb: @escaping (Error) -> ()) -> Self {
        fail = cb
        return self
    }
    
    func get() -> Self {
        guard let url = URL(string: self.url) else {
            preError()
            return self
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let task = dataTask(req)
        task.resume()
        return self
    }

    func post(urlParams: [Params: String]) -> Self {
        guard var urlComponents = URLComponents(string: url) else {
            preError()
            return self
        }
        urlComponents.queryItems = urlParams.map { (kv) in
            URLQueryItem(name: kv.key.rawValue, value: kv.value)
        }
        guard let encoded = urlComponents.url else {
            preError()
            return self
        }
        var req = URLRequest(url: encoded)
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        let task = dataTask(req)
        task.resume()
        return self
    }
    
    func preError() {
        DispatchQueue.main.async { [weak self] in
            let e = NetError.payload
            self?.fail?(e)
        }
    }
    
    func dataTask(_ req: URLRequest) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard error == nil else {
                let e = NetError.pre
                DispatchQueue.main.async {
                    self.fail?(e)
                }
                return
            }
            guard let resp = response as? HTTPURLResponse, (200...299 ~= resp.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode
                let e = NetError.httpRespCode(code)
                DispatchQueue.main.async {
                    self.fail?(e)
                }
                return
            }
            
            guard let data = data, let payload = DataType.decode(data) else {
                let e = NetError.payload
                DispatchQueue.main.async {
                    self.fail?(e)
                }
                return
            }
            DispatchQueue.main.async {
                self.success?(payload)
            }
            
        }
        return task
    }
    
}

protocol ProfileUpdate {
    func post(_ img: UIImage?) -> Json
    func patch(_ bio: String) -> Json
}

extension ProfileUpdate where Self: Json {
    // should provide actual implementation
    // placeholder here
    func post(_ img: UIImage? = nil) -> Json {
        return self
    }
    func patch(_ bio: String) -> Json {
        return self
    }
}

final class Json: Resource, ProfileUpdate {
    typealias DataType = JSON
    
    var fail: ((Error) -> ())?
    
    var url: String
    
    var success: ((JSON) -> ())?
    
    init(_ url: String) {
        self.url = url
    }

    // override for mocking
    #if MOCK
    func post(_ img: UIImage? = nil) -> Json {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.success?(JSON.null)
        }
        return self
    }
    func patch(_ bio: String) -> Json {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.success?(JSON.null)
        }
        return self
    }
    #endif
}

public extension Dictionary where Key: RawRepresentable, Key.RawValue == String {
    func toStringKey() -> [String: Any] {
        var d = [String: Any]()
        for k in self.keys {
            let v = self[k]!
            if let x = v as? [Key: Any] {
                d[k.rawValue] = x.toStringKey()
            }
            else {
                d[k.rawValue] = v
            }
        }
        return d
    }
}
