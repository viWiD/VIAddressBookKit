//
//  VIAddressBookTests.swift
//  VIOSFramework
//
//  Created by Nils Fischer on 17.08.14.
//  Copyright (c) 2014 viWiD Webdesign & iOS Development. All rights reserved.
//

import XCTest
import VIAddressBookKit

class VIAddressBookTests: XCTestCase {
    
    
    // MARK: Authorization
    
    // TODO: some weird error..
    /* func testAuthorization() {
        XCTAssert(VIAddressBook.authorizationStatus() == .Authorized, "Address Book access is not authorized.")
    } */
    
    
    // MARK: Loading Contacts
    
    class CustomAddressBookContact: VIAddressBookContact {
        var customFullName: String? {
            return fullName?.uppercaseString
        }
    }

    func testLoadingContacts() {
        let addressBook = VIAddressBook<VIAddressBookContact>()
        let contacts = addressBook.contacts
        XCTAssert(contacts != nil, "Unable to access contacts.")
    }
    
    func testLoadingCustomContacts() {
        let addressBook = VIAddressBook<CustomAddressBookContact>()
        let contacts = addressBook.contacts
        XCTAssert(contacts != nil, "Unable to access contacts with custom contact type.")
    }

}
