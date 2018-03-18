//
//  JSONParseError.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import Foundation

enum JSONParseErrorCode: Int {
    case nullData = 1
    case serialization = 2
    case keyNotFound = 3
}

struct JSONParseError: LocalizedError {
    
    var code: JSONParseErrorCode
    var errorDescription: String? { return _description }
    
    private var _description: String
    
    init(description: String, code: JSONParseErrorCode) {
        self._description = description
        self.code = code
    }
}


