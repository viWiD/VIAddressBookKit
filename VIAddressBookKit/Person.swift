//
//  Person.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 16.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation
import UIKit

@objc public class Person: AlphabeticOrdering {


    // MARK: Public Properties
    
    public var firstName: String?
    public var lastName: String?
    
    
    // MARK: Initializers
    
    public init() {}
    
    public convenience init(firstName: String?, lastName: String?) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
    }
    
    
    // MARK: Computed Properties
    
    public var fullName: String? {
        if firstName == nil {
            return lastName
        } else if lastName == nil {
            return firstName
        } else {
            return "\(firstName!) \(lastName!)"
        }
    }
    
    // TODO: char instead of string?
    public var leadingLastNameInitial: String? {
        if lastName != nil && count(lastName!) > 0 {
            // TODO: use String instead of NSString
            return (lastName! as NSString).substringToIndex(1).capitalizedString
        } else if firstName != nil && count(firstName!) > 0 {
            return (firstName! as NSString).substringToIndex(1).capitalizedString
            }
            return nil
    }
    public class func leadingLastNameInitial(person: Person) -> String? {
        return person.leadingLastNameInitial
    }
    

    // MARK: - Comparison
    
    public var alphabeticOrderingString: String? {
        if let alphabeticOrderingString = self.lastName ?? self.firstName ?? nil {
            // Remove diacritics
            return "".join(alphabeticOrderingString.decomposedStringWithCanonicalMapping.componentsSeparatedByCharactersInSet(NSCharacterSet.letterCharacterSet().invertedSet))
        } else {
            return nil
        }

    }
    
}



// MARK: - Printable

extension Person: Printable {
    
    public var description: String {
        let unnamedString = "Unnamed Person"
        return "\(fullName ?? unnamedString)"
    }
}
