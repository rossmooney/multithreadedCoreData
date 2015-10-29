//
//  DataViewController.swift
//  CoreDataTest
//
//  Created by Ross M Mooney on 10/26/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//

import UIKit
import CoreData

class SecondViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var searchField:UITextField!
    
    var currentPage = 1
    static var pageSize = 30
    
    var animatedView:UIView!
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Contact")
        let primarySortDescriptor = NSSortDescriptor(key: "firstName", ascending: true)
        request.sortDescriptors = [primarySortDescriptor]
        request.fetchBatchSize = 100
        request.fetchLimit = pageSize
        
        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: Data.sharedInstance.mainMoc,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()
    
    override func viewDidLoad() {

        //Setup
        self.animatedView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        self.animatedView.backgroundColor = .redColor()
        self.view.addSubview(self.animatedView)
            
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }

        
        self.searchField.delegate = self // Replace TextField with the name of your textField
        self.searchField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)

    }

    override func viewDidAppear(animated: Bool) {
        animate(true)
        
        print("Number of items: \(Data.sharedInstance.numberOfContacts())")
        
//        print(Data.sharedInstance.fetchInPages(10000))
        
    }

    func animate(forwards: Bool) {
        UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            if forwards {
                self.animatedView.frame = CGRect(x: 100, y: 200, width: 300, height: 200)
                self.animatedView.backgroundColor = .purpleColor()
                self.animatedView.transform = CGAffineTransformMakeRotation(340)
                
            } else {
                self.animatedView.frame = CGRect(x: 30, y: 80, width: 100, height: 70)
                self.animatedView.backgroundColor = .yellowColor()
                self.animatedView.transform = CGAffineTransformMakeRotation(54)
                
            }
            }) { _ in
                self.animate(!forwards)
        }
        
    }
}

extension SecondViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! Cell
        let contact = fetchedResultsController.objectAtIndexPath(indexPath) as! Contact
        
        cell.label?.text = contact.firstName! + " " + contact.lastName!
        return cell
    }

}

// MARK: NSFetchedResultsControllerDelegate
extension SecondViewController : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            //Even though these won't be deleted by the user they can be deleted on logout since they are pointing directly to NSManagedObject's that are cleared when the user logs out.
            //If this wasn't here even though the inbox view would not be visible the table updates would still fire on logout and the number of objects in the table view would not match the datasource and crashes will happen.
            if let deletePath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([deletePath], withRowAnimation: .None)
            }
        case .Insert:
            if let insertPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([insertPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Update:
            if let updatePath = indexPath {
                self.tableView.reloadRowsAtIndexPaths([updatePath], withRowAnimation: .None)
            }
        case .Move:
            if let oldPath = indexPath, newPath = newIndexPath {
                self.tableView.moveRowAtIndexPath(oldPath, toIndexPath: newPath)
                dispatch_async(dispatch_get_main_queue(), { self.tableView.reloadRowsAtIndexPaths([newPath], withRowAnimation: .None) })
            }
        }
    }
    
    func loadNextPage() {
        currentPage++
        self.fetchedResultsController.fetchRequest.fetchLimit = currentPage * SecondViewController.pageSize
        do {
            try self.fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch let error {
            print("Error loading next page: \(error)")
        }
    
    }
}

extension SecondViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 50 {
            loadNextPage()
        }
    }
}

extension SecondViewController : UITextFieldDelegate {
    func textFieldDidChange(textField: UITextField) {
        self.fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "firstName CONTAINS %@", textField.text!)
        do {
            try self.fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch let error {
            print("Error loading next page: \(error)")
        }
    }
}
    