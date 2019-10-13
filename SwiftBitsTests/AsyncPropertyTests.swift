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
    
    func testLoad() {
        let expectationLoad = expectation(description: "load")
        
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.global().async {
                usleep(1_000)
                completion(.success(42))
                expectationLoad.fulfill() // make sure this only runs once.
            }
        }
        
        asyncProperty.load()
        
        let expectation1 = expectation(description: "one")
        let expectation2 = expectation(description: "two")
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation1.fulfill()
        }
        asyncProperty.load() // shouldn't do anything
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testReload() {
        let expectationLoad1 = expectation(description: "load1")
        let expectationLoad2 = expectation(description: "load2")

        var loadCount: Int = 0
        
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.global().async {
                usleep(1_000)
                if loadCount == 0 {
                    completion(.success(42))
                    expectationLoad1.fulfill() // make sure this only runs once.
                    loadCount += 1
                }
                else if loadCount == 1 {
                    completion(.success(47))
                    expectationLoad2.fulfill() // make sure this only runs once.
                }
            }
        }
        
        asyncProperty.load()
        
        let expectation1 = expectation(description: "one")
        let expectation2 = expectation(description: "two")
        let expectation3 = expectation(description: "three")
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation1.fulfill()
        }
        asyncProperty.load() // shouldn't do anything
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation2.fulfill()
        }
        usleep(3000)
        asyncProperty.reload()
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 47)
            expectation3.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testReset() {
        let expectationLoad1 = expectation(description: "load1")
        let expectationLoad2 = expectation(description: "load2")

        var loadCount: Int = 0
        
        self.asyncProperty = AsyncProperty() { (completion:@escaping (Result<Int, Error>) -> Void) in
            DispatchQueue.global().async {
                usleep(1_000)
                if loadCount == 0 {
                    completion(.success(42))
                    expectationLoad1.fulfill() // make sure this only runs once.
                    loadCount += 1
                }
                else if loadCount == 1 {
                    completion(.success(47))
                    expectationLoad2.fulfill() // make sure this only runs once.
                }
            }
        }
        
        asyncProperty.load()
        
        let expectation1 = expectation(description: "one")
        let expectation2 = expectation(description: "two")
        let expectation3 = expectation(description: "three")
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation1.fulfill()
        }
        asyncProperty.load() // shouldn't do anything
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 42)
            expectation2.fulfill()
        }
        usleep(3000)
        asyncProperty.reload()
        asyncProperty.get { result in
            let value = try? result.get()
            XCTAssertEqual(value, 47)
            expectation3.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
