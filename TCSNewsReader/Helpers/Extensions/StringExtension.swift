//
//  StringExtension.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import Foundation

extension String {
    
    public var htmlDecodedString: String {
        get {
            guard let data = data(using: .utf8) else {
                return self
            }
            
            guard let attributedString = try? NSAttributedString(data: data,
                                                                 options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                                                                 documentAttributes: nil) else {
                                                                    return self
            }
            
            return attributedString.string
        }
    }
    
}
