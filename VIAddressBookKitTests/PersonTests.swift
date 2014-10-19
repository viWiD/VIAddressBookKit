//
//  PersonTests.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 17.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import XCTest
import VIAddressBookKit

class PersonTests: XCTestCase {
    
    
    // MARK: Full Name
    
    func testFullNameWithBothNamesProvided() {
        let firstName = "Alice"
        let lastName = "Ecila"
        let person = Person(firstName: firstName, lastName: lastName)
        XCTAssertNotNil(person.fullName, "Person's full name is nil, although both names were provided")
        XCTAssert(person.fullName! == firstName + " " + lastName, "Person's full name is \(person.fullName) and not \(firstName) \(lastName) (with both names provided)")
    }
    
    func testFullNameWithOnlyFirstNameProvided() {
        let firstName = "Alica"
        let person = Person(firstName: firstName, lastName: nil)
        XCTAssertNotNil(person.fullName, "Person's full name is nil, although first name was provided")
        XCTAssert(person.fullName! == firstName, "Person's full name is \(person.fullName) and not \(firstName) (with only first name provided)")
    }
    
    func testFullNameWithOnlyLastNameProvided() {
        let lastName = "Ecila"
        let person = Person(firstName: nil, lastName: lastName)
        XCTAssertNotNil(person.fullName, "Person's full name is nil, although last name was provided")
        XCTAssert(person.fullName! == lastName, "Person's full name is \(person.fullName) and not \(lastName) (with only last name provided)")
    }
    
    
    // MARK: Comparisons
    
    func testLeadingLastNameOrdering() {
        let person1 = Person(firstName: "Alice", lastName: nil)
        let person2 = Person(firstName: "Xavier", lastName: "Bob")
        let person3 = Person(firstName: nil, lastName: "Chen")
        let person4 = Person(firstName: "David", lastName: "Drey")
        let nilPerson = Person()
        XCTAssertTrue(isOrderedAlphabetically(person1, person2), "Incorrect ordering: \(person1) should be before \(person2)")
        XCTAssertTrue(isOrderedAlphabetically(person2, person3), "Incorrect ordering: \(person2) should be before \(person3)")
        XCTAssertTrue(isOrderedAlphabetically(person3, person4), "Incorrect ordering: \(person3) should be before \(person4)")
        XCTAssertTrue(isOrderedAlphabetically(person1, nilPerson), "Incorrect ordering: \(person1) should be before \(nilPerson)")
    }

}
