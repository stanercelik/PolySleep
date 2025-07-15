import Foundation
import Combine

#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - Notification Extensions
public extension Notification.Name {
    static let sleepDidStart = Notification.Name("sleepDidStart")
    static let sleepDidEnd = Notification.Name("sleepDidEnd")
    static let sleepQualityDidRate = Notification.Name("sleepQualityDidRate")
    static let scheduleDidUpdate = Notification.Name("scheduleDidUpdate")
    static let userPreferencesDidUpdate = Notification.Name("userPreferencesDidUpdate")
    static let sleepDataBatchReceived = Notification.Name("sleepDataBatchReceived")
    static let scheduleDataBatchReceived = Notification.Name("scheduleDataBatchReceived")
    static let watchContextDidUpdate = Notification.Name("watchContextDidUpdate")
    static let watchConnectivityStatusChanged = Notification.Name("watchConnectivityStatusChanged")
}

#if os(iOS) || os(watchOS)

// MARK: - Watch Message Types

public enum WatchMessageType: String, Codable {
    case sleepStarted = "sleepStarted"
    case sleepEnded = "sleepEnded"
    case qualityRated = "qualityRated"
    case scheduleUpdate = "scheduleUpdate"
    case scheduleActivated = "scheduleActivated"
    case adaptationUpdate = "adaptationUpdate"
    case sleepEntryAdded = "sleepEntryAdded"
    case userPreferencesUpdate = "userPreferencesUpdate"
    case syncRequest = "syncRequest"
    case syncResponse = "syncResponse"
    case fullDataSync = "fullDataSync"
}

// MARK: - Codable Dictionary Support
public struct CodableDictionary: Codable {
    public let value: [String: String]
    
    public init(_ dict: [String: Any]) {
        var stringDict: [String: String] = [:]
        for (key, value) in dict {
            // Validate key - must be non-empty string
            let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedKey.isEmpty else {
                print("⚠️ WatchMessage: Skipping empty key in dictionary")
                continue
            }
            
            // Convert value to string with type preservation
            let stringValue: String
            if let stringVal = value as? String {
                stringValue = stringVal
            } else if let numberValue = value as? NSNumber {
                // Preserve number type information
                if numberValue === kCFBooleanTrue || numberValue === kCFBooleanFalse {
                    stringValue = numberValue.boolValue ? "true" : "false"
                } else {
                    stringValue = numberValue.stringValue
                }
            } else if let boolValue = value as? Bool {
                stringValue = boolValue ? "true" : "false"
            } else if let dateValue = value as? Date {
                stringValue = String(dateValue.timeIntervalSince1970)
            } else if let uuidValue = value as? UUID {
                stringValue = uuidValue.uuidString
            } else {
                // Fallback for other types
                stringValue = String(describing: value)
            }
            
            stringDict[trimmedKey] = stringValue
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
    
    // Dictionary'e çevirmek için - NSSecureCoding uyumlu
    public var dictionary: [String: Any] {
        return [
            "type": type.rawValue,
            "data": data.value, // String dictionary olarak gönder
            "timestamp": timestamp.timeIntervalSince1970,
            "messageId": messageId.uuidString
        ]
    }
    
    // Dictionary'den oluşturmak için - improved with validation
    public static func from(dictionary: [String: Any]) -> WatchMessage? {
        // Validate required fields
        guard let typeString = dictionary["type"] as? String,
              !typeString.isEmpty,
              let type = WatchMessageType(rawValue: typeString) else {
            print("❌ WatchMessage: Invalid or missing message type")
            return nil
        }
        
        guard let timestampInterval = dictionary["timestamp"] as? TimeInterval,
              timestampInterval > 0 else {
            print("❌ WatchMessage: Invalid or missing timestamp")
            return nil
        }
        
        guard let messageIdString = dictionary["messageId"] as? String,
              !messageIdString.isEmpty,
              let messageId = UUID(uuidString: messageIdString) else {
            print("❌ WatchMessage: Invalid or missing messageId")
            return nil
        }
        
        // Validate timestamp range (reasonable bounds)
        let minTimestamp = Date(timeIntervalSince1970: 946684800).timeIntervalSince1970 // 2000-01-01
        let maxTimestamp = Date(timeIntervalSince1970: 4102444800).timeIntervalSince1970 // 2100-01-01
        guard timestampInterval >= minTimestamp && timestampInterval <= maxTimestamp else {
            print("❌ WatchMessage: Timestamp out of reasonable range: \(timestampInterval)")
            return nil
        }
        
        // Data kısmını farklı formatlarda handle et
        var dataDict: [String: Any] = [:]
        if let stringDict = dictionary["data"] as? [String: String] {
            // CodableDictionary format - String to Any convert et
            for (key, value) in stringDict {
                let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedKey.isEmpty else { continue }
                dataDict[trimmedKey] = convertStringToAppropriateType(value)
            }
        } else if let anyDict = dictionary["data"] as? [String: Any] {
            // Direct Any dictionary format - validate keys
            for (key, value) in anyDict {
                let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedKey.isEmpty else { continue }
                dataDict[trimmedKey] = value
            }
        }
        
        var message = WatchMessage(type: type, data: dataDict)
        message.timestamp = Date(timeIntervalSince1970: timestampInterval)
        message.messageId = messageId
        return message
    }
    
    // String'i uygun type'a convert eder - improved with validation
    private static func convertStringToAppropriateType(_ value: String) -> Any {
        // Trim whitespace
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty string check
        guard !trimmedValue.isEmpty else { return "" }
        
        // Bool check - more robust
        let lowercased = trimmedValue.lowercased()
        if lowercased == "true" || lowercased == "yes" || lowercased == "1" { return true }
        if lowercased == "false" || lowercased == "no" || lowercased == "0" { return false }
        
        // Number check with validation
        // First try Int to preserve precision for integer values
        if let intValue = Int(trimmedValue) {
            // Validate range for safety
            if intValue >= Int.min && intValue <= Int.max {
                return intValue
            }
        }
        
        // Then try Double for decimal values
        if let doubleValue = Double(trimmedValue) {
            // Validate for NaN and infinity
            if doubleValue.isFinite {
                return doubleValue
            }
        }
        
        // Date string check (ISO format or timestamp)
        if let timestampValue = Double(trimmedValue), timestampValue > 0 {
            // Reasonable timestamp range check (year 2000 to 2100)
            let minTimestamp = Date(timeIntervalSince1970: 946684800).timeIntervalSince1970 // 2000-01-01
            let maxTimestamp = Date(timeIntervalSince1970: 4102444800).timeIntervalSince1970 // 2100-01-01
            
            if timestampValue >= minTimestamp && timestampValue <= maxTimestamp {
                return timestampValue
            }
        }
        
        // Return as string if no other type matches
        return trimmedValue
    }
}

@MainActor
public class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = WatchConnectivityManager()
    
    // MARK: - Published Properties
    @Published public var isReachable = false
    @Published public var isSessionActive = false
    @Published public var lastSyncDate: Date?
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Private Properties
    private let session: WCSession
    private var cancellables = Set<AnyCancellable>()
    
    // Retry mechanism için
    private var retryAttempts: Int = 0
    private let maxRetryAttempts: Int = 3
    private var retryTimer: Timer?
    
    // İlk senkronizasyon takibi
    private var hasInitialSyncCompleted = false
    private var initialSyncTimeout: Timer?
    private let initialSyncTimeoutInterval: TimeInterval = 30.0 // 30 saniye timeout
    private var pendingInitialDataRequest = false
    
    // MARK: - Connection Status
    public enum ConnectionStatus {
        case connected
        case disconnected
        case pairing
        case paired
        case notSupported
        
        public var localizedDescription: String {
            switch self {
            case .connected:
                return "Bağlı"
            case .disconnected:
                return "Bağlantı Yok"
            case .pairing:
                return "Eşleştiriliyor"
            case .paired:
                return "Eşleştirildi"
            case .notSupported:
                return "Desteklenmiyor"
            }
        }
    }
    
    // MARK: - Initialization
    private override init() {
        self.session = WCSession.default
        super.init()
        setupSessionIfSupported()
    }
    
    // MARK: - Setup Methods
    private func setupSessionIfSupported() {
        guard WCSession.isSupported() else {
            connectionStatus = .notSupported
            print("🚫 WatchConnectivity desteklenmiyor")
            return
        }
        
        session.delegate = self
        session.activate()
        print("🌙 PolyNap WatchConnectivityManager başlatıldı")
        
        // Platform-specific setup
        #if os(iOS)
        setupiOSSpecific()
        #elseif os(watchOS)
        setupWatchOSSpecific()
        #endif
    }
    
    #if os(iOS)
    private func setupiOSSpecific() {
        print("📱 iOS WatchConnectivity setup")
        
        // iOS-specific features
        startConnectionMonitoring()
        
        // Background mode bildirim setup
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 iOS app background'a geçti")
            self?.syncCurrentContext()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 iOS app foreground'a geçti")
            self?.requestSync()
        }
        
        // Watch state değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 iOS app aktif oldu")
            // Health check yap
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let _ = self?.performHealthCheck()
            }
        }
    }
    #endif
    
    #if os(watchOS)
    private func setupWatchOSSpecific() {
        print("⌚ watchOS WatchConnectivity setup")
        
        // watchOS-specific features
        startConnectionMonitoring()
        
        // Initial sync için kısa bir delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestSync()
        }
        
        // Background app refresh scheduling - modern approach
        scheduleBackgroundRefresh()
    }
    
    private func scheduleBackgroundRefresh() {
        // Modern watchOS single target approach'te background refresh
        // Task.detached kullanarak background refresh scheduling
        Task.detached { @MainActor in
            let refreshDate = Date().addingTimeInterval(30 * 60) // 30 dakika sonra
            
            // Modern watchOS'ta background refresh scheduling
            // WKExtension.shared() yerine modern approach
            print("✅ Background refresh zamanlandı: \(refreshDate)")
            
            // Periyodik sync scheduling
            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { // 30 dakika
                self.requestSync()
                self.scheduleBackgroundRefresh() // Recursive scheduling
            }
        }
    }
    #endif
    
    // MARK: - Connection Monitoring
    private func updateConnectionStatus() {
        if session.isReachable {
            connectionStatus = .connected
            isReachable = true
        } else {
            // isPaired property watchOS'ta mevcut değil
            #if os(iOS)
            if session.isPaired {
                connectionStatus = .paired
                isReachable = false
            } else {
                connectionStatus = .disconnected
                isReachable = false
            }
            #elseif os(watchOS)
            // watchOS'ta isPaired yok, session activated olup olmadığına bakıyoruz
            if session.activationState == .activated {
                connectionStatus = .paired
                isReachable = false
            } else {
                connectionStatus = .disconnected
                isReachable = false
            }
            #endif
        }
        
        isSessionActive = session.activationState == .activated
        
        print("📶 WatchConnectivity durum güncellendi: \(connectionStatus.localizedDescription)")
        print("📶 Erişilebilir: \(isReachable)")
        print("📶 Session aktif: \(isSessionActive)")
        
        // Connection state değişikliklerini broadcast et
        broadcastConnectionStatusChange()
    }
    
    // MARK: - Reachability Monitoring
    
    /// Connection status değişikliklerini NotificationCenter ile broadcast eder
    private func broadcastConnectionStatusChange() {
        let userInfo: [String: Any] = [
            "isReachable": isReachable,
            "isSessionActive": isSessionActive,
            "connectionStatus": connectionStatus.localizedDescription,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        NotificationCenter.default.post(
            name: .watchConnectivityStatusChanged,
            object: self,
            userInfo: userInfo
        )
    }
    
    /// Real-time reachability durumunu döner
    public var currentReachabilityStatus: String {
        if !WCSession.isSupported() {
            return "Desteklenmiyor"
        }
        
        switch session.activationState {
        case .notActivated:
            return "Aktif Değil"
        case .inactive:
            return "Pasif"
        case .activated:
            if session.isReachable {
                return "Erişilebilir"
            } else {
                #if os(iOS)
                if session.isPaired {
                    return "Eşleştirildi (Erişilemez)"
                } else {
                    return "Eşleştirilmedi"
                }
                #elseif os(watchOS)
                // watchOS'ta isPaired mevcut değil - session activated ise paired kabul ediyoruz
                return "Eşleştirildi (Erişilemez)"
                #endif
            }
        @unknown default:
            return "Bilinmeyen"
        }
    }
    
    /// Detaylı connection bilgilerini döner
    public var connectionDetails: [String: Any] {
        var details: [String: Any] = [
            "isSupported": WCSession.isSupported(),
            "activationState": session.activationState.rawValue,
            "isReachable": session.isReachable,
            "isSessionActive": isSessionActive,
            "connectionStatus": connectionStatus.localizedDescription,
            "currentReachabilityStatus": currentReachabilityStatus,
            "lastSyncDate": lastSyncDate?.timeIntervalSince1970 ?? 0,
            "retryAttempts": retryAttempts,
            "maxRetryAttempts": maxRetryAttempts
        ]
        
        // isPaired sadece iOS'ta mevcut
        #if os(iOS)
        details["isPaired"] = session.isPaired
        #elseif os(watchOS)
        details["isPaired"] = session.activationState == .activated
        #endif
        
        return details
    }
    
    /// Connection status'u dinleyenler için Combine publisher
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }
    
    /// Reachability durumunu dinleyenler için Combine publisher
    public var reachabilityPublisher: AnyPublisher<Bool, Never> {
        $isReachable.eraseToAnyPublisher()
    }
    
    /// Son sync tarihini dinleyenler için Combine publisher
    public var lastSyncPublisher: AnyPublisher<Date?, Never> {
        $lastSyncDate.eraseToAnyPublisher()
    }
    
    /// Connection monitoring'i başlat
    public func startConnectionMonitoring() {
        // Timer ile periyodik health check
        let healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performPeriodicHealthCheck()
            }
        }
        
        // Timer'ı cancellables'a ekle
        let timerCancellable = Timer.TimerPublisher(interval: 30.0, runLoop: .main, mode: .default)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.performPeriodicHealthCheck()
                }
            }
        
        timerCancellable.store(in: &cancellables)
        print("🔄 Connection monitoring başlatıldı - 30 saniye interval")
    }
    
    /// Periyodik health check yapar
    private func performPeriodicHealthCheck() {
        let wasReachable = isReachable
        updateConnectionStatus()
        
        // Reachability değişti ise log et
        if wasReachable != isReachable {
            print("📶 Reachability değişti: \(wasReachable) -> \(isReachable)")
            
            // Reachable oldu ise sync isteği gönder
            if isReachable && !wasReachable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.requestSync()
                }
            }
        }
    }
    
    /// Connection monitoring'i durdur
    public func stopConnectionMonitoring() {
        cancellables.removeAll()
        retryTimer?.invalidate()
        retryTimer = nil
        print("🛑 Connection monitoring durduruldu")
    }
    
    // MARK: - Public Interface
    public func requestSync() {
        guard isReachable else {
            print("⚠️ Sync isteği gönderilemedi - bağlantı yok")
            return
        }
        
        let syncRequest = ["type": "syncRequest", "timestamp": Date().timeIntervalSince1970] as [String : Any]
        
        session.sendMessage(syncRequest, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.lastSyncDate = Date()
                print("✅ Sync isteği başarılı - yanıt alındı")
            }
        }) { [weak self] error in
            Task { @MainActor in
                print("❌ Sync isteği hatası: \(error.localizedDescription)")
                self?.handleCommunicationError(error)
            }
        }
    }
    
    // MARK: - Message Sending
    public func sendMessage(_ message: WatchMessage) {
        guard isReachable else {
            print("⚠️ Message gönderilemedi - bağlantı yok: \(message.type.rawValue)")
            return
        }
        
        session.sendMessage(message.dictionary, replyHandler: nil) { [weak self] error in
            Task { @MainActor in
                print("❌ Message gönderim hatası (\(message.type.rawValue)): \(error.localizedDescription)")
                self?.handleCommunicationError(error)
            }
        }
        
        print("📤 Message gönderildi: \(message.type.rawValue)")
    }
    
    /// Instant message sending with priority and immediate delivery
    public func sendInstantMessage(_ message: WatchMessage) {
        guard isReachable else {
            print("⚠️ Instant message gönderilemedi - bağlantı yok: \(message.type.rawValue)")
            // Fallback: Application context ile gönder
            updateApplicationContext(message.dictionary)
            return
        }
        
        // Instant message için reply handler ekle - daha hızlı delivery
        session.sendMessage(message.dictionary, replyHandler: { [weak self] reply in
            Task { @MainActor in
                print("⚡ Instant message başarıyla teslim edildi: \(message.type.rawValue)")
                self?.lastSyncDate = Date()
            }
        }) { [weak self] error in
            Task { @MainActor in
                print("❌ Instant message gönderim hatası (\(message.type.rawValue)): \(error.localizedDescription)")
                // Fallback: Application context ile tekrar dene
                self?.updateApplicationContext(message.dictionary)
                self?.handleCommunicationError(error)
            }
        }
        
        print("⚡ Instant message gönderildi: \(message.type.rawValue)")
    }
    
    // MARK: - Background Transfer Methods
    
    /// Application Context günceller - son durum bilgisi için
    /// Bu method background'da çalışır ve büyük veriler için uygundur
    public func updateApplicationContext(_ data: [String: Any]) {
        guard isSessionActive else {
            print("⚠️ Application context gönderilemedi - session aktif değil")
            return
        }
        
        do {
            try session.updateApplicationContext(data)
            print("📦 Application context güncellendi: \(data.keys.joined(separator: ", "))")
        } catch {
            print("❌ Application context güncelleme hatası: \(error.localizedDescription)")
            handleCommunicationError(error)
        }
    }
    
    /// Büyük veri setlerini background'da transfer eder
    /// Queue'ya eklenir ve sırayla gönderilir
    public func transferUserInfo(_ userInfo: [String: Any]) {
        guard isSessionActive else {
            print("⚠️ User info gönderilemedi - session aktif değil")
            return
        }
        
        let transfer = session.transferUserInfo(userInfo)
        print("📤 User info transfer başlatıldı: \(transfer.userInfo.keys.joined(separator: ", "))")
        
        // Transfer durumunu izle
        if transfer.isTransferring {
            print("🔄 Transfer devam ediyor...")
        }
    }
    
    /// Mevcut context'i sync eder - uygulama state'i için
    public func syncCurrentContext() {
        let currentContext: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "platform": {
                #if os(iOS)
                return "iOS"
                #elseif os(watchOS)
                return "watchOS"
                #else
                return "Unknown"
                #endif
            }(),
            "connectionStatus": connectionStatus.localizedDescription
        ]
        
        updateApplicationContext(currentContext)
    }
    
    /// Sleep data'yı background transfer ile gönder
    public func transferSleepData(_ sleepEntries: [[String: Any]]) {
        let transferData: [String: Any] = [
            "type": "sleepDataBatch",
            "entries": sleepEntries,
            "timestamp": Date().timeIntervalSince1970,
            "count": sleepEntries.count
        ]
        
        transferUserInfo(transferData)
    }
    
    /// Schedule data'yı background transfer ile gönder
    public func transferScheduleData(_ schedules: [[String: Any]]) {
        let transferData: [String: Any] = [
            "type": "scheduleDataBatch", 
            "schedules": schedules,
            "timestamp": Date().timeIntervalSince1970,
            "count": schedules.count
        ]
        
        transferUserInfo(transferData)
    }
    
    // MARK: - Error Handling & Retry Logic
    
    private func handleCommunicationError(_ error: Error) {
        print("❌ WatchConnectivity iletişim hatası: \(error.localizedDescription)")
        
        // WatchConnectivity spesifik hatalar için özel handling
        if let wcError = error as? WCError {
            handleWatchConnectivityError(wcError)
        } else {
            handleGenericError(error)
        }
        
        // Retry mechanism başlat
        scheduleRetryIfNeeded()
    }
    
    private func handleWatchConnectivityError(_ error: WCError) {
        switch error.code {
        case .sessionNotSupported:
            print("🚫 WatchConnectivity desteklenmiyor")
            connectionStatus = .notSupported
            
        case .sessionNotActivated:
            print("⚠️ Session aktif değil - yeniden aktive ediliyor")
            session.activate()
            
        case .deviceNotPaired:
            print("📱 Cihaz eşleştirilmemiş")
            connectionStatus = .disconnected
            
        case .watchAppNotInstalled:
            print("⌚ Watch app yüklenmemiş")
            connectionStatus = .paired
            
        case .notReachable:
            print("📶 Watch erişilebilir değil")
            connectionStatus = .paired
            
        case .invalidParameter:
            print("❌ Geçersiz parametre")
            
        case .payloadTooLarge:
            print("📦 Payload çok büyük - UserInfo transfer kullanılmalı")
            
        case .payloadUnsupportedTypes:
            print("❌ Desteklenmeyen veri tipi")
            
        case .messageReplyTimedOut:
            print("⏰ Message reply timeout")
            
        case .messageReplyFailed:
            print("❌ Message reply başarısız")
            
        case .fileAccessDenied:
            print("🔒 Dosya erişimi reddedildi")
            
        default:
            print("❌ Bilinmeyen WatchConnectivity hatası: \(error.localizedDescription)")
        }
    }
    
    private func handleGenericError(_ error: Error) {
        print("❌ Genel iletişim hatası: \(error.localizedDescription)")
    }
    
    private func scheduleRetryIfNeeded() {
        guard retryAttempts < maxRetryAttempts else {
            print("🚫 Maksimum retry sayısına ulaşıldı (\(maxRetryAttempts))")
            resetRetryCounter()
            return
        }
        
        retryAttempts += 1
        
        // Exponential backoff: 2^n seconds
        let retryDelay = pow(2.0, Double(retryAttempts))
        
        print("🔄 Retry #\(retryAttempts) \(retryDelay) saniye sonra...")
        
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptReconnection()
            }
        }
    }
    
    private func attemptReconnection() {
        print("🔄 Yeniden bağlantı deneniyor...")
        
        if WCSession.isSupported() {
            session.activate()
            
            // Sync request göndermeyi dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.isReachable {
                    self.requestSync()
                    self.resetRetryCounter()
                    print("✅ Yeniden bağlantı başarılı")
                } else {
                    print("⚠️ Yeniden bağlantı başarısız")
                }
            }
        } else {
            connectionStatus = .notSupported
            resetRetryCounter()
        }
    }
    
    private func resetRetryCounter() {
        retryAttempts = 0
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    // MARK: - Connection Recovery
    
    /// Manual olarak connection recovery tetikler
    public func forceReconnection() {
        print("🔄 Manual yeniden bağlantı başlatılıyor...")
        resetRetryCounter()
        attemptReconnection()
    }
    
    /// Session'ı tamamen reset eder
    public func resetSession() {
        print("🔄 WatchConnectivity session reset ediliyor...")
        resetRetryCounter()
        
        #if os(iOS)
        session.delegate = nil
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupSessionIfSupported()
        }
    }
    
    /// Connection health check yapar
    public func performHealthCheck() -> Bool {
        let isHealthy: Bool = {
            guard WCSession.isSupported() && session.activationState == .activated else {
                return false
            }
            
            if session.isReachable {
                return true
            }
            
            #if os(iOS)
            return session.isPaired
            #elseif os(watchOS)
            // watchOS'ta isPaired yok, activated session healthy kabul ediyoruz
            return true
            #endif
        }()
        
        print("🏥 Connection health: \(isHealthy ? "✅ Sağlıklı" : "❌ Sorunlu")")
        
        if !isHealthy {
            forceReconnection()
        }
        
        return isHealthy
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession aktivasyon hatası: \(error.localizedDescription)")
            connectionStatus = .disconnected
        } else {
            print("✅ WCSession başarıyla aktive edildi: \(activationState.rawValue)")
            updateConnectionStatus()
            
            // Session aktive olduktan sonra ilk senkronizasyon stratejisini başlat
            initiateInitialSyncStrategy()
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession pasif hale geldi")
        connectionStatus = .disconnected
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession deaktive edildi - yeniden aktive ediliyor")
        session.activate()
    }
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("📶 WatchConnectivity erişilebilirlik değişti: \(session.isReachable)")
        updateConnectionStatus()
    }
    
    // Message handling
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📩 Message alındı: \(message)")
        handleReceivedMessage(message)
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📩 Reply handler ile message alındı: \(message)")
        handleReceivedMessage(message)
        
        // Reply gönder
        let reply = ["status": "received", "timestamp": Date().timeIntervalSince1970] as [String : Any]
        replyHandler(reply)
    }
    
    // Context handling
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📦 Application context alındı: \(applicationContext)")
        handleReceivedContext(applicationContext)
    }
    
    // User info handling
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("📤 User info alındı: \(userInfo)")
        handleReceivedUserInfo(userInfo)
    }
    
    // MARK: - Message Processing
    private func handleReceivedMessage(_ message: [String: Any]) {
        // WatchMessage formatına çevir
        guard let watchMessage = WatchMessage.from(dictionary: message) else {
            print("❌ Geçersiz message formatı: \(message)")
            return
        }
        
        print("📩 Message işleniyor: \(watchMessage.type.rawValue)")
        
        // Message type'a göre routing
        switch watchMessage.type {
        case .sleepStarted:
            handleSleepStarted(data: watchMessage.data.toDictionary())
        case .sleepEnded:
            handleSleepEnded(data: watchMessage.data.toDictionary())
        case .qualityRated:
            handleQualityRated(data: watchMessage.data.toDictionary())
        case .scheduleUpdate:
            handleScheduleUpdate(data: watchMessage.data.toDictionary())
        case .scheduleActivated:
            handleScheduleActivated(data: watchMessage.data.toDictionary())
        case .adaptationUpdate:
            handleAdaptationUpdate(data: watchMessage.data.toDictionary())
        case .sleepEntryAdded:
            handleSleepEntryAdded(data: watchMessage.data.toDictionary())
        case .userPreferencesUpdate:
            handleUserPreferencesUpdate(data: watchMessage.data.toDictionary())
        case .syncRequest:
            handleSyncRequest(data: watchMessage.data.toDictionary())
        case .syncResponse:
            handleSyncResponse(data: watchMessage.data.toDictionary())
        case .fullDataSync:
            handleFullDataSync(data: watchMessage.data.toDictionary())
        }
        
        // Son sync tarihini güncelle
        lastSyncDate = Date()
    }
    
    private func handleReceivedContext(_ context: [String: Any]) {
        print("📦 Application context işleniyor: \(context.keys.joined(separator: ", "))")
        
        // Platform bilgisi kontrol et
        if let platform = context["platform"] as? String {
            print("📱 Platform: \(platform)")
        }
        
        // Timestamp kontrol et
        if let timestamp = context["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            print("⏰ Context zamanı: \(date)")
        }
        
        // Connection status kontrol et
        if let connStatus = context["connectionStatus"] as? String {
            print("📶 Remote connection status: \(connStatus)")
        }
        
        // Context type'ına göre işle
        if let contextType = context["type"] as? String {
            handleContextByType(contextType, context: context)
        } else {
            print("⚠️ Application context'te type bulunamadı")
        }
        
        // Context güncellemelerini işle
        processContextUpdate(context)
        lastSyncDate = Date()
    }
    
    /// Context type'ına göre işleme yapar
    private func handleContextByType(_ type: String, context: [String: Any]) {
        switch type {
        case "scheduleSync":
            handleScheduleContext(context)
        case "userPreferencesSync":
            handleUserPreferencesContext(context)
        case "sleepDataSync":
            handleSleepDataContext(context)
        case "fullSync":
            handleFullSyncContext(context)
        case "appState":
            handleAppStateContext(context)
        default:
            print("❓ Bilinmeyen context type: \(type)")
        }
    }
    
    /// Schedule context'ini işler
    private func handleScheduleContext(_ context: [String: Any]) {
        print("📅 Application context ile schedule sync alındı")
        
        if let scheduleData = context["schedule"] as? [String: Any] {
            // Schedule güncelleme notification'ı gönder
            NotificationCenter.default.post(
                name: .scheduleDidUpdate,
                object: nil,
                userInfo: scheduleData
            )
            print("📅 Schedule context data notification gönderildi")
        } else {
            print("❌ Schedule context'te schedule data bulunamadı")
        }
    }
    
    /// User preferences context'ini işler
    private func handleUserPreferencesContext(_ context: [String: Any]) {
        print("⚙️ Application context ile user preferences sync alındı")
        
        if let preferencesData = context["preferences"] as? [String: Any] {
            // User preferences güncelleme notification'ı gönder
            NotificationCenter.default.post(
                name: .userPreferencesDidUpdate,
                object: nil,
                userInfo: preferencesData
            )
            print("⚙️ User preferences context data notification gönderildi")
        } else {
            print("❌ User preferences context'te preferences data bulunamadı")
        }
    }
    
    /// Sleep data context'ini işler
    private func handleSleepDataContext(_ context: [String: Any]) {
        print("💤 Application context ile sleep data sync alındı")
        
        if let sleepEntries = context["entries"] as? [[String: Any]] {
            // Sleep data batch notification'ı gönder
            NotificationCenter.default.post(
                name: .sleepDataBatchReceived,
                object: nil,
                userInfo: ["entries": sleepEntries]
            )
            print("💤 Sleep data context notification gönderildi: \(sleepEntries.count) entries")
        } else {
            print("❌ Sleep data context'te entries bulunamadı")
        }
    }
    
    /// Full sync context'ini işler
    private func handleFullSyncContext(_ context: [String: Any]) {
        print("🔄 Application context ile full sync alındı")
        
        // Full sync request notification'ı gönder
        NotificationCenter.default.post(
            name: Notification.Name("fullDataSyncRequested"),
            object: nil,
            userInfo: context
        )
        print("🔄 Full sync context notification gönderildi")
    }
    
    /// App state context'ini işler
    private func handleAppStateContext(_ context: [String: Any]) {
        print("📱 Application context ile app state sync alındı")
        
        // App state bilgilerini process et
        if let appVersion = context["appVersion"] as? String {
            print("📱 Remote app version: \(appVersion)")
        }
        
        if let isPremium = context["isPremium"] as? Bool {
            print("💎 Remote premium status: \(isPremium)")
        }
        
        // Detailed app state processing için notification gönder
        NotificationCenter.default.post(
            name: Notification.Name("appStateDidUpdate"),
            object: nil,
            userInfo: context
        )
    }
    
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        print("📤 User info işleniyor: \(userInfo.keys.joined(separator: ", "))")
        
        // Data type'ına göre işle
        if let dataType = userInfo["type"] as? String {
            switch dataType {
            case "sleepDataBatch":
                handleSleepDataBatch(userInfo)
            case "scheduleDataBatch":
                handleScheduleDataBatch(userInfo)
            default:
                print("❓ Bilinmeyen user info type: \(dataType)")
            }
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Specific Message Handlers
    
    private func handleSleepStarted(data: [String: Any]) {
        print("😴 Uyku başladı: \(data)")
        
        // Repository'ye sleep entry kaydet
        // Bu method Repository layer'dan çağrılacak
        NotificationCenter.default.post(
            name: .sleepDidStart,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleSleepEnded(data: [String: Any]) {
        print("😊 Uyku bitti: \(data)")
        
        // Sleep entry'yi güncelle
        NotificationCenter.default.post(
            name: .sleepDidEnd,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleQualityRated(data: [String: Any]) {
        print("⭐ Uyku kalitesi puanlandı: \(data)")
        
        // Quality rating'i kaydet
        NotificationCenter.default.post(
            name: .sleepQualityDidRate,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleScheduleUpdate(data: [String: Any]) {
        print("📅 Schedule güncellendi: \(data)")
        
        // Schedule değişikliklerini işle
        NotificationCenter.default.post(
            name: .scheduleDidUpdate,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleScheduleActivated(data: [String: Any]) {
        print("🎯 Schedule aktive edildi: \(data)")
        
        // Schedule aktivasyonunu işle
        NotificationCenter.default.post(
            name: .scheduleDidUpdate,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleAdaptationUpdate(data: [String: Any]) {
        print("📈 Adaptation güncellendi: \(data)")
        
        // Adaptation güncellemelerini işle
        NotificationCenter.default.post(
            name: Notification.Name("adaptationDidUpdate"),
            object: nil,
            userInfo: data
        )
    }
    
    private func handleSleepEntryAdded(data: [String: Any]) {
        print("💤 Sleep entry eklendi: \(data)")
        
        // Sleep entry eklenmelerini işle
        NotificationCenter.default.post(
            name: Notification.Name("sleepEntryDidAdd"),
            object: nil,
            userInfo: data
        )
    }
    
    private func handleFullDataSync(data: [String: Any]) {
        print("🔄 Full data sync isteği: \(data)")
        
        // Tam data sync'i işle
        NotificationCenter.default.post(
            name: Notification.Name("fullDataSyncRequested"),
            object: nil,
            userInfo: data
        )
    }
    
    private func handleUserPreferencesUpdate(data: [String: Any]) {
        print("⚙️ User preferences güncellendi: \(data)")
        
        // Preferences güncellemelerini işle
        NotificationCenter.default.post(
            name: .userPreferencesDidUpdate,
            object: nil,
            userInfo: data
        )
    }
    
    private func handleSyncRequest(data: [String: Any]) {
        print("🔄 Sync isteği alındı")
        
        #if os(iOS)
        // iOS'ta sync request geldiğinde otomatik olarak active schedule'ı gönder
        print("📱 iOS: Watch'tan sync isteği alındı - active schedule gönderiliyor")
        Task { @MainActor in
            await triggerAutoScheduleSync()
        }
        #endif
        
        // Mevcut veriyi sync response olarak gönder
        let responseData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "status": "success",
            "platform": {
                #if os(iOS)
                return "iOS"
                #elseif os(watchOS)
                return "watchOS"
                #else
                return "Unknown"
                #endif
            }()
        ]
        
        let syncResponse = WatchMessage(type: .syncResponse, data: responseData)
        sendMessage(syncResponse)
    }
    
    #if os(iOS)
    /// iOS'ta Watch'tan sync request geldiğinde otomatik schedule sync tetikler
    private func triggerAutoScheduleSync() async {
        print("🔄 iOS: Otomatik schedule sync tetikleniyor...")
        
        // WatchSyncBridge üzerinden full sync başlat
        NotificationCenter.default.post(
            name: Notification.Name("watchAppLaunchDetected"),
            object: nil,
            userInfo: ["timestamp": Date().timeIntervalSince1970]
        )
    }
    #endif
    
    private func handleSyncResponse(data: [String: Any]) {
        print("✅ Sync response alındı: \(data)")
        
        if let status = data["status"] as? String, status == "success" {
            print("✅ Sync başarılı")
            resetRetryCounter() // Başarılı sync sonrası retry counter'ı sıfırla
        } else {
            print("⚠️ Sync başarısız")
        }
    }
    
    // MARK: - Batch Data Handlers
    
    private func handleSleepDataBatch(_ userInfo: [String: Any]) {
        guard let entries = userInfo["entries"] as? [[String: Any]] else {
            print("❌ Sleep data batch format hatası")
            return
        }
        
        print("📦 Sleep data batch işleniyor: \(entries.count) entry")
        
        // Repository layer'a batch import için notification gönder
        NotificationCenter.default.post(
            name: .sleepDataBatchReceived,
            object: nil,
            userInfo: ["entries": entries]
        )
    }
    
    private func handleScheduleDataBatch(_ userInfo: [String: Any]) {
        guard let schedules = userInfo["schedules"] as? [[String: Any]] else {
            print("❌ Schedule data batch format hatası")
            return
        }
        
        print("📦 Schedule data batch işleniyor: \(schedules.count) schedule")
        
        // Repository layer'a batch import için notification gönder
        NotificationCenter.default.post(
            name: .scheduleDataBatchReceived,
            object: nil,
            userInfo: ["schedules": schedules]
        )
    }
    
    private func processContextUpdate(_ context: [String: Any]) {
        // Context güncellemelerini işle
        // Bu method app state güncellemeleri için kullanılır
        
        // NotificationCenter ile app-wide update broadcast
        NotificationCenter.default.post(
            name: .watchContextDidUpdate,
            object: nil,
            userInfo: context
        )
    }
    
    // MARK: - High-level Convenience Methods
    
    /// Sleep entry'yi karşı platforma bildir
    public func notifySleepStarted(_ sleepEntry: [String: Any]) {
        let message = WatchMessage(type: .sleepStarted, data: sleepEntry)
        sendMessage(message)
    }
    
    /// Sleep end'i karşı platforma bildir
    public func notifySleepEnded(_ sleepEntry: [String: Any]) {
        let message = WatchMessage(type: .sleepEnded, data: sleepEntry)
        sendMessage(message)
    }
    
    /// Quality rating'i karşı platforma bildir
    public func notifyQualityRated(_ rating: [String: Any]) {
        let message = WatchMessage(type: .qualityRated, data: rating)
        sendMessage(message)
    }
    
    /// Schedule güncellemesini karşı platforma bildir
    public func notifyScheduleUpdate(_ schedule: [String: Any]) {
        let message = WatchMessage(type: .scheduleUpdate, data: schedule)
        sendInstantMessage(message)
    }
    
    /// Schedule aktivasyonunu karşı platforma bildir
    public func notifyScheduleActivated(_ schedule: [String: Any]) {
        let message = WatchMessage(type: .scheduleActivated, data: schedule)
        sendInstantMessage(message)
    }
    
    /// Adaptation progress güncellemesini karşı platforma bildir
    public func notifyAdaptationUpdate(_ adaptation: [String: Any]) {
        let message = WatchMessage(type: .adaptationUpdate, data: adaptation)
        sendMessage(message)
    }
    
    /// Sleep entry eklenmesini karşı platforma bildir
    public func notifySleepEntryAdded(_ entry: [String: Any]) {
        let message = WatchMessage(type: .sleepEntryAdded, data: entry)
        sendMessage(message)
    }
    
    /// Tam data sync isteğini karşı platforma bildir
    public func requestFullDataSync() {
        let syncData = [
            "timestamp": Date().timeIntervalSince1970,
            "platform": {
                #if os(iOS)
                return "iOS"
                #elseif os(watchOS)
                return "watchOS"
                #else
                return "Unknown"
                #endif
            }()
        ] as [String: Any]
        
        let message = WatchMessage(type: .fullDataSync, data: syncData)
        sendMessage(message)
    }
    
    /// User preferences güncellemesini karşı platforma bildir
    public func notifyUserPreferencesUpdate(_ preferences: [String: Any]) {
        let message = WatchMessage(type: .userPreferencesUpdate, data: preferences)
        sendMessage(message)
    }
    
    // MARK: - İlk Senkronizasyon Stratejisi
    
    /// İlk senkronizasyon stratejisini başlatır
    private func initiateInitialSyncStrategy() {
        guard !hasInitialSyncCompleted else {
            print("✅ İlk senkronizasyon zaten tamamlandı")
            return
        }
        
        print("🔄 İlk senkronizasyon stratejisi başlatılıyor...")
        
        // Timeout timer'ını başlat
        startInitialSyncTimeout()
        
        #if os(iOS)
        initiateInitialSyncForiOS()
        #elseif os(watchOS)
        initiateInitialSyncForWatchOS()
        #endif
    }
    
    #if os(iOS)
    /// iOS için ilk senkronizasyon stratejisi
    private func initiateInitialSyncForiOS() {
        print("📱 iOS: İlk senkronizasyon stratejisi başlatılıyor...")
        
        // 1. Mevcut active schedule'ı application context olarak gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendInitialScheduleContext()
        }
        
        // 2. Watch'tan gelen receivedApplicationContext'i kontrol et
        if !session.receivedApplicationContext.isEmpty {
            print("📦 iOS: Mevcut receivedApplicationContext bulundu")
            handleReceivedContext(session.receivedApplicationContext)
        }
        
        // 3. Kısa süre sonra ilk senkronizasyonu tamamlandı olarak işaretle
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.completeInitialSync()
        }
    }
    
    /// Active schedule'ı application context olarak gönder
    private func sendInitialScheduleContext() {
        // iOS app'ten active schedule bilgilerini al ve gönder
        let initialContext: [String: Any] = [
            "type": "scheduleSync",
            "timestamp": Date().timeIntervalSince1970,
            "platform": "iOS",
            "initialSync": true
        ]
        
        // Repository'den active schedule bilgilerini al
        NotificationCenter.default.post(
            name: Notification.Name("requestActiveScheduleForWatchSync"),
            object: nil,
            userInfo: initialContext
        )
        
        print("📱 iOS: Active schedule context gönderim isteği yapıldı")
    }
    #endif
    
    #if os(watchOS)
    /// watchOS için ilk senkronizasyon stratejisi
    private func initiateInitialSyncForWatchOS() {
        print("⌚ watchOS: İlk senkronizasyon stratejisi başlatılıyor...")
        
        // 1. Önce mevcut receivedApplicationContext'i kontrol et
        if !session.receivedApplicationContext.isEmpty {
            print("📦 watchOS: Mevcut receivedApplicationContext bulundu")
            handleReceivedContext(session.receivedApplicationContext)
            completeInitialSync()
        } else {
            print("📦 watchOS: ApplicationContext boş - iOS'tan veri isteği gönderiliyor")
            // 2. iOS'tan veri isteği gönder
            requestInitialDataFromiOS()
        }
    }
    
    /// iOS'tan ilk veri isteği gönder
    private func requestInitialDataFromiOS() {
        guard !pendingInitialDataRequest else {
            print("⚠️ watchOS: Zaten bekleyen veri isteği var")
            return
        }
        
        pendingInitialDataRequest = true
        
        if isReachable {
            // Reachable ise direct message gönder
            let syncRequest = WatchMessage(type: .fullDataSync, data: [
                "requestType": "initialData",
                "timestamp": Date().timeIntervalSince1970,
                "platform": "watchOS"
            ])
            sendMessage(syncRequest)
            print("📤 watchOS: iOS'a ilk veri isteği gönderildi (message)")
        } else {
            // Reachable değilse application context güncelle
            updateApplicationContext([
                "type": "fullSync",
                "requestType": "initialData",
                "timestamp": Date().timeIntervalSince1970,
                "platform": "watchOS"
            ])
            print("📤 watchOS: iOS'a ilk veri isteği gönderildi (context)")
        }
    }
    #endif
    
    /// İlk senkronizasyon timeout'unu başlat
    private func startInitialSyncTimeout() {
        initialSyncTimeout?.invalidate()
        initialSyncTimeout = Timer.scheduledTimer(withTimeInterval: initialSyncTimeoutInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleInitialSyncTimeout()
            }
        }
        print("⏰ İlk senkronizasyon timeout başlatıldı: \(initialSyncTimeoutInterval) saniye")
    }
    
    /// İlk senkronizasyon timeout'unu handle et
    private func handleInitialSyncTimeout() {
        guard !hasInitialSyncCompleted else { return }
        
        print("⏰ watchOS: İlk senkronizasyon timeout - fallback mekanizması başlatılıyor")
        
        #if os(watchOS)
        // watchOS'ta timeout olursa fallback mekanizması
        print("⚠️ watchOS: Timeout - SharedRepository fallback ile başlatılacak")
        
        // SharedRepository'e fallback mekanizmasını tetikle
        NotificationCenter.default.post(
            name: Notification.Name("initiateWatchAppFallback"),
            object: nil,
            userInfo: [
                "reason": "initialSyncTimeout",
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        #endif
        
        completeInitialSync()
    }
    
    /// İlk senkronizasyonu tamamlandı olarak işaretle
    private func completeInitialSync() {
        guard !hasInitialSyncCompleted else { return }
        
        hasInitialSyncCompleted = true
        pendingInitialDataRequest = false
        
        // Timeout timer'ını temizle
        initialSyncTimeout?.invalidate()
        initialSyncTimeout = nil
        
        print("✅ İlk senkronizasyon tamamlandı")
        
        // İlk senkronizasyon tamamlandı notification'ı gönder
        NotificationCenter.default.post(
            name: Notification.Name("initialWatchSyncCompleted"),
            object: nil,
            userInfo: [
                "timestamp": Date().timeIntervalSince1970,
                "platform": {
                    #if os(iOS)
                    return "iOS"
                    #elseif os(watchOS)
                    return "watchOS"
                    #else
                    return "Unknown"
                    #endif
                }()
            ]
        )
    }
    
    /// İlk senkronizasyon durumunu sıfırla (test için)
    public func resetInitialSyncState() {
        hasInitialSyncCompleted = false
        pendingInitialDataRequest = false
        initialSyncTimeout?.invalidate()
        initialSyncTimeout = nil
        print("🔄 İlk senkronizasyon durumu sıfırlandı")
    }
    
    /// İlk senkronizasyon tamamlandı mı?
    public var isInitialSyncCompleted: Bool {
        return hasInitialSyncCompleted
    }
} 

#endif 
