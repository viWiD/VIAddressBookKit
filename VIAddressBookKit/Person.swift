//
//  Person.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 16.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation
import UIKit

public class Person {


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
        if lastName != nil && countElements(lastName!) > 0 {
            // TODO: use String instead of NSString
            return (lastName! as NSString).substringToIndex(1).capitalizedString
        } else if firstName != nil && countElements(firstName!) > 0 {
            return (firstName! as NSString).substringToIndex(1).capitalizedString
            }
            return nil
    }
    public class func leadingLastNameInitial(person: Person) -> String? {
        return person.leadingLastNameInitial
    }
    
    
    // MARK: Interface Output
    // TODO: move somewhere else?
    
    public func attributedFullNameOfSize(fontSize: CGFloat) -> NSAttributedString?
    {
        if let fullName = self.fullName {
            var attributedName = NSMutableAttributedString(string: fullName)
            attributedName.beginEditing()
            if lastName != nil {
                var beginBoldFont = firstName != nil ? countElements(firstName!) : 0
                if beginBoldFont > 0 {
                    beginBoldFont++
                }
                attributedName.addAttribute(NSFontAttributeName, value:UIFont.boldSystemFontOfSize(fontSize), range:NSMakeRange(beginBoldFont, countElements(lastName!)))
            } else {
                attributedName.addAttribute(NSFontAttributeName, value:UIFont.boldSystemFontOfSize(fontSize), range:NSMakeRange(0, countElements(firstName!)))
            }
            attributedName.endEditing()
            return attributedName
        } else {
            return nil
        }
    }
    
}


// MARK: - Comparison

extension Person: AlphabeticOrdering {
    
    public var alphabeticOrderingString: String? {
        return self.lastName ?? self.firstName ?? nil
    }

}


// MARK: - Printable

extension Person: Printable {
    
    public var description: String {
        let unnamedString = "Unnamed Person"
        return "\(fullName ?? unnamedString)"
    }
}
