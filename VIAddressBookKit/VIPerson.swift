//
//  VIPerson.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 16.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation
import UIKit

public class VIPerson {


    // MARK: Public Properties
    
    public var firstName: String?
    public var lastName: String?
    
    
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
    public class func leadingLastNameInitial(person: VIPerson) -> String? {
        return person.leadingLastNameInitial
    }
    
    // MARK: Initializers
    
    // TODO: required only to make address book work..
    public required init() {
        
    }
    
    public convenience init(firstName: String?, lastName: String?) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
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


// MARK: - Printable

extension VIPerson: Printable {
    
    public var description: String {
        let unnamedString = "Unnamed Person"
        return "\(fullName ?? unnamedString)"
    }
}


// MARK: - Comparison

extension VIPerson {
    
    public class func leadingLastNameIsOrderedBefore(obj1: VIPerson, _ obj2: VIPerson) -> Bool
    {
        if obj1.fullName == nil && obj2.fullName != nil {
            return false
        } else if obj1.fullName != nil && obj2.fullName == nil {
            return true
        } else if obj1.fullName == nil && obj2.fullName == nil {
            return true
        }
        let str1 = obj1.lastName ?? obj1.firstName!
        let str2 = obj2.lastName ?? obj2.firstName!
        return str1 < str2
    }

}
