//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public protocol PEnvironment {
    var baseUrl: String { get }
    var defaultHeaders: [String: String] { get set }
    func getUrl(endpoint: PEndpoint) -> URL?
}

public extension PEnvironment {
    func getUrl(endpoint: PEndpoint) -> URL? {
        let url: String = "\(baseUrl)/\(endpoint.path)"
        return URL(string: url)
    }
}
