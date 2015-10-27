//
//  Data.swift
//  CoreDataTest
//
//  Created by Ross M Mooney on 10/22/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//

import UIKit
import CoreData
import ReactiveCocoa

class Data {
    //Singleton
    static let sharedInstance = Data()
    
    var dataIsLoading:Bool = false
    
    func generateContext() -> NSManagedObjectContext? {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = self.saveMoc
        managedObjectContext.undoManager = nil
        print("Private Context Generated")
        return managedObjectContext
    }
    
    func loadAllTheData() {
        if !self.dataIsLoading {
            self.dataIsLoading = true
            loadDataProducer(generateContext()!).startOn(QueueScheduler(qos: QOS_CLASS_UTILITY, name: "")).startWithCompleted({
                print("LoadDataProducer completed")
                self.dataIsLoading = false
            })
        }
    }
    
    func loadDataProducer(moc: NSManagedObjectContext) -> SignalProducer<(), NoError> {
        return SignalProducer { [weak self] sink, disposable in
            let count = 50000
            
            print("Load data started for \(count) items")
            let startTime = NSDate.timeIntervalSinceReferenceDate()
            self?.loadData(moc, count: count)
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            print("Load data finished, time: \(endTime - startTime) seconds")
            
            sink.sendCompleted()
        }
    }
    
    
    func loadData(moc: NSManagedObjectContext, count: Int) {

        for itemIndex in 0...count {
            let contact = NSManagedObject(entity: NSEntityDescription.entityForName("Contact", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc) as! Contact
            contact.firstName = "first\(itemIndex)"
            contact.lastName = "last\(itemIndex)"
            contact.contactId = itemIndex
            
            for phoneIndex in 0...3 {
                let phone = NSManagedObject(entity: NSEntityDescription.entityForName("Phone", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc) as! Phone
                phone.contact = contact
                phone.phoneId = phoneIndex + itemIndex
                phone.phoneNumber = "\(itemIndex)\(itemIndex)"
            }

            for emailIndex in 0...5 {
                let email = NSManagedObject(entity: NSEntityDescription.entityForName("Email", inManagedObjectContext: moc)!, insertIntoManagedObjectContext: moc) as! Email
                email.contact = contact
                email.emailId = emailIndex + itemIndex
                email.emailAddress = "\(itemIndex)\(itemIndex)"
            }
            
        }
        
        do {
            try moc.save()
        } catch let error {
            print("Failed to save: \(error)")
        }
        
        
    }
    
    func numberOfContacts() -> Int {
//        let moc = generateContext()! <-- Using this we don't block the main thread, but NSFRC requires a main thread context
        let moc = self.mainMoc
        let fetchRequest = NSFetchRequest(entityName: "Contact")
        do {
            let startTime = NSDate.timeIntervalSinceReferenceDate()
            let fetchedEntities = try moc.executeFetchRequest(fetchRequest) as! [Contact]
            let endTime = NSDate.timeIntervalSinceReferenceDate()
            print("Fetch Time = \(endTime - startTime) seconds")
            return fetchedEntities.count
        } catch {
            // Do something in response to error condition
            print("Failed to get number of contacts")
            return 0
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.rossmooney.CoreDataTest" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("CoreDataTest", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var saveMoc: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        managedObjectContext.undoManager = nil
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: NSOperationQueue.mainQueue()) {
            [weak self] notification in
            if let savedContext = notification.object as? NSManagedObjectContext {
                if savedContext == self?.saveMoc {
                    return
                }
                
                let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    do {
                        print("Merging contexts:")
                        self?.areWeBlockingTheMainThread()
                        let startTime = NSDate.timeIntervalSinceReferenceDate()
                        try self?.saveMoc.save()
                        let endTime = NSDate.timeIntervalSinceReferenceDate()
                        print("Merged to Parent (save) MOC- Merge time: \(endTime - startTime) seconds")
                    } catch let error {
                        NSLog("An error occured while merging a store context save into the main thread context: \(error)")
                        print("\(error)")
                    }
                }
                

            }
        }

        return managedObjectContext
    }()
    
    
    lazy var mainMoc: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.saveMoc
        managedObjectContext.undoManager = nil
        
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if self.mainMoc.hasChanges {
            do {
                try self.mainMoc.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func areWeBlockingTheMainThread() {
        if NSThread.isMainThread() { print("We are blocking the main thread!") } else { print("We are not blocking the main thread.") }
    }

}