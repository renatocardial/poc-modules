//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public struct PNetworkResponse<T: Model> {
    public var statusCode: Int
    public var object: T?
    public var error: PNetworkError?
    public var raw: String
    
    init(statusCode: Int, object: T?, error: PNetworkError?, raw: String) {
        self.statusCode = statusCode
        self.object = object
        self.error = error
        self.raw = raw
    }
    
}
