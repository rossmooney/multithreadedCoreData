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
    
    var dataMoc: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = (UIApplication.sharedApplication().delegate as! AppDelegate).persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    init() {
        let coordinator = (UIApplication.sharedApplication().delegate as! AppDelegate).persistentStoreCoordinator

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:", name:NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coordinator)
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        let dictionary = notification.userInfo!
        print(dictionary)
        let moc: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        moc.performBlock { () -> Void in
            moc.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    func loadAllTheData() {
        if !self.dataIsLoading {
            self.dataIsLoading = true
            loadDataProducer().startOn(QueueScheduler(qos: QOS_CLASS_UTILITY, name: "")).startWithCompleted({
                print("Producer completed")
                self.dataIsLoading = false
            })
        }
    }
    
    func loadDataProducer() -> SignalProducer<(), NoError> {
        return SignalProducer { [weak self] sink, disposable in
            print("Load data started")
            
            self?.loadData(20000)
            
            print("Load data finished")
            
            sink.sendCompleted()
        }
    }
    
    
    func loadData(count: Int) {

        for itemIndex in 0...count {
            let contact = NSManagedObject(entity: NSEntityDescription.entityForName("Contact", inManagedObjectContext: self.dataMoc)!, insertIntoManagedObjectContext: self.dataMoc) as! Contact
            contact.firstName = "first\(itemIndex)"
            contact.lastName = "last\(itemIndex)"
            contact.contactId = itemIndex
            
            for phoneIndex in 0...3 {
                let phone = NSManagedObject(entity: NSEntityDescription.entityForName("Phone", inManagedObjectContext: self.dataMoc)!, insertIntoManagedObjectContext: self.dataMoc) as! Phone
                phone.contact = contact
                phone.phoneId = phoneIndex + itemIndex
                phone.phoneNumber = "\(itemIndex)\(itemIndex)"
            }

            for emailIndex in 0...5 {
                let email = NSManagedObject(entity: NSEntityDescription.entityForName("Email", inManagedObjectContext: self.dataMoc)!, insertIntoManagedObjectContext: self.dataMoc) as! Email
                email.contact = contact
                email.emailId = emailIndex + itemIndex
                email.emailAddress = "\(itemIndex)\(itemIndex)"
            }
            
        }
        
        do {
            try self.dataMoc.save()
        } catch let error {
            print("Failed to save: \(error)")
        }
        
        
    }
    
    func numberOfContacts() -> Int {
        let fetchRequest = NSFetchRequest(entityName: "Contact")
        do {
            let mainMoc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            let fetchedEntities = try mainMoc.executeFetchRequest(fetchRequest) as! [Contact]
            return fetchedEntities.count
        } catch {
            // Do something in response to error condition
            print("Failed to get number of contacts")
            return 0
        }
    }
    
}