//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public struct PEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let params: [String: String]
    let postType: PostType
    
    public init(path: String, method: HTTPMethod, headers: [String: String], params: [String: String], postType: PostType) {
        self.path = path
        self.method = method
        self.headers = headers
        self.params = params
        self.postType = postType
    }
}
