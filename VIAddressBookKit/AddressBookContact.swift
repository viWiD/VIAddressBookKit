//
//  AddressBookContact.swift
//  VIAddressBookKit
//
//  Created by Nils Fischer on 22.10.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation
import Evergreen


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
    
    public override var firstName: String? {
        get {
            return self._firstName
        }
        set {
            _firstName = newValue
        }
    }
    private lazy var _firstName: String? = {
        return self.valueForProperty(kABPersonFirstNameProperty)
        }()
    
    public override var lastName: String? {
        get {
            return self._lastName
        }
        set {
            _lastName = newValue
        }
    }
    private lazy var _lastName: String? = {
        return self.valueForProperty(kABPersonLastNameProperty)
        }()
    
    public lazy var organisationName: String? = {
        return self.valueForProperty(kABPersonOrganizationProperty)
        }()
    
    private lazy var kind: CFNumber? = {
        return self.valueForProperty(kABPersonKindProperty)
        }()
    
    public override var fullName: String? {
        get {
            return self._fullName
        }
        set {
            _fullName = newValue
        }
    }
    private lazy var _fullName: String? = {
        return ABRecordCopyCompositeName(self.record).takeRetainedValue()
        }() as String
    
    override public var alphabeticOrderingString: String? {
        var alphabeticOrderingString: String?
        if self.kind != nil && self.kind! == kABPersonKindOrganization {
            alphabeticOrderingString = self.organisationName
        } else {
            switch ABPersonGetSortOrdering() {
            case 0: // TODO: use proper names when refactored in AddressBook Framework API
                alphabeticOrderingString = self.firstName ?? self.lastName
            default:
                alphabeticOrderingString = self.lastName ?? self.firstName
            }
        }
        if let alphabeticOrderingString = alphabeticOrderingString {
            // Remove diacritics
            return "".join(alphabeticOrderingString.decomposedStringWithCanonicalMapping.componentsSeparatedByCharactersInSet(NSCharacterSet.letterCharacterSet().invertedSet))
        } else {
            return nil
        }
    }
    
    public lazy var birthday: NSDate? = {
        if let birthday: NSDate = self.valueForProperty(kABPersonBirthdayProperty) {
            if NSCalendar(calendarIdentifier: NSGregorianCalendar)!.component(.YearCalendarUnit, fromDate: birthday) != 1604 {
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
        self.linkedRecords = linkedRecords as [ABRecordRef]
        super.init()
    }
    
    
    // MARK: Value Extraction
    
    private func valueForProperty<T>(property: ABPropertyID) -> T? {
        var r: T?
        dispatch_sync(addressBookQueue) {
            for record in self.linkedRecords {
                if let value = ABRecordCopyValue(record, property)?.takeRetainedValue() as? T {
                    self.logger.log("Extracted property \(property) from record \(record) and got \(value)", forLevel: .Verbose)
                    r = value
                    return
                }
            }
        }
        return r
    }
    private func imageValueWithFormat(format: ABPersonImageFormat) -> UIImage? {
        var r: UIImage?
        dispatch_sync(addressBookQueue) {
            for record in self.linkedRecords {
                if let imageData = ABPersonCopyImageDataWithFormat(record, format)?.takeRetainedValue() {
                    self.logger.log("Extracted image with format \(format) from record \(record).", forLevel: .Verbose)
                    r = UIImage(data: imageData)
                    return
                }
            }
        }
        return r
    }
}


// MARK: - Equatable

extension AddressBookContact: Equatable {}

public func ==(lhs: AddressBookContact, rhs: AddressBookContact) -> Bool {
    return lhs.recordId == rhs.recordId
}

extension AddressBookContact {
    
    public var logger: Logger {
        return VIAddressBookKit.logger.childForKeyPath("AddressBook.AddressBookContact")
    }
    
}
