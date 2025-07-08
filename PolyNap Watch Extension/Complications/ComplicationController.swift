import ClockKit
import SwiftUI
import PolyNapShared

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        handler(endDate)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        guard let template = createTemplate(for: complication.family) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        
        var entries: [CLKComplicationTimelineEntry] = []
        let calendar = Calendar.current
        
        // Önümüzdeki 24 saat için uyku blokları oluştur
        for hour in 0..<24 {
            guard entries.count < limit else { break }
            
            if let entryDate = calendar.date(byAdding: .hour, value: hour, to: date),
               let template = createTemplate(for: complication.family, for: entryDate) {
                let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                entries.append(entry)
            }
        }
        
        handler(entries.isEmpty ? nil : entries)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createSampleTemplate(for: complication.family)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for family: CLKComplicationFamily, for date: Date = Date()) -> CLKComplicationTemplate? {
        let sleepInfo = getCurrentSleepInfo(for: date)
        
        switch family {
        case .modularSmall:
            return createModularSmallTemplate(sleepInfo: sleepInfo)
            
        case .modularLarge:
            return createModularLargeTemplate(sleepInfo: sleepInfo)
            
        case .circularSmall:
            return createCircularSmallTemplate(sleepInfo: sleepInfo)
            
        case .graphicCorner:
            return createGraphicCornerTemplate(sleepInfo: sleepInfo)
            
        case .graphicCircular:
            return createGraphicCircularTemplate(sleepInfo: sleepInfo)
            
        @unknown default:
            return nil
        }
    }
    
    private func createSampleTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
        let sampleInfo = SleepInfo(
            nextSleepTime: "14:30",
            nextSleepType: "Şekerleme",
            timeUntilSleep: "2s 15d",
            isCurrentlySleeping: false
        )
        
        switch family {
        case .modularSmall:
            return createModularSmallTemplate(sleepInfo: sampleInfo)
            
        case .modularLarge:
            return createModularLargeTemplate(sleepInfo: sampleInfo)
            
        case .circularSmall:
            return createCircularSmallTemplate(sleepInfo: sampleInfo)
            
        case .graphicCorner:
            return createGraphicCornerTemplate(sleepInfo: sampleInfo)
            
        case .graphicCircular:
            return createGraphicCircularTemplate(sleepInfo: sampleInfo)
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Specific Template Creators
    
    private func createModularSmallTemplate(sleepInfo: SleepInfo) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallSimpleText()
        
        if sleepInfo.isCurrentlySleeping {
            template.textProvider = CLKSimpleTextProvider(text: "😴")
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "🌙")
        }
        
        return template
    }
    
    private func createModularLargeTemplate(sleepInfo: SleepInfo) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        
        template.headerTextProvider = CLKSimpleTextProvider(text: "PolyNap")
        
        if sleepInfo.isCurrentlySleeping {
            template.body1TextProvider = CLKSimpleTextProvider(text: "Uyuyorsunuz")
            template.body2TextProvider = CLKSimpleTextProvider(text: "😴")
        } else {
            template.body1TextProvider = CLKSimpleTextProvider(text: "Sonraki: \(sleepInfo.nextSleepTime)")
            template.body2TextProvider = CLKSimpleTextProvider(text: sleepInfo.nextSleepType)
        }
        
        return template
    }
    
    private func createCircularSmallTemplate(sleepInfo: SleepInfo) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallSimpleText()
        
        if sleepInfo.isCurrentlySleeping {
            template.textProvider = CLKSimpleTextProvider(text: "😴")
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "🌙")
        }
        
        return template
    }
    
    private func createGraphicCornerTemplate(sleepInfo: SleepInfo) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        
        let image = UIImage(systemName: sleepInfo.isCurrentlySleeping ? "bed.double.fill" : "moon.fill")!
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        
        if sleepInfo.isCurrentlySleeping {
            template.textProvider = CLKSimpleTextProvider(text: "Uyku")
        } else {
            template.textProvider = CLKSimpleTextProvider(text: sleepInfo.nextSleepTime)
        }
        
        return template
    }
    
    private func createGraphicCircularTemplate(sleepInfo: SleepInfo) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularImage()
        
        let image = UIImage(systemName: sleepInfo.isCurrentlySleeping ? "bed.double.fill" : "moon.fill")!
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        
        return template
    }
    
    // MARK: - Data Helpers
    
    private func getCurrentSleepInfo(for date: Date = Date()) -> SleepInfo {
        // Bu method gerçek implementasyonda SharedRepository'den veri çekecek
        // Şimdilik mock data kullanıyoruz
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        let isCurrentlySleeping = (hour >= 23 || hour <= 6) || (hour >= 14 && hour <= 15)
        
        let nextSleepTime: String
        let nextSleepType: String
        let timeUntilSleep: String
        
        if hour < 14 {
            nextSleepTime = "14:00"
            nextSleepType = "Şekerleme"
            let hoursUntil = 14 - hour
            timeUntilSleep = "\(hoursUntil)s"
        } else if hour < 23 {
            nextSleepTime = "23:00"
            nextSleepType = "Ana Uyku"
            let hoursUntil = 23 - hour
            timeUntilSleep = "\(hoursUntil)s"
        } else {
            nextSleepTime = "06:00"
            nextSleepType = "Uyanma"
            let hoursUntil = (24 - hour) + 6
            timeUntilSleep = "\(hoursUntil)s"
        }
        
        return SleepInfo(
            nextSleepTime: nextSleepTime,
            nextSleepType: nextSleepType,
            timeUntilSleep: timeUntilSleep,
            isCurrentlySleeping: isCurrentlySleeping
        )
    }
}

// MARK: - Supporting Types

private struct SleepInfo {
    let nextSleepTime: String
    let nextSleepType: String
    let timeUntilSleep: String
    let isCurrentlySleeping: Bool
}

// MARK: - Complication Updates

extension ComplicationController {
    
    static func reloadAllComplications() {
        let server = CLKComplicationServer.sharedInstance()
        
        if let activeComplications = server.activeComplications {
            for complication in activeComplications {
                server.reloadTimeline(for: complication)
            }
        }
        
        print("✅ All complications reloaded")
    }
    
    static func reloadComplications(for families: [CLKComplicationFamily]) {
        let server = CLKComplicationServer.sharedInstance()
        
        if let activeComplications = server.activeComplications {
            for complication in activeComplications {
                if families.contains(complication.family) {
                    server.reloadTimeline(for: complication)
                }
            }
        }
        
        print("✅ Complications reloaded for families: \(families)")
    }
} 