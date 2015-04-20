//
//  AddressBook.swift
//  living
//
//  Created by Nils Fischer on 13.06.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation
import UIKit
import AddressBook
import VILogKit
import CoreData


// MARK: Global Interface

public let logger = Logger.loggerForKeyPath("VIAddressBookKit")

public let AddressBookAuthorizationStatusDidChangeNotification = "VIAddressBookKit.AddressBookAuthorizationStatusDidChangeNotification"
public let AddressBookStatusDidChangeNotification = "VIAddressBookKit.AddressBookStatusDidChangeNotification"
/// Forward this notification to addressBookDidChangeExternally: to trigger a contact reload (can't listen to notifications in generic non-@objc class, so has to be triggered externally for now).
public let AddressBookDidChangeExternallyNotification = "VIAddressBookKit.AddressBookDidChangeExternallyNotification"


public let _sharedAddressBook = AddressBook<AddressBookContact>()
internal let addressBookQueue: dispatch_queue_t = {
    return dispatch_queue_create("com.viwid.VIAddressBookKit.addressBookQueue", DISPATCH_QUEUE_SERIAL)
}()


public enum AddressBookStatus<C>: Printable {
    case NotLoaded, Loading, Merging([ABRecordID : C]), Loaded([ABRecordID : C])
    
    public var description: String {
        switch self {
        case .NotLoaded: return "Not Loaded"
        case .Loading: return "Loading"
        case .Merging: return "Merging"
        case .Loaded: return "Loaded"
        }
    }
}

public class AddressBook<C: AddressBookContact> {

    public let addressBookRef: ABAddressBookRef
    
    public var status: AddressBookStatus<C> = .NotLoaded {
        didSet {
            self.logger.log("Status changed to \(status)", forLevel: .Debug)
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(AddressBookStatusDidChangeNotification, object: self)
            }
        }
    }
    
    // public var managedObjectContext: NSManagedObjectContext?
    // TODO: use this variable when it's possible to add protocol constraints to a type. so long, do the same in a closure
    // public var managedObjectsType: (NSManagedObject: AddressBookContactMergable).Type?
    /// Temporary way to merge address book contacts into database. Make sure to forward this call to mergeContacts:andManagedObjectsOfType:withManagedObjectContext:
    public var _mergingOperationBlock: ((contacts: [ABRecordID : C]) -> ())?
    
    
    // MARK: Initializers

    public init() {
        // Create Address Book
        var addressBookRef: ABAddressBookRef?
        dispatch_sync(addressBookQueue) {
            addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
            // Register external change callback
            registerExternalChangeCallbackForAddressBook(addressBookRef)
        }
        if addressBookRef == nil {
            log("Could not create ABAddressBookRef.", forLevel: .Critical) // TODO: can't access self here, but should never happen anyway
        }
        self.addressBookRef = addressBookRef!
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "addressBookDidChangeExternally:", name: AddressBookDidChangeExternallyNotification, object: nil)
    }
    
    
    // MARK: Singleton
    // TODO: reconsider this..
    
    public class func sharedAddressBook() -> AddressBook<AddressBookContact> {
        return _sharedAddressBook
    }
    
    
    // MARK: Authorization
    
    public class func authorizationStatus() -> ABAuthorizationStatus
    {
        return ABAddressBookGetAuthorizationStatus()
    }
    public func authorizationStatus() -> ABAuthorizationStatus
    {
        return AddressBook.authorizationStatus()
    }
    
    public func requestAuthorization(#completion: ABAddressBookRequestAccessCompletionHandler?)
    {
        logger.log("Requesting authorization...", forLevel: .Debug)
        
        if !self.isRequestingAuthorization {
            self.isRequestingAuthorization = true
            ABAddressBookRequestAccessWithCompletion(self.addressBookRef) { (granted, error) in
                if granted {
                    self.logger.log("Address book authorization granted.", forLevel: .Info)
                } else {
                    self.logger.log("Address book authorization denied.", forLevel: .Warning)
                }
                self.isRequestingAuthorization = false
                completion?(granted, error)
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(AddressBookAuthorizationStatusDidChangeNotification, object: self)
                }
            }
        } else {
            logger.log("Authorization request already in progress.", forLevel: .Debug)
        }
    }
    private var isRequestingAuthorization = false
    
    
    // MARK: Contacts Loading
    
    public func loadContacts(#completion: ((success: Bool) -> ())?)
    {
        switch self.status {
            
        case .NotLoaded, .Loaded:
            
            switch self.authorizationStatus() {
                
            case .Authorized:
                
                logger.log("Loading contacts ...", forLevel: .Debug)
                self.status = .Loading
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    let startDate = NSDate()
                    
                    // Load Contacts
                    var records: NSArray?
                    dispatch_sync(addressBookQueue) {
                        records = ABAddressBookCopyArrayOfAllPeople(self.addressBookRef).takeRetainedValue()
                    }
                    var contacts = [ABRecordID : C]()
                    var mergedRecords = [ABRecordRef]()
                    for record: ABRecordRef in records! {
                        if (mergedRecords as NSArray).containsObject(record) { // TODO: don't use NSArray
                            continue
                        }
                        
                        let contact = C(record: record)
                        
                        mergedRecords.extend(contact.linkedRecords)
                        contacts[contact.recordId] = contact
                    }
                    
                    self.logger.log("\(contacts.count) contacts loaded in \(NSDate().timeIntervalSinceDate(startDate))s.", forLevel: .Debug)
                    self.logger.log(contacts, forLevel: .Verbose)
                    
                    // Merge into database
                    /*if self.managedObjectContext != nil && self.managedObjectsType != nil {
                    self.mergeContacts(self.contacts!, andManagedObjectsOfType: self.managedObjectsType!, withManagedObjectContext: self.managedObjectContext!)
                    }*/
                    if let mergingOperationBlock = self._mergingOperationBlock {
                        mergingOperationBlock(contacts: contacts)
                    } else {
                        self.status = .Loaded(contacts)
                    }
                    
                    // Completion
                    completion?(success: true)
                }
                
            default:
                logger.log("Could not load contacts because authorization status is \(self.authorizationStatus())", forLevel: .Warning)
                completion?(success: false)
            }
            
        case .Loading:
            logger.log("Loading contacts already in progress.", forLevel: .Debug)
            completion?(success: false)

        case .Merging:
            logger.log("Contacts already loaded, but merging is in progress.", forLevel: .Debug)
            completion?(success: false)

        }
    }

}


// MARK: - Utility Subscripts

extension AddressBook {
    
    public subscript(#recordId: ABRecordID) -> C?
        {
            switch self.status {
            case .Loaded(let contacts):
                return contacts[recordId]
            case .Merging(let contacts):
                return contacts[recordId]
            default:
                return nil
            }
    }
    
}


// MARK: - External Change Callback

extension AddressBook {
    
    // TODO: This can't be called by notification center because it's not @objc, so has to be triggered externally
    public func addressBookDidChangeExternally(notification: NSNotification)
    {
        logger.log("Detected external address book change.", forLevel: .Debug)
        // TODO: handle cases better
        switch self.status {
        case .Loaded:
            self.loadContacts(completion: nil)
        default:
            break
        }
    }
    
}


// MARK: - Core Data Merging

private enum ChangeType {
    case Insert, Update, Delete
}

@objc public protocol AddressBookContactMergable {
    
    static var entityName: String { get }
    static var recordIdKeyPath: String { get }
    
    func mergeAddressBookContact(addressBookContact: AddressBookContact)
    
}

extension AddressBook {

    public func mergeContacts<M where M: NSManagedObject, M: AddressBookContactMergable>(contacts: [ABRecordID : C], andManagedObjectsOfType: M.Type, withManagedObjectContext managedObjectContext: NSManagedObjectContext)
    {
        self.logger.log("Merging contacts into database...", forLevel: .Debug)
        self.status = .Merging(contacts)
        let startDate = NSDate()

        // Merge contacts on MOC queue
        managedObjectContext.performBlockAndWait {
            
            // Get all managed contacts
            let fetchRequest = NSFetchRequest(entityName: M.entityName)
            fetchRequest.sortDescriptors = [ NSSortDescriptor(key: M.recordIdKeyPath, ascending: true) ]
            var fetchError: NSError?
            if let managedContacts = managedObjectContext.executeFetchRequest(fetchRequest, error: &fetchError) as? [NSManagedObject]
            {
                // Iterate through both contacts and managed contacts
                let contactsRecordIds = Array(contacts.keys).sorted(<)
                var i = (contactsIndex: 0, managedContactsIndex: 0)
                updateLoop: while true {
                    
                    // Determine change type
                    var changeType: ChangeType
                    switch i {
                    case (let contactsIndex, let managedContactsIndex) where contactsIndex > contacts.count - 1 && managedContactsIndex > managedContacts.count - 1:
                        break updateLoop
                    case (let contactsIndex, _) where contactsIndex > contacts.count - 1:
                        changeType = .Delete
                    case (_, let managedContactsIndex) where managedContactsIndex > managedContacts.count - 1:
                        changeType = .Insert
                    case (let contactsIndex, let managedContactsIndex) where contactsRecordIds[contactsIndex] == (managedContacts[managedContactsIndex].valueForKey(M.recordIdKeyPath)! as! NSNumber).intValue:
                        changeType = .Update
                    case (let contactsIndex, let managedContactsIndex) where contactsRecordIds[contactsIndex] < (managedContacts[managedContactsIndex].valueForKey(M.recordIdKeyPath)! as! NSNumber).intValue:
                        changeType = .Insert
                    case (let contactsIndex, let managedContactsIndex) where contactsRecordIds[contactsIndex] > (managedContacts[managedContactsIndex].valueForKey(M.recordIdKeyPath)! as! NSNumber).intValue:
                        changeType = .Delete
                    default:
                        self.logger.log("Index \(i) not handled correctly.", forLevel: .Warning)
                        break updateLoop
                    }
                    
                    // Apply change
                    switch changeType {
                    case .Insert:
                        let contact = contacts[contactsRecordIds[i.contactsIndex]]!
                        let insertedContact = NSEntityDescription.insertNewObjectForEntityForName(M.entityName, inManagedObjectContext: managedObjectContext) as! AddressBookContactMergable
                        insertedContact.mergeAddressBookContact(contact)
                        self.logger.log("Inserted contact \(contact).", forLevel: .Verbose)
                        i.contactsIndex += 1
                    case .Update:
                        let contact = contacts[contactsRecordIds[i.contactsIndex]]!
                        let managedContact = managedContacts[i.managedContactsIndex] as! AddressBookContactMergable
                        managedContact.mergeAddressBookContact(contact)
                        self.logger.log("Updated contact \(contact).", forLevel: .Verbose)
                        i.contactsIndex += 1
                        i.managedContactsIndex += 1
                    case .Delete:
                        let managedContact = managedContacts[i.managedContactsIndex]
                        managedObjectContext.deleteObject(managedContact)
                        self.logger.log("Deleted contact \(managedContact).", forLevel: .Verbose)
                        i.managedContactsIndex += 1
                    }
                }
            } else {
                self.logger.log("Failed to fetch managed contacts with error: \(fetchError)", forLevel: .Warning)
            }
            
            self.logger.log("Finished merging contacts in \(NSDate().timeIntervalSinceDate(startDate)) with \(managedObjectContext.insertedObjects.count) inserted, \(managedObjectContext.updatedObjects.count) updated and \(managedObjectContext.deletedObjects.count) deleted.", forLevel: .Debug)
            self.logger.log("Saving managed object context \(managedObjectContext)...", forLevel: .Debug)
            var saveError: NSError?
            if managedObjectContext.save(&saveError) {
                self.logger.log("Successfully saved managed object context \(managedObjectContext).", forLevel: .Debug)
            } else {
                self.logger.log("Failed to save managed object context with error: \(saveError)", forLevel: .Warning)
            }
        }
        
        self.status = .Loaded(contacts)
    }

}


// MARK: - Logging

extension AddressBook {

    public var logger: Logger {
        return VIAddressBookKit.logger.childForKeyPath("AddressBook")
    }

}
