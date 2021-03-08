//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public enum PNetworkError: Error {
    case noneResponse
    case noContent
    case jsonParsing
    case invalidUrl
    case serviceError(message: String)
    
    public var message: String {
        switch self {
        case let .serviceError(message):
            return message
        default:
            return self.localizedDescription
        }
    }
}
