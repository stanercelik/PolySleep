import Foundation
import SwiftUI

class DailyTipManager {
    private static let tipKeys = [
        "tip.sleep.adaptation",
        "tip.sleep.alertness",
        "tip.sleep.ancient",
        "tip.sleep.animals",
        "tip.sleep.athletes",
        "tip.sleep.bat",
        "tip.sleep.biological",
        "tip.sleep.brain_cycles",
        "tip.sleep.chess",
        "tip.sleep.creativity_boost",
        "tip.sleep.dreams",
        "tip.sleep.eeg",
        "tip.sleep.energy",
        "tip.sleep.esports",
        "tip.sleep.famous",
        "tip.sleep.farmer",
        "tip.sleep.history",
        "tip.sleep.japanese",
        "tip.sleep.melatonin",
        "tip.sleep.memory_boost",
        "tip.sleep.metabolism",
        "tip.sleep.mountaineer",
        "tip.sleep.nasa",
        "tip.sleep.natural_wake",
        "tip.sleep.parent",
        "tip.sleep.sailor",
        "tip.sleep.startup",
        "tip.sleep.stress_mechanism",
        "tip.sleep.time_management",
        "tip.sleep.travel"
    ]
    
    private static let lastUsedTipsKey = "LastUsedTipsKey"
    private static let lastTipDateKey = "LastTipDateKey"
    
    static func getDailyTip() -> LocalizedStringKey {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = defaults.object(forKey: lastTipDateKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return LocalizedStringKey(defaults.string(forKey: "CurrentTipKey") ?? tipKeys[0])
        }
        
        var lastUsedTips = defaults.array(forKey: lastUsedTipsKey) as? [String] ?? []
        
        if lastUsedTips.count >= 30 || lastUsedTips.isEmpty {
            lastUsedTips = []
        }
        
        let unusedTips = tipKeys.filter { !lastUsedTips.contains($0) }
        
        let randomTip = unusedTips.randomElement() ?? tipKeys[0]
        
        lastUsedTips.append(randomTip)
        
        defaults.set(lastUsedTips, forKey: lastUsedTipsKey)
        defaults.set(today, forKey: lastTipDateKey)
        defaults.set(randomTip, forKey: "CurrentTipKey")
        
        return LocalizedStringKey(randomTip)
    }
}
