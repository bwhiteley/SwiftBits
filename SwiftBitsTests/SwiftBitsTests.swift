//
//  SwiftBitsTests.swift
//  SwiftBitsTests
//
//  Created by Bart Whiteley on 10/29/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

import XCTest
import Foundation
@testable import SwiftBits

class SwiftBitsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testResource() {
        
        let expectation = self.expectation(description: "load")
        
        URLSession.shared.load(usersResource) { usersResult in
            XCTAssertEqual(usersResult.value!.first!.id, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCombinedResource() {
        
        let expectation = self.expectation(description: "load")
        
        let combined = usersResource.c
            .flatMap { (users:[User]) -> CombinedResource<User> in
                let id = users.first!.id
                let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!
                return Resource<User>(get: url).c
        }
        
        URLSession.shared.load(combined) { usersResult in
            XCTAssertEqual(usersResult.value!.id, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testZippedResource() {
        
        let expectation = self.expectation(description: "load")
        
        let combined: CombinedResource<String> = usersResource.c
            .flatMap { (users:[User]) in
                let id1 = users.first!.id
                let id2 = users.last!.id
                let url1 = URL(string: "https://jsonplaceholder.typicode.com/users/\(id1)")!
                let url2 = URL(string: "https://jsonplaceholder.typicode.com/users/\(id2)")!
                return Resource<User>(get: url1).c
                    .zipWith(Resource<User>(get: url2).c) { user1, user2 -> String in
                        return "\(user1.id),\(user2.id)"
                }
        }
        
        URLSession.shared.load(combined) { usersResult in
            XCTAssertEqual(usersResult.value!, "1,10")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}

struct User: Decodable {
    let name: String
    let id: Int
    let username: String
}

let usersResource = Resource<[User]>(get: URL(string: "https://jsonplaceholder.typicode.com/users")!)

