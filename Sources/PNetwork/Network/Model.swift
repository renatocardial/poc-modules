//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public protocol Model: Decodable {
    static func mapJson() -> [String]
}

public extension Model {
    static func mapJson() -> [String] {  return [] }
}

public struct EmptyModel: Model {
    init() {}
}

