//
//  CoreDataTestTests.swift
//  CoreDataTestTests
//
//  Created by Ross M Mooney on 10/22/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//

import XCTest
@testable import CoreDataTest

class CoreDataTestTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDataLoad() {
        let data = Data()
        
        let startTime = NSDate.timeIntervalSinceReferenceDate()
        data.loadData(20000)
        let endTime = NSDate.timeIntervalSinceReferenceDate()
        
        print("Time: \(endTime - startTime)")
    }
    

    
}
