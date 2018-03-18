//
//  FeedsManager.swift
//  TCSNewsReader
//
//  Created by Эдуард Миниахметов on 16.03.2018.
//  Copyright © 2018 Eduard Miniakhmetov. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class FeedsManager: NSObject, NSFetchedResultsControllerDelegate {

    // MARK: - Singleton
    
    private override init() { }
    
    private static var sharedFeedsManager: FeedsManager = {
        let feedsManager = FeedsManager()
        return feedsManager
    }()
   
    class var shared: FeedsManager {
        return sharedFeedsManager
    }

    // MARK: - Core Data stack
    
    // MARK: Persistent container
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "TCSNewsReader")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            guard let error = error as NSError? else {return}
            fatalError("Unresolved error \(error), \(error.userInfo)")
        })
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: Fetched Results controllers
    
    lazy var feedFetchedResultsController: NSFetchedResultsController<Feed> = {
        let fetchRequest = NSFetchRequest<Feed>(entityName:"Feed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending:true)]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        
        do {
            try controller.performFetch()
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }()
    
    lazy var watchedCountFetchedResultController: NSFetchedResultsController<FeedWatchedCount> = {
        let fetchRequest = NSFetchRequest<FeedWatchedCount>(entityName: "FeedWatchedCount")
        
        fetchRequest.sortDescriptors = []
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        controller.delegate = self
        
        do {
            try controller.performFetch()
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }()
    
    // MARK: Core Data Saving support
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Public methods
    
    func incrementWatchedCountFor(feed: Feed) {
        guard let fetchedObjects = watchedCountFetchedResultController.fetchedObjects else { return }
        
        guard let watchedCount = fetchedObjects.first(where: { (feedWatchedCount) -> Bool in
            return feedWatchedCount.id == feed.id
        }) else { return }
        
        watchedCount.count = watchedCount.count + 1
        
        do {
            try watchedCount.managedObjectContext?.save()
        } catch {
            let saveError = error as NSError
            print("Unable to save watchedCount")
            print("\(saveError), \(saveError.localizedDescription)")
        }
    }
    
    func importFeedsFromJSONModelArray(_ feeds: Array<FeedJSONModel>, completion: (() -> Void)?) throws {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        
        taskContext.performAndWait {
            for feed in feeds {
                let newFeed = NSEntityDescription.insertNewObject(forEntityName: "Feed", into: taskContext) as! Feed
                newFeed.updateWith(feed: feed)
                
                if ((watchedCountFetchedResultController.fetchedObjects?.first(where: { (watchedCount) -> Bool in
                    return watchedCount.id == newFeed.id
                })) == nil) {
                    let newFeedWatchedCount = NSEntityDescription.insertNewObject(forEntityName: "FeedWatchedCount", into: taskContext) as! FeedWatchedCount
                    newFeedWatchedCount.updateWith(id: feed.id, count: 0)
                }
                
                if taskContext.hasChanges {
                    do {
                        try taskContext.save()
                    }
                    catch {
                        print("Error: \(error)\nCould not save Core Data context.")
                        return
                    }
                    taskContext.reset()
                }
            }
        }
        
        completion?()
    }
    
    func getContentFor(feed: Feed) -> FeedContent? {
        let request = NSFetchRequest<FeedContent>(entityName: "FeedContent")
        request.returnsObjectsAsFaults = false
        
        let predicate = NSPredicate(format: "id = %d", feed.id)
        request.predicate = predicate
        
        do {
            let result = try self.persistentContainer.viewContext.fetch(request)
            
            return result.first(where: { (feedContent) -> Bool in
                return feedContent.id == feed.id
            })
        } catch {
            print("Failed")
        }
        
        return nil
    }
    
    func addContentFor(feed: Feed, content: String) {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        
        taskContext.perform {
            let newFeedContent = NSEntityDescription.insertNewObject(forEntityName: "FeedContent", into: taskContext) as! FeedContent
            newFeedContent.updateWith(id: feed.id, content: content)
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                }
                catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                    return
                }
                taskContext.reset()
            }
        }
    }
    
    func deleteAllFeeds() {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.undoManager = nil
        taskContext.performAndWait {
            let feedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Feed")
            let feedBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: feedRequest)
            
            do {
                try taskContext.execute(feedBatchDeleteRequest)
            }
            catch {
                print("Error: \(error)\nCould not batch delete existing records.")
            }
            
            let feedContentRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedContent")
            let feedContentBatchDeleteRequest = NSBatchDeleteRequest(fetchRequest: feedContentRequest)
            
            do {
                try taskContext.execute(feedContentBatchDeleteRequest)
            }
            catch {
                print("Error: \(error)\nCould not batch delete existing records.")
            }
            
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                }
                catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                    return
                }
                taskContext.reset()
            }
        }
        
        do {
            try feedFetchedResultsController.performFetch()
        }
        catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }
    
}
