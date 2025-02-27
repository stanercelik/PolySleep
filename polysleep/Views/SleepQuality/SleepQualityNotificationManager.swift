import SwiftUI
import UserNotifications

class SleepQualityNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SleepQualityNotificationManager()
    
    @Published var pendingRatings: [(startTime: Date, endTime: Date)] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let ratingActions = ["😩", "😪", "😐", "😊", "😄"]
    private let ratingCategories = "SLEEP_RATING_CATEGORY"
    
    private override init() {
        super.init()
        setupNotificationCategories()
        notificationCenter.delegate = self
    }
    
    private func setupNotificationCategories() {
        var actions: [UNNotificationAction] = []
        
        // Her emoji için bir aksiyon oluştur
        for (index, emoji) in ratingActions.enumerated() {
            let action = UNNotificationAction(
                identifier: "RATE_\(index)",
                title: emoji,
                options: .foreground
            )
            actions.append(action)
        }
        
        // Kategoriyi oluştur ve kaydet
        let category = UNNotificationCategory(
            identifier: ratingCategories,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func addPendingRating(startTime: Date, endTime: Date) {
        pendingRatings.append((startTime: startTime, endTime: endTime))
        showNotification(startTime: startTime, endTime: endTime)
    }
    
    func removePendingRating(startTime: Date, endTime: Date) {
        pendingRatings.removeAll { rating in
            Calendar.current.isDate(rating.startTime, inSameDayAs: startTime) &&
            Calendar.current.isDate(rating.endTime, inSameDayAs: endTime)
        }
    }
    
    private func showNotification(startTime: Date, endTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("sleepQuality.notification.title", comment: "")
        content.body = NSLocalizedString("sleepQuality.question", comment: "")
        content.sound = .default
        content.categoryIdentifier = ratingCategories
        
        // Bildirim için özel veri ekle
        content.userInfo = [
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    // Bildirim aksiyonlarını işle
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let startTimeInterval = userInfo["startTime"] as? TimeInterval,
              let endTimeInterval = userInfo["endTime"] as? TimeInterval else {
            completionHandler()
            return
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        
        if response.actionIdentifier.starts(with: "RATE_"),
           let ratingString = response.actionIdentifier.split(separator: "_").last,
           let rating = Int(ratingString) {
            saveSleepQuality(rating: rating, startTime: startTime, endTime: endTime)
        }
        
        completionHandler()
    }
    
    private func saveSleepQuality(rating: Int, startTime: Date, endTime: Date) {
        // TODO: Implement actual save functionality
        print("Sleep quality saved from notification: \(rating)")
        removePendingRating(startTime: startTime, endTime: endTime)
    }
}
