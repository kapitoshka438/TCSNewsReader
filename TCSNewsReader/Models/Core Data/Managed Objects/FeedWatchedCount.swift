//
//  FeedWatchedCount.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 17.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import CoreData

class FeedWatchedCount: NSManagedObject {

    @NSManaged var id: Int
    @NSManaged var count: Int
    
    func updateWith(id: Int, count: Int) {
        self.id = id
        self.count = count
    }
    
}
