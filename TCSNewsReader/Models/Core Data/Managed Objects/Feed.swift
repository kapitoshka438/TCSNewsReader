//
//  FeedManagedObject.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import Foundation
import CoreData

class Feed: NSManagedObject {
    
    @NSManaged var order: Int
    @NSManaged var id: Int
    @NSManaged var text: String
    @NSManaged var publicationDate: Date
    
    func updateWith(feed: FeedJSONModel) {
        self.order = feed.order
        self.id = feed.id
        self.text = feed.text
        self.publicationDate = feed.publicationDate
    }
    
}
