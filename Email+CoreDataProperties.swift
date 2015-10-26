//
//  Email+CoreDataProperties.swift
//  CoreDataTest
//
//  Created by Ross M Mooney on 10/22/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Email {

    @NSManaged var emailAddress: String?
    @NSManaged var emailId: NSNumber?
    @NSManaged var contact: NSManagedObject?

}
