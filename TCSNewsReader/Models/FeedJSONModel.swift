//
//  FeedManagedObject.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import Foundation

class FeedJSONModel {
    
    private var _order: Int
    private var _id: Int
    private var _text: String
    private var _publicationDate: Date
    
    public var order: Int {
        return _order
    }
    
    public var id: Int {
        return _id
    }
    
    public var text: String {
        return _text
    }
    
    public var publicationDate: Date {
        return _publicationDate
    }
    
    init(order: Int, id: Int, text: String, publicationDate: Date) {
        self._order = order
        self._id = id
        self._text = text.htmlDecodedString
        self._publicationDate = publicationDate
    }
    
}
