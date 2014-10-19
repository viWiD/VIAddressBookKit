//
//  AlphabeticOrdering.swift
//  VIAddressBookKit
//
//  Created by Nils Fischer on 09.10.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import Foundation

/* TODO: remove @objc flag when this works without runtime exception:
protocol P {}
class Foo: P {}

let foos = [ Foo() ]
let ps: [P] = foos // Casting here requires protocol conformance check which is only available for @objc protocols
*/
@objc public protocol AlphabeticOrdering {
    
    var alphabeticOrderingString: String? { get }
}

public func isOrderedAlphabetically(lhs: AlphabeticOrdering, rhs: AlphabeticOrdering) -> Bool
{
    let a = lhs.alphabeticOrderingString
    let b = rhs.alphabeticOrderingString
    if let rhsAlphabeticOrderingString = rhs.alphabeticOrderingString {
        if let lhsAlphabeticOrderingString = lhs.alphabeticOrderingString {
            return lhsAlphabeticOrderingString < rhsAlphabeticOrderingString
        } else {
            return false
        }
    } else {
        return true
    }
}

public func alphabeticSectioningLetter(element: AlphabeticOrdering) -> String?
{
    if let orderingString = element.alphabeticOrderingString {
        return orderingString.substringToIndex(advance(orderingString.startIndex, 1)).uppercaseString
    } else {
        return nil
    }
}
