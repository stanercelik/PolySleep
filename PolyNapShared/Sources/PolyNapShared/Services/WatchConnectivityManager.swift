import Foundation
import WatchConnectivity

// MARK: - Watch Message Types

public enum WatchMessageType: String, Codable {
    case sleepStarted = "sleepStarted"
    case sleepEnded = "sleepEnded"
    case qualityRated = "qualityRated"
    case scheduleUpdate = "scheduleUpdate"
    case userPreferencesUpdate = "userPreferencesUpdate"
    case syncRequest = "syncRequest"
    case syncResponse = "syncResponse"
}

// MARK: - Codable Dictionary Support
public struct CodableDictionary: Codable {
    public let value: [String: String]
    
    public init(_ dict: [String: Any]) {
        var stringDict: [String: String] = [:]
        for (key, value) in dict {
            if let stringValue = value as? String {
                stringDict[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                stringDict[key] = numberValue.stringValue
            } else if let boolValue = value as? Bool {
                stringDict[key] = boolValue ? "true" : "false"
            } else {
                stringDict[key] = String(describing: value)
            }
        }
        self.value = stringDict
    }
    
    public func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self.value {
            // Sayı mı kontrol et
            if let doubleValue = Double(value) {
                if value.contains(".") {
                    result[key] = doubleValue
                } else {
                    result[key] = Int(doubleValue)
                }
            }
            // Bool mu kontrol et
            else if value == "true" {
                result[key] = true
            } else if value == "false" {
                result[key] = false
            }
            // String olarak bırak
            else {
                result[key] = value
            }
        }
        return result
    }
}

public struct WatchMessage: Codable {
    public let type: WatchMessageType
    public let data: CodableDictionary
    public var timestamp: Date
    public var messageId: UUID
    
    public init(type: WatchMessageType, data: [String: Any]) {
        self.type = type
        self.data = CodableDictionary(data)
        self.timestamp = Date()
        self.messageId = UUID()
    }
    
    // Dictionary'e çevirmek için
    public var dictionary: [String: Any] {
        return [
            "type": type.rawValue,
            "data": data.toDictionary(),
            "timestamp": timestamp.timeIntervalSince1970,
            "messageId": messageId.uuidString
        ]
    }
    
    // Dictionary'den oluşturmak için
    public static func from(dictionary: [String: Any]) -> WatchMessage? {
        guard 
            let typeString = dictionary["type"] as? String,
            let type = WatchMessageType(rawValue: typeString),
            let dataDict = dictionary["data"] as? [String: Any],
            let timestampInterval = dictionary["timestamp"] as? TimeInterval,
            let messageIdString = dictionary["messageId"] as? String,
            let messageId = UUID(uuidString: messageIdString)
        else {
            return nil
        }
        
        var message = WatchMessage(type: type, data: dataDict)
        message.timestamp = Date(timeIntervalSince1970: timestampInterval)
        message.messageId = messageId
        return message
    }
}

// MARK: - WatchConnectivity Manager

@MainActor
public class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()
    
    @Published public var isReachable = false
    @Published public var isSessionActive = false
    @Published public var lastSyncDate: Date?
    
    private let session: WCSession
    
    public override init() {
        session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Public Methods
    
    public func sendMessage(_ message: WatchMessage) {
        guard session.isReachable else {
            print("❌ WatchConnectivity: Session not reachable")
            return
        }
        
        session.sendMessage(message.dictionary, replyHandler: nil) { error in
            print("❌ WatchConnectivity Error: \(error.localizedDescription)")
        }
    }
    
    public func updateApplicationContext(_ data: [String: Any]) {
        do {
            try session.updateApplicationContext(data)
            print("✅ WatchConnectivity: Context updated")
        } catch {
            print("❌ WatchConnectivity Context Error: \(error.localizedDescription)")
        }
    }
    
    public func transferUserInfo(_ userInfo: [String: Any]) {
        session.transferUserInfo(userInfo)
        print("📤 WatchConnectivity: UserInfo transferred")
    }
    
    // MARK: - Specific Message Helpers
    
    public func notifySleepStarted(sleepEntry: SharedSleepEntry) {
        let data: [String: Any] = [
            "id": sleepEntry.id.uuidString,
            "startTime": sleepEntry.startTime.timeIntervalSince1970,
            "isCore": sleepEntry.isCore,
            "blockId": sleepEntry.blockId ?? ""
        ]
        
        let message = WatchMessage(type: .sleepStarted, data: data)
        sendMessage(message)
    }
    
    public func notifySleepEnded(sleepEntry: SharedSleepEntry) {
        let data: [String: Any] = [
            "id": sleepEntry.id.uuidString,
            "endTime": sleepEntry.endTime.timeIntervalSince1970,
            "durationMinutes": sleepEntry.durationMinutes,
            "rating": sleepEntry.rating
        ]
        
        let message = WatchMessage(type: .sleepEnded, data: data)
        sendMessage(message)
    }
    
    public func notifyScheduleUpdate(schedule: SharedUserSchedule) {
        let data: [String: Any] = [
            "id": schedule.id.uuidString,
            "name": schedule.name,
            "description": schedule.scheduleDescription ?? "",
            "totalSleepHours": schedule.totalSleepHours ?? 0.0,
            "isActive": schedule.isActive
        ]
        
        let message = WatchMessage(type: .scheduleUpdate, data: data)
        sendMessage(message)
    }
    
    public func requestSync() {
        let message = WatchMessage(type: .syncRequest, data: [:])
        sendMessage(message)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isSessionActive = activationState == .activated
            self.isReachable = session.isReachable
        }
        
        if let error = error {
            print("❌ WatchConnectivity Activation Error: \(error.localizedDescription)")
        } else {
            print("✅ WatchConnectivity: Session activated with state: \(activationState.rawValue)")
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        print("📶 WatchConnectivity: Reachability changed to \(session.isReachable)")
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let watchMessage = WatchMessage.from(dictionary: message) else {
            print("❌ WatchConnectivity: Invalid message format")
            return
        }
        
        DispatchQueue.main.async {
            self.handleReceivedMessage(watchMessage)
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleApplicationContext(applicationContext)
            self.lastSyncDate = Date()
        }
        print("📥 WatchConnectivity: Application context received")
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.handleUserInfo(userInfo)
            self.lastSyncDate = Date()
        }
        print("📥 WatchConnectivity: User info received")
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WatchConnectivity: Session became inactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WatchConnectivity: Session deactivated")
        session.activate()
    }
    #endif
    
    // MARK: - Message Handling
    
    private func handleReceivedMessage(_ message: WatchMessage) {
        switch message.type {
        case .sleepStarted:
            handleSleepStarted(data: message.data.toDictionary())
        case .sleepEnded:
            handleSleepEnded(data: message.data.toDictionary())
        case .qualityRated:
            handleQualityRated(data: message.data.toDictionary())
        case .syncRequest:
            handleSyncRequest()
        case .syncResponse:
            handleSyncResponse(data: message.data.toDictionary())
        default:
            print("🤷‍♂️ WatchConnectivity: Unhandled message type: \(message.type)")
        }
    }
    
    private func handleSleepStarted(data: [String: Any]) {
        // Implement sleep started handling
        print("😴 Sleep started: \(data)")
    }
    
    private func handleSleepEnded(data: [String: Any]) {
        // Implement sleep ended handling  
        print("😊 Sleep ended: \(data)")
    }
    
    private func handleQualityRated(data: [String: Any]) {
        // Implement quality rating handling
        print("⭐ Quality rated: \(data)")
    }
    
    private func handleSyncRequest() {
        // Implement sync request handling
        print("🔄 Sync requested")
    }
    
    private func handleSyncResponse(data: [String: Any]) {
        // Implement sync response handling
        print("✅ Sync response: \(data)")
    }
    
    private func handleApplicationContext(_ context: [String: Any]) {
        // Implement application context handling
        print("📱 Application context: \(context)")
    }
    
    private func handleUserInfo(_ userInfo: [String: Any]) {
        // Implement user info handling
        print("👤 User info: \(userInfo)")
    }
} 