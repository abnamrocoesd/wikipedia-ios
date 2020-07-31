
import XCTest
@testable import WMF

class LegacyService {
    static let shared: EventLoggingService = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        return EventLoggingService(session: Session.shared, permanentStorageURL: randomURL)!
    }()
}

class EPCStorageManagerTests: XCTestCase {
    
    let temporaryStorageManager: EPCStorageManager = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        guard let storageManager = EPCStorageManager(permanentStorageURL: randomURL, legacyEventLoggingService: LegacyService.shared, postBatchSize: 5) else {
            XCTFail("Failure initializing temporaryStorageManager.")
            fatalError()
        }
        
        return storageManager
    }()
    
    let temporaryNonCachingStorageManager: EPCStorageManager = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        guard let storageManager = EPCStorageManager(permanentStorageURL: randomURL, cachesLibraryValues: false, legacyEventLoggingService: LegacyService.shared, postBatchSize: 5) else {
            XCTFail("Failure initializing temporaryStorageManager.")
            fatalError()
        }
        
        return storageManager
    }()
    
    let eventGateURI: URL = URL(string: "https://intake-analytics.wikimedia.org/v1/events")!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSavingSomeEvents() throws {
        
        let key = "epc_input_buffer"
        
        let dict1: [String: NSCoding] = [
            "question1": "answer1" as NSCoding,
            "question2": 1 as NSCoding]
        let dict2: [String: NSCoding] = [
            "question3": "answer3" as NSCoding,
            "question4": 2 as NSCoding]
        
        let event1 = EPCEvent(stream: "stream1", schema: "schema1", data: dict1, domain: nil)
        
        let event2 = EPCEvent(stream: "stream2", schema: "schema2", data: dict2, domain: "es")
        
        let buffer = NSArray(array: [event1, event2])
        temporaryStorageManager.setPersisted(key, buffer)
        
        guard let result = temporaryStorageManager.getPersisted(key),
            let events = result as? [EPCEvent] else {
            XCTFail("Unrecognized format of WMFKeyValue value")
            return
        }
        
        XCTAssertEqual(events.count, 2)
        let firstEvent = events[0];
        let secondEvent = events[1];
        XCTAssertEqual(firstEvent.stream, "stream1")
        XCTAssertEqual(firstEvent.schema, "schema1")
        XCTAssertEqual(firstEvent.data["question1"] as? String, "answer1")
        XCTAssertEqual(firstEvent.data["question2"] as? Int, 1)
        XCTAssertEqual(firstEvent.domain, nil)
        
        XCTAssertEqual(secondEvent.stream, "stream2")
        XCTAssertEqual(secondEvent.schema, "schema2")
        XCTAssertEqual(secondEvent.data["question3"] as? String, "answer3")
        XCTAssertEqual(secondEvent.data["question4"] as? Int, 2)
        XCTAssertEqual(secondEvent.domain, "es")
    }
    
    func testSavingSomeEventsWithoutCaching() throws {
        
        let key = "epc_input_buffer"
        
        let dict1: [String: NSCoding] = [
            "question1": "answer1" as NSCoding,
            "question2": 1 as NSCoding]
        let dict2: [String: NSCoding] = [
            "question3": "answer3" as NSCoding,
            "question4": 2 as NSCoding]
        
        let event1 = EPCEvent(stream: "stream1", schema: "schema1", data: dict1, domain: nil)
        
        let event2 = EPCEvent(stream: "stream2", schema: "schema2", data: dict2, domain: "es")
        
        let buffer = NSArray(array: [event1, event2])
        temporaryNonCachingStorageManager.setPersisted(key, buffer)
        
        guard let result = temporaryNonCachingStorageManager.getPersisted(key),
            let events = result as? [EPCEvent] else {
            XCTFail("Unrecognized format of WMFKeyValue value")
            return
        }
        
        XCTAssertEqual(events.count, 2)
        let firstEvent = events[0];
        let secondEvent = events[1];
        XCTAssertEqual(firstEvent.stream, "stream1")
        XCTAssertEqual(firstEvent.schema, "schema1")
        XCTAssertEqual(firstEvent.data["question1"] as? String, "answer1")
        XCTAssertEqual(firstEvent.data["question2"] as? Int, 1)
        XCTAssertEqual(firstEvent.domain, nil)
        
        XCTAssertEqual(secondEvent.stream, "stream2")
        XCTAssertEqual(secondEvent.schema, "schema2")
        XCTAssertEqual(secondEvent.data["question3"] as? String, "answer3")
        XCTAssertEqual(secondEvent.data["question4"] as? Int, 2)
        XCTAssertEqual(secondEvent.domain, "es")
    }

    func testDeletingSomeEvents() throws {
        
        let key = "epc_input_buffer"
        
        let dict1: [String: NSCoding] = [
            "question1": "answer1" as NSCoding,
            "question2": 1 as NSCoding]
        let dict2: [String: NSCoding] = [
            "question3": "answer3" as NSCoding,
            "question4": 2 as NSCoding]
        
        let event1 = EPCEvent(stream: "stream1", schema: "schema1", data: dict1, domain: nil)
        
        let event2 = EPCEvent(stream: "stream2", schema: "schema2", data: dict2, domain: "es")
        
        let buffer = NSArray(array: [event1, event2])
        temporaryStorageManager.setPersisted(key, buffer)
        
        guard let result = temporaryStorageManager.getPersisted(key),
            let events = result as? [EPCEvent] else {
            XCTFail("Unrecognized format of WMFKeyValue value")
            return
        }
        
        XCTAssertEqual(events.count, 2)
        
        temporaryStorageManager.deletePersisted(key)
        
        XCTAssertNil(temporaryStorageManager.getPersisted(key),"WMFKeyValue has value after deletion")
    }
    
    func testDeletingSomeEventsWithoutCaching() throws {
        
        let key = "epc_input_buffer"
        
        let dict1: [String: NSCoding] = [
            "question1": "answer1" as NSCoding,
            "question2": 1 as NSCoding]
        let dict2: [String: NSCoding] = [
            "question3": "answer3" as NSCoding,
            "question4": 2 as NSCoding]
        
        let event1 = EPCEvent(stream: "stream1", schema: "schema1", data: dict1, domain: nil)
        
        let event2 = EPCEvent(stream: "stream2", schema: "schema2", data: dict2, domain: "es")
        
        let buffer = NSArray(array: [event1, event2])
        temporaryNonCachingStorageManager.setPersisted(key, buffer)
        
        guard let result = temporaryNonCachingStorageManager.getPersisted(key),
            let events = result as? [EPCEvent] else {
            XCTFail("Unrecognized format of WMFKeyValue value")
            return
        }
        
        XCTAssertEqual(events.count, 2)
        
        temporaryNonCachingStorageManager.deletePersisted(key)
        
        XCTAssertNil(temporaryNonCachingStorageManager.getPersisted(key),"WMFKeyValue has value after deletion")
    }
    
    func testDeviceIDMatchesLegacyDeviceID() {
        
        let deviceID = temporaryStorageManager.deviceID
        let legacyDeviceID = LegacyService.shared.appInstallID
        
        XCTAssertNotNil(deviceID)
        XCTAssertNotNil(legacyDeviceID)
        XCTAssertEqual(deviceID, legacyDeviceID)
    }
    
    private func generatePostBody(index: Int) -> [String: NSCoding] {
        guard let deviceID = temporaryStorageManager.deviceID else {
            XCTFail("Missing Device ID")
            return [:]
        }
        
        let meta: [String: NSCoding] = [
            "domain": "en" as NSCoding
        ]
        
        let body: [String: NSCoding] = [
            "question\(index)": "answer\(index)" as NSCoding,
            "meta": meta as NSCoding,
            "client_dt": ISO8601DateFormatter().string(from: Date()) as NSCoding,
            "session_id": "\(index)" as NSCoding,
            "device_id": deviceID as NSCoding,
            "schema": "schemaValue\(index)" as NSCoding,
            "stream": "streamValue\(index)" as NSCoding,
            "id": UUID().uuidString as NSCoding
        ]
        return body
    }
    
    func testSavePostItem() {
        
        guard let deviceID = temporaryStorageManager.deviceID else {
            XCTFail("Missing Device ID")
            return
        }

        let body: [String: NSCoding] = generatePostBody(index: 1)
        
        temporaryStorageManager.createAndSavePostItem(with: self.eventGateURI, body: body as NSDictionary)
        
        let moc = temporaryStorageManager.managedObjectContextToTest
        
        moc.performAndWait {
            var results: [EPCPost] = []
            let fetch: NSFetchRequest<EPCPost> = EPCPost.fetchRequest()
            do {
                results = try moc.fetch(fetch)
            } catch let error {
                XCTFail("Failure fetching EPCPost results \(error)")
            }
            
            XCTAssertEqual(results.count, 1)
            let firstResult = results.first!
            
            XCTAssertEqual(firstResult.url, self.eventGateURI)
            XCTAssertNotNil(firstResult.recorded)
            XCTAssertNil(firstResult.posted)
            XCTAssertFalse(firstResult.failed)
            XCTAssertEqual(firstResult.userAgent, WikipediaAppUtils.versionedUserAgent())
            
            guard let body = firstResult.body as? [String: NSCoding],
                let meta = body["meta"] as? [String: NSCoding] else {
                XCTFail("Unrecognized body type")
                return
            }
            
            XCTAssertEqual(body["question1"] as? String, "answer1")
            XCTAssertEqual(meta["domain"] as? String, "en")
            XCTAssertNotNil(body["client_dt"])
            XCTAssertEqual(body["session_id"] as? String, "1")
            XCTAssertEqual(body["device_id"] as? String, deviceID)
            XCTAssertEqual(body["schema"] as? String, "schemaValue1")
            XCTAssertEqual(body["stream"] as? String, "streamValue1")
            XCTAssertNotNil(body["id"])
        }
    }
    
    func testFetchPostItems() {
        
        for i in 0..<10 {
            
            let body = generatePostBody(index: i)
            temporaryStorageManager.createAndSavePostItem(with: self.eventGateURI, body: body as NSDictionary)
        }
        
        let moc = temporaryStorageManager.managedObjectContextToTest
        
        let results = temporaryStorageManager.fetchPostItemsToPost()
        XCTAssertEqual(results.count, 5)
        
        moc.performAndWait {
            let lastResult = results.last!
            
            guard let body = lastResult.body as? [String: NSCoding] else {
                XCTFail("Unrecognized body type")
                return
            }
            
            XCTAssertEqual(body["schema"] as? String, "schemaValue4")
        }
    }
    
    func testUpdatePostItemWithSuccess() {
        let body: [String: NSCoding] = generatePostBody(index: 1)
        
        temporaryStorageManager.createAndSavePostItem(with: self.eventGateURI, body: body as NSDictionary)
        
        let results = temporaryStorageManager.fetchPostItemsToPost()
        let firstItem = results.first!
        
        XCTAssertNil(firstItem.posted)
        XCTAssertFalse(firstItem.failed)
        
        temporaryStorageManager.updatePostItem(postItem: firstItem, result: .success(Date()))
        
        let moc = temporaryStorageManager.managedObjectContextToTest
        
        moc.performAndWait {
            var results: [EPCPost] = []
            let fetch: NSFetchRequest<EPCPost> = EPCPost.fetchRequest()
            do {
                results = try moc.fetch(fetch)
            } catch let error {
                XCTFail("Failure fetching EPCPost results \(error)")
            }
            let firstItem = results.first!
            XCTAssertNotNil(firstItem.posted)
            XCTAssertFalse(firstItem.failed)
        }
    }
    
    func testUpdatePostItemWithFailure() {
        let body: [String: NSCoding] = generatePostBody(index: 1)
        
        temporaryStorageManager.createAndSavePostItem(with: self.eventGateURI, body: body as NSDictionary)
        
        let results = temporaryStorageManager.fetchPostItemsToPost()
        let firstItem = results.first!
        
        XCTAssertNil(firstItem.posted)
        XCTAssertFalse(firstItem.failed)
        
        let stockError = NSError(domain: "wikipedia.org", code: 1, userInfo: nil)
        temporaryStorageManager.updatePostItem(postItem: firstItem, result: .failure(stockError))
        
        let moc = temporaryStorageManager.managedObjectContextToTest
        
        moc.performAndWait {
            var results: [EPCPost] = []
            let fetch: NSFetchRequest<EPCPost> = EPCPost.fetchRequest()
            do {
                results = try moc.fetch(fetch)
            } catch let error {
                XCTFail("Failure fetching EPCPost results \(error)")
            }
            let firstItem = results.first!
            XCTAssertNil(firstItem.posted)
            XCTAssertTrue(firstItem.failed)
        }
    }
    
    func testDeleteStalePostItems() {
        
        //add 20 post items
        for i in 0..<20 {
            
            let body = generatePostBody(index: i)
            temporaryStorageManager.createAndSavePostItem(with: self.eventGateURI, body: body as NSDictionary)
        }
        
        //grab first batch and mark as successes or failures (batch size is 5 for test storage manager)
        let moc = temporaryStorageManager.managedObjectContextToTest
        
        moc.performAndWait {
            let results = temporaryStorageManager.fetchPostItemsToPost()
            for (i, post) in results.enumerated() {
                if i < 5 {
                    switch i % 3 {
                    case 0:
                        let stockError = NSError(domain: "wikipedia.org", code: 1, userInfo: nil)
                        temporaryStorageManager.updatePostItem(postItem: post, result: .failure(stockError))
                    case 1:
                        //artificially move recorded date 31 days in the past so it is purged
                        let pruneInterval = 60*60*24*31
                        post.recorded = Date(timeIntervalSinceNow: -Double(pruneInterval))
                        temporaryStorageManager.testSave(moc)
                    default:
                        temporaryStorageManager.updatePostItem(postItem: post, result: .success(Date()))
                    }
                }
            }
        }
        
        //now purge
        temporaryStorageManager.deleteStalePostItems()
        
        //confirm 15 post items remain
        moc.performAndWait {
            var results: [EPCPost] = []
            let fetch: NSFetchRequest<EPCPost> = EPCPost.fetchRequest()
            do {
                results = try moc.fetch(fetch)
            } catch let error {
                XCTFail("Failure fetching EPCPost results \(error)")
            }
            XCTAssertEqual(results.count, 15)
        }
    }
}