//
//  Endpoint.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import ObjectMapper

class Endpoint<Response> {
    let method: HTTPMethod
    let path: String
    let parameterEncoding: ParameterEncoding?
    let decode: (Data) throws -> Response?

    init(path: String,
         method: HTTPMethod = .get,
         parameterEncoding: ParameterEncoding? = nil,
         decode: @escaping (Data) throws -> Response?)
    {
        self.method = method
        self.path = path
        self.parameterEncoding = parameterEncoding
        self.decode = decode
    }
}

extension Endpoint {
    class func make(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil
    ) -> Endpoint<Bool> {
        Endpoint<Bool>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding
        ) { data in
            String(data: data, encoding: .utf8).flatMap(Bool.init)
        }
    }

    class func make(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil
    ) -> Endpoint<String> {
        Endpoint<String>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> String? in
                String(data: data, encoding: .utf8)
            }
        )
    }

    class func make(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil
    ) -> Endpoint<Parameters> {
        Endpoint<Parameters>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> Parameters? in
                do {
                    if let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        return result
                    }
                } catch {
                    log.debug(String(data: data, encoding: String.Encoding.utf8) ?? "")
                    log.debug(error)
                }

                return nil
            }
        )
    }

    class func make<T: BaseMappable>(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil
    ) -> Endpoint<T> {
        Endpoint<T>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> T? in
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let result = Mapper<T>().map(JSON: json) {
                            return result
                        }
                    }
                } catch {
                    log.debug(String(data: data, encoding: String.Encoding.utf8) ?? "")
                    log.debug(error)
                }

                return nil
            }
        )
    }

    class func make<T: BaseMappable>(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil,
        _ params: [String: Any]? = nil
    ) -> Endpoint<[T]> {
        Endpoint<[T]>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> [T]? in

                var objects: [T] = []

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Any]

                    if let list = json {
                        for element in list {
                            if let readObject = Mapper<T>().map(JSON: element as! [String: Any]) {
                                objects.append(readObject)
                            }
                        }
                    }
                } catch {
                    log.debug(String(data: data, encoding: String.Encoding.utf8) ?? "")
                    log.debug(error)
                }

                return objects
            }
        )
    }

    class func make<T: Codable>(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameterEncoding: ParameterEncoding? = nil
    ) -> Endpoint<T> {
        return Endpoint<T>(
            path: path,
            method: method,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> T? in
                let decoder = JSONDecoder()
                return try? decoder.decode(T.self, from: data)
            }
        )
    }
}
