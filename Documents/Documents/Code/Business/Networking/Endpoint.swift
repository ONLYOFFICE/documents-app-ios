//
//  Endpoint.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class Endpoint<Response> {
    
    let method: HTTPMethod
    let path: String
    let parameters: Parameters?
    let parameterEncoding: ParameterEncoding?
    let decode: (Data) throws -> Response?
    
    init(path: String,
         method: HTTPMethod = .get,
         parameters: Parameters? = nil,
         parameterEncoding: ParameterEncoding? = nil,
         decode: @escaping (Data) throws -> Response?) {
        
        self.method = method
        self.path = path
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.decode = decode
    }
}


extension Endpoint {
    
    static func make(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameters: Parameters? = nil,
        _ parameterEncoding: ParameterEncoding? = nil) -> Endpoint<String>
    {
        return Endpoint<String>(
            path: path,
            method: method,
            parameters: parameters,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> String? in
                return String(data: data, encoding: .utf8)
        })
    }
    
    static func make(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameters: Parameters? = nil,
        _ parameterEncoding: ParameterEncoding? = nil) -> Endpoint<Parameters>
    {
        return Endpoint<Parameters>(
            path: path,
            method: method,
            parameters: parameters,
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
        })
    }
    
    static func make<Response:BaseMappable>(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameters: Parameters? = nil,
        _ parameterEncoding: ParameterEncoding? = nil) -> Endpoint<Response>
    {
        return Endpoint<Response>(
            path: path,
            method: method,
            parameters: parameters,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> Response? in
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let result = Mapper<Response>().map(JSON: json) {
                            return result
                        }
                    }
                } catch {
                    log.debug(String(data: data, encoding: String.Encoding.utf8) ?? "")
                    log.debug(error)
                }
                
                return nil
        })
    }
    
    static func make<Response:BaseMappable>(
        _ path: String,
        _ method: HTTPMethod = .get,
        _ parameters: Parameters? = nil,
        _ parameterEncoding: ParameterEncoding? = nil) -> Endpoint<[Response]>
    {
        return Endpoint<[Response]>(
            path: path,
            method: method,
            parameters: parameters,
            parameterEncoding: parameterEncoding,
            decode: { (data: Data) -> [Response]? in
                
                var objects: [Response] = []
                
                do {
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Any]
                    
                    if let list = json {
                        for element in list {
                            if let readObject = Mapper<Response>().map(JSON:element as! [String : Any]) {
                                objects.append(readObject)
                            }
                        }
                    }
                } catch {
                    log.debug(String(data: data, encoding: String.Encoding.utf8) ?? "")
                    log.debug(error)
                }
                
                return objects
        })
    }
}
