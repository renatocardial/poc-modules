//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
