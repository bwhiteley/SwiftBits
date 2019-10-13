//
//  File.swift
//  
//
//  Created by Bart Whiteley on 10/13/19.
//

import XCTest
@testable import SwiftBits

class AsyncPropertyTests: XCTestCase {
    
    var asyncProperty: AsyncProperty<Int, Error>!
    
    override func setUp() {
        super.setUp()
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.global().async {
                usleep(1_000)
                completion(.success(42))
            }
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGet() {
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.main.async {
                usleep(1_000)
                completion(.success(42))
            }
        }

        let expectation1 = expectation(description: "one")
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testMultipleGet() {
        
        let expectationLoad = expectation(description: "load")
        
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.global().async {
                usleep(1_000)
                completion(.success(42))
                expectationLoad.fulfill() // make sure this only runs once. 
            }
        }
        
        let expectation1 = expectation(description: "one")
        let expectation2 = expectation(description: "two")
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation1.fulfill()
        }
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
