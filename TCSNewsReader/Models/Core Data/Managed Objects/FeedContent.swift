//
//  FeedContent.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 17.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import CoreData

class FeedContent: NSManagedObject {
    
    @NSManaged var id: Int
    @NSManaged var content: String
    
    func updateWith(id: Int, content: String) {
        self.id = id
        self.content = content
    }
    
}
