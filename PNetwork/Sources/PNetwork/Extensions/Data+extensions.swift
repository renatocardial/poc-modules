//
//  File.swift
//  
//
//  Created by Renato Cardial on 05/03/21.
//

import Foundation

extension Data {
    
    func prettyJSON() -> String {
        var result = ""
        if let object = try? JSONSerialization.jsonObject(with: self, options: []) {
            if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
                result = String(data: data, encoding: .utf8) ?? ""
            }
        } else {
            result = String(data: self, encoding: .utf8) ?? ""
        }
        return result
    }
    
}
