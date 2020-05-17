//
//  HookContextSingleInstancesAfterTests.swift
//  SwiftHookTests
//
//  Created by Yanni Wang on 13/5/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

import XCTest
@testable import SwiftHook

class HookContextSingleInstancesAfterTests: XCTestCase {

    func testNormal() {
        do {
            let contextCount = HookManager.shared.debugToolsGetHookContextsCount()
            let hookedTestObject = TestObject()
            let nonHookTestObject = TestObject()
            var result = [Int]()
            
            try autoreleasepool {
                // hook
                let selector = #selector(TestObject.execute(closure:))
                let mode: HookMode = .after
                let closure = {
                    XCTAssertEqual(result, [2])
                    result.append(1)
                    } as @convention(block) () -> Void
                let hookContext = try HookManager.shared.hook(object: hookedTestObject, selector: selector, mode: mode, hookClosure: closure as AnyObject)
                XCTAssertEqual(HookManager.shared.debugToolsGetHookContextsCount(), contextCount + 2)
                
                // test hook
                XCTAssertEqual(result, [])
                hookedTestObject.execute {
                    XCTAssertEqual(result, [])
                    result.append(2)
                }
                XCTAssertEqual(result, [2, 1])
                
                nonHookTestObject.execute {
                    XCTAssertEqual(result, [2, 1])
                    result.append(3)
                    XCTAssertEqual(result, [2, 1, 3])
                }
                XCTAssertEqual(result, [2, 1, 3])
                
                // cancel
                XCTAssertTrue(try isDynamicClass(object: hookedTestObject))
                XCTAssertTrue(hookContext.cancelHook()!)
                result.removeAll()
            }
            
            // test cancel
            XCTAssertFalse(try isDynamicClass(object: hookedTestObject))
            hookedTestObject.execute {
                XCTAssertEqual(result, [])
                result.append(2)
            }
            XCTAssertEqual(result, [2])
            XCTAssertEqual(HookManager.shared.debugToolsGetHookContextsCount(), contextCount)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testCheckArguments() {
        do {
            let contextCount = HookManager.shared.debugToolsGetHookContextsCount()
            let test = TestObject()
            let argumentA = 77
            let argumentB = 88
            var executed = false
            
            try autoreleasepool {
                // hook
                let selector = #selector(TestObject.sumFunc(a:b:))
                let mode: HookMode = .after
                let closure = { a, b in
                    XCTAssertEqual(argumentA, a)
                    XCTAssertEqual(argumentB, b)
                    executed = true
                    } as @convention(block) (Int, Int) -> Void
                let hookContext = try HookManager.shared.hook(object: test, selector: selector, mode: mode, hookClosure: closure as AnyObject)
                XCTAssertEqual(HookManager.shared.debugToolsGetHookContextsCount(), contextCount + 2)
                
                // test hook
                let result = test.sumFunc(a: argumentA, b: argumentB)
                XCTAssertEqual(result, argumentA + argumentB)
                XCTAssertTrue(executed)
                
                // cancel
                XCTAssertTrue(try isDynamicClass(object: test))
                XCTAssertTrue(hookContext.cancelHook()!)
            }
            
            // test cancel
            XCTAssertFalse(try isDynamicClass(object: test))
            executed = false
            let result = test.sumFunc(a: argumentA, b: argumentB)
            XCTAssertEqual(result, argumentA + argumentB)
            XCTAssertFalse(executed)
            XCTAssertEqual(HookManager.shared.debugToolsGetHookContextsCount(), contextCount)
        } catch {
            XCTAssertNil(error)
        }
    }
    
}
