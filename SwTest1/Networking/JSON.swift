//
//  JSON.swift
//  SwTest1
//
//  Created by JimLai on 2020/4/11.
//  Copyright © 2020 stargate. All rights reserved.
//

import Foundation

extension JSON: ResDecodable {
    static func decode(_ data: Data) -> JSON? {
        guard let j = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        return JSON(j)
    }
}

extension JSON: CustomStringConvertible {
    public var description: String {
        #if DEBUG
        var jsonObject: Any?
        switch self {
        case .arr(let a):
            jsonObject = a
        case .dict(let d):
            jsonObject = d
        case .raw(let r):
            return String(describing: r)
        case .null:
            return "null"
        case .json(let j):
            return j.description
        }
        guard let j = jsonObject, let data = try? JSONSerialization.data(withJSONObject: j, options: .prettyPrinted), let s = String(data: data, encoding: .utf8) else {
            return "null"
        }
        return s
        #else
        return ""
        #endif
    }
}

public indirect enum JSON {
    case arr([Any]), dict([String: Any]), json(JSON), raw(Any), null
    public init<T>(_ pd: [T: Any]) where T: RawRepresentable, T.RawValue == String {
        self.init(pd.toStringKey())
    }
    
    public init(_ any: Any?) {
        guard let any = any else {
            self = .null
            return
        }
        switch any {
        case let x as [Any]:
            self = .arr(x)
        case let x as [String: Any]:
            self = .dict(x)
        case let x as JSON:
            self = .json(x)
        case let x as Data:
            guard let json = try? JSONSerialization.jsonObject(with: x) else {
                self = .null
                return
            }
            switch json {
            case let x as [String: Any]:
                self = .dict(x)
            case let x as [Any]:
                self = .arr(x)
            default:
                self = .null
            }
        default:
            self = .raw(any)
        }
    }
}

public extension JSON {
    subscript<T>(_ rs: T) -> JSON where T: RawRepresentable, T.RawValue == String {
        switch self {
        case .dict(let d):
            return JSON(d[rs.rawValue])
        default:
            return .null
        }
    }
    subscript(_ i: Int) -> JSON {
        switch self {
        case .arr(let arr):
            guard 0..<arr.count ~= i else {
                return .null
            }
            return JSON(arr[i])
        default:
            return .null
        }
    }
    var stringValue: String {
        switch self {
        case .raw(let x):
            return String(describing: x)
        default:
            return ""
        }
    }
    var intValue: Int {
        switch self {
        case .raw(let x):
            return Int(String(describing: x)) ?? 0
        default:
            return 0
        }
    }
    var decimalValue: Decimal {
        switch self {
        case .raw:
            return Decimal(string: stringValue) ?? 0
        default:
            return 0
        }
    }
    var doubleValue: Double {
        switch self {
        case .raw(let x):
            return Double(String(describing: x)) ?? 0
        default:
            return 0
        }
    }
    var arrayValue: [JSON] {
        switch self {
        case .arr(let a):
            return a.map {JSON($0)}
        default:
            return []
        }
    }
}
