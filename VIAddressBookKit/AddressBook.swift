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

public let AddressBookDidChangeExternallyNotification = "AddressBookDidChangeExternallyNotification"
public let VIChangedAddressBookContacts = "VIChangedAddressBookContacts"

public class AddressBook<C: AddressBookContact> {
    
    private lazy var addressBookRef: ABAddressBookRef = {
        var addressBookRef: ABAddressBookRef?
        self.addressBookQueue.addOperations([ NSBlockOperation(block: {
            addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
            
            // TODO: register external change callback, http://stackoverflow.com/questions/25346563/address-book-external-change-callback-in-swift-with-c-function-pointers
            
        }) ], waitUntilFinished: true)
        if let addressBookRef: ABAddressBookRef = addressBookRef {
            return addressBookRef
        } else {
            self.logger.log("Could not create ABAddressBookRef.", forLevel: .Critical)
            return addressBookRef!
        }
    }()
    
    private lazy var addressBookQueue = NSOperationQueue()

    public private(set) var contacts: [C]?

    
    // MARK: Initializers

    public init() {
        
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
    
    public func requestAuthorization(completion: ABAddressBookRequestAccessCompletionHandler?)
    {
        logger.log("Requesting authorization...", forLevel: .Debug)
        
        if !self.isRequestingAuthorization {
            self.isRequestingAuthorization = true
            self.addressBookQueue.addOperation(NSBlockOperation(block: {
                
                ABAddressBookRequestAccessWithCompletion(self.addressBookRef) { (granted, error) in
                    if granted {
                        self.logger.log("Address book authorization granted.", forLevel: .Info)
                    } else {
                        self.logger.log("Address book authorization denied.", forLevel: .Warning)
                    }
                    self.isRequestingAuthorization = false
                    if let completion = completion {
                        completion(granted, error)
                    }
                }

            }))
        } else {
            logger.log("Authorization request already in progress.", forLevel: .Debug)
        }
    }
    private var isRequestingAuthorization = false
    
    
    // MARK: Contacts Loading
    
    public func loadContacts(completion: ((contacts: [C]?) -> ())?)
    {
        logger.log("Loading contacts ...", forLevel: .Debug)

        if let contacts = self.contacts {
            logger.log("Contacts already loaded.", forLevel: .Debug)
            if let completion = completion {
                completion(contacts: contacts)
            }
        } else {
        
            let authorizationStatus = self.authorizationStatus()
            switch authorizationStatus {
                
            case .Authorized:
                
                if !contains(addressBookQueue.operations as [NSOperation], loadingOperation) && !loadingOperation.finished {
                    
                    addressBookQueue.addOperation(loadingOperation)
                    
                    if let completion = completion {
                        let completionOperation = NSBlockOperation(block: {
                            completion(contacts: self.contacts)
                        })
                        completionOperation.addDependency(loadingOperation)
                        addressBookQueue.addOperation(completionOperation)
                    }
                } else {
                    logger.log("Loading contacts already in progress.", forLevel: .Debug)
                    if let completion = completion {
                        completion(contacts: self.contacts)
                    }
                }
                
            default:
                logger.log("Could not load contacts because authorization status is \(authorizationStatus)", forLevel: .Warning)
                if let completion = completion {
                    completion(contacts: self.contacts)
                }
            }
        }
    }
    
    private lazy var loadingOperation: NSBlockOperation = {
        let loadingOperation = NSBlockOperation(block: {

            let startDate = NSDate()
            
            var records: NSArray = ABAddressBookCopyArrayOfAllPeople(self.addressBookRef).takeRetainedValue()
            var contacts = [C]()
            var mergedRecords = [ABRecordRef]()
            for record: ABRecordRef in records {
                // TODO: don't use NSArray
                if (mergedRecords as NSArray).containsObject(record) {
                    continue
                }
                
                let contact = C(record: record)
                
                mergedRecords.extend(contact.linkedRecords)
                contacts.append(contact)
            }
            self.contacts = contacts
            self.logger.log("\(contacts.count) contacts loaded in \(NSDate().timeIntervalSinceDate(startDate))s.", forLevel: .Debug)
            self.logger.log(contacts, forLevel: .Verbose)

        })
        return loadingOperation
    }()
    
}


// MARK: - Address Book Contact

public class AddressBookContact: Person {
    
    
    /// All address book records linked to this contact
    public private(set) var linkedRecords: [ABRecordRef]

    /// The address book record representing this contact
    public var record: ABRecordRef {
        return linkedRecords.first!
    }

    /// The representing address book record's id
    public var recordId: ABRecordID {
        return ABRecordGetRecordID(self.record)
    }
    
    
    // MARK: Contact Properties
    
    public override lazy var firstName: String? = {
        return self.valueForProperty(kABPersonFirstNameProperty)
    }()
    
    public override lazy var lastName: String? = {
        return self.valueForProperty(kABPersonLastNameProperty)
    }()
    
    public lazy var birthday: NSDate? = {
        if let birthday: NSDate = self.valueForProperty(kABPersonBirthdayProperty) {
            if NSCalendar(calendarIdentifier: NSGregorianCalendar).component(.YearCalendarUnit, fromDate: birthday) != 1604 {
                return birthday
            } else {
                return nil
            }
        } else {
            return nil
        }
    }()
    
    public lazy var pictureThumbnail: UIImage? = {
        return self.imageValueWithFormat(kABPersonImageFormatThumbnail)
    }()
    
    public lazy var picture: UIImage? = {
        return self.imageValueWithFormat(kABPersonImageFormatOriginalSize)
    }()
    
    
    // MARK: Initializers
    
    // TODO: remove required and make internal (crash when using a subclass and then doing type casting later)
    required public init(record: ABRecordRef) {
        let linkedRecords: NSArray = ABPersonCopyArrayOfAllLinkedPeople(record).takeRetainedValue()
        self.linkedRecords = linkedRecords
        super.init()
    }
    
    
    // MARK: Value Extraction
    
    private func valueForProperty<T>(property: ABPropertyID) -> T? {
        for record in linkedRecords {
            if let value = ABRecordCopyValue(record, property)?.takeRetainedValue() as? T {
                logger.log("Extracted property \(property) from record \(record) and got \(value)", forLevel: .Verbose)
                return value
            }
        }
        return nil
    }
    private func imageValueWithFormat(format: ABPersonImageFormat) -> UIImage? {
        for record in linkedRecords {
            if let imageData = ABPersonCopyImageDataWithFormat(record, format)?.takeRetainedValue() {
                logger.log("Extracted image with format \(format) from record \(record).", forLevel: .Verbose)
                return UIImage(data: imageData)
            }
        }
        return nil
    }
}


// MARK: - Equatable

/*extension AddressBookContact: Equatable {}

public func ==(lhs: AddressBookContact, rhs: AddressBookContact) -> Bool
{
    return lhs.recordId == rhs.recordId
}*/


// MARK: - Utility Subscripts

extension AddressBook {
    
    public subscript(recordId: ABRecordID) -> C?
    {
        return contacts?.filter({ contact in
            return contact.recordId == recordId
        }).first
    }
    
}


// MARK: - Logging

public var logger: Logger {
    return Logger.loggerForKeyPath("VIAddressBookKit")
}

extension AddressBook {

    public var logger: Logger {
        return Logger.loggerForKeyPath("VIAddressBookKit.AddressBook")
    }

}

extension AddressBookContact {

    public var logger: Logger {
        return Logger.loggerForKeyPath("VIAddressBookKit.AddressBook.AddressBookContact")
    }

}
