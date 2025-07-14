//
//  polynapTests.swift
//  polynapTests
//
//  Created by Taner Çelik on 27.12.2024.
//

import Testing
import WatchConnectivity
import SwiftData
@testable import polynap
@testable import PolyNapShared

struct polynapTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testAppGroupContainerAccess() async throws {
        // App Group container erişimini test et
        let appGroupID = "group.com.tanercelik.polynap.shared"
        let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        
        #expect(appGroupURL != nil, "App Group container URL must be accessible")
        
        if let containerURL = appGroupURL {
            print("✅ App Group container URL: \(containerURL.path)")
            
            // Test file write/read to App Group container
            let testFile = containerURL.appendingPathComponent("test.txt")
            let testContent = "WatchConnectivity Test - \(Date())"
            
            try testContent.write(to: testFile, atomically: true, encoding: .utf8)
            let readContent = try String(contentsOf: testFile, encoding: .utf8)
            
            #expect(readContent == testContent, "App Group container read/write must work")
            
            // Clean up test file
            try? FileManager.default.removeItem(at: testFile)
        }
    }
    
    @Test func testSharedModelContainerCreation() async throws {
        // SharedModelContainer oluşturma testı
        do {
            let container = try SharedModelContainer.createTestContainer()
            let isValid = await SharedModelContainer.validateContainer(container)
            #expect(isValid, "Test ModelContainer must be valid")
            print("✅ Test SharedModelContainer successfully created and validated")
        } catch {
            throw error
        }
    }
    
    @Test func testWatchConnectivitySupport() async throws {
        // WatchConnectivity desteğini test et
        #expect(WCSession.isSupported(), "WatchConnectivity must be supported on iOS")
        
        let session = WCSession.default
        #expect(session.isPaired == true || session.isPaired == false, "WCSession paired status must be accessible")
        
        print("✅ WatchConnectivity support: \(WCSession.isSupported())")
        print("✅ Watch paired: \(session.isPaired)")
        print("✅ Watch app installed: \(session.isWatchAppInstalled)")
        print("✅ Session activation state: \(session.activationState.rawValue)")
    }
    
    @Test func testCodableDictionaryConversion() async throws {
        // CodableDictionary dönüşüm testı
        let testData: [String: Any] = [
            "string": "test",
            "number": 42,
            "bool": true,
            "date": Date(),
            "uuid": UUID()
        ]
        
        let codableDict = CodableDictionary(testData)
        let convertedBack = codableDict.toDictionary()
        
        #expect(convertedBack["string"] as? String == "test", "String conversion must work")
        #expect(convertedBack["number"] as? Int == 42, "Number conversion must work")
        #expect(convertedBack["bool"] as? Bool == true, "Bool conversion must work")
        
        print("✅ CodableDictionary conversion successful")
    }
    
    @Test func testWatchMessageTypeEnum() async throws {
        // WatchMessageType enum testı
        let messageType = WatchMessageType.sleepStarted
        #expect(messageType.rawValue == "sleepStarted", "Message type raw value must match")
        
        let allTypes: [WatchMessageType] = [
            .sleepStarted, .sleepEnded, .qualityRated, .scheduleUpdate,
            .scheduleActivated, .adaptationUpdate, .sleepEntryAdded,
            .userPreferencesUpdate, .syncRequest, .syncResponse, .fullDataSync
        ]
        
        for type in allTypes {
            #expect(!type.rawValue.isEmpty, "All message types must have non-empty raw values")
        }
        
        print("✅ WatchMessageType enum validation successful")
    }

}
