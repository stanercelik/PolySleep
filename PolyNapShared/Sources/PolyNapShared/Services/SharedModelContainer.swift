//
//  SharedModelContainer.swift
//  PolyNapShared
//
//  Created by Taner Çelik on 5.07.2025.
//

import SwiftData
import Foundation

/// Shared ModelContainer yapılandırması ve yönetimi
public final class SharedModelContainer {
    
    // MARK: - Public Factory Methods
    
    /// Shared ModelContainer oluşturur
    /// - Parameter inMemory: True ise in-memory container oluşturur (testing için)
    /// - Returns: Yapılandırılmış ModelContainer
    /// - Throws: ModelContainer oluşturma hatası
    public static func createSharedModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: SharedUser.self, 
                 SharedUserSchedule.self, 
                 SharedSleepBlock.self, 
                 SharedSleepEntry.self,
            configurations: config
        )
    }
    
    /// Production için optimize edilmiş ModelContainer oluşturur
    /// - Returns: Production yapılandırması ile ModelContainer
    /// - Throws: ModelContainer oluşturma hatası
    public static func createProductionContainer() throws -> ModelContainer {
        return try createSharedModelContainer(inMemory: false)
    }
    
    /// Test için in-memory ModelContainer oluşturur
    /// - Returns: In-memory ModelContainer
    /// - Throws: ModelContainer oluşturma hatası
    public static func createTestContainer() throws -> ModelContainer {
        return try createSharedModelContainer(inMemory: true)
    }
    
    /// Fallback ModelContainer oluşturur (hata durumlarında)
    /// - Returns: Fallback ModelContainer veya nil
    public static func createFallbackContainer() -> ModelContainer? {
        do {
            // Önce in-memory deneme
            return try createTestContainer()
        } catch {
            print("❌ Fallback ModelContainer bile oluşturulamadı: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Configuration Helpers
    
    /// Desteklenen tüm model tiplerini döndürür
    public static var supportedModels: [any PersistentModel.Type] {
        return [
            SharedUser.self,
            SharedUserSchedule.self,
            SharedSleepBlock.self,
            SharedSleepEntry.self
        ]
    }
    
    /// Container'ın sağlık durumunu kontrol eder
    /// - Parameter container: Kontrol edilecek ModelContainer
    /// - Returns: Container sağlıklı ise true
    @MainActor public static func validateContainer(_ container: ModelContainer) -> Bool {
        do {
            let context = container.mainContext
            // Basit bir sorgu ile container'ın çalışıp çalışmadığını test et
            let fetchRequest = FetchDescriptor<SharedUser>()
            _ = try context.fetch(fetchRequest)
            return true
        } catch {
            print("❌ ModelContainer validation failed: \(error.localizedDescription)")
            return false
        }
    }
} 
