//
//  AddressBookTests.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 17.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import XCTest
import VIAddressBookKit

class AddressBookTests: XCTestCase {
    
    
    // MARK: Authorization
    
    // TODO: some weird error..
    /* func testAuthorization() {
        XCTAssert(AddressBook.authorizationStatus() == .Authorized, "Address Book access is not authorized.")
    } */
    
    
    // MARK: Loading Contacts
    
    class CustomAddressBookContact: AddressBookContact {
        var customFullName: String? {
            return fullName?.uppercaseString
        }
    }

    func testLoadingContacts() {
        let addressBook = AddressBook<AddressBookContact>()
        let contacts = addressBook.contacts
        XCTAssert(contacts != nil, "Unable to access contacts.")
    }
    
    func testLoadingCustomContacts() {
        let addressBook = AddressBook<CustomAddressBookContact>()
        let contacts = addressBook.contacts
        XCTAssert(contacts != nil, "Unable to access contacts with custom contact type.")
    }

}
