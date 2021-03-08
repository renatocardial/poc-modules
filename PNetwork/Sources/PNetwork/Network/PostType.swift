//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

public enum PostType {
    case string
    case json
    case boundry((params: Data, code: String))
}
