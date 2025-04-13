import Foundation
import Supabase

/// Uyku programları yönetimi için servis sınıfı
class SupabaseScheduleService {
    // Singleton instance
    static let shared = SupabaseScheduleService()
    
    // Supabase istemcisi referansı
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    // Auth servisi referansı
    private var authService: SupabaseAuthService {
        return SupabaseAuthService.shared
    }
    
    // Private initializer for singleton pattern
    private init() {}
    
    /// Önerilen uyku programını Supabase'e kaydeder
    /// - Parameters:
    ///   - schedule: Kaydedilecek uyku programı
    ///   - adaptationPeriod: Adaptasyon süresi (gün cinsinden)
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func saveRecommendedSchedule(
        schedule: SleepScheduleModel,
        adaptationPeriod: Int
    ) async throws -> Bool {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await authService.getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, önerilen program kaydedilemiyor")
            throw SupabaseError.userNotFound
        }
        
        do {
            print("PolySleep Debug: Önerilen program kaydediliyor, id: \(schedule.id)")
            
            // Önce mevcut aktif programı kontrol et
            let activeSchedules: [UserSchedule] = try await client
                .from("user_schedules")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("is_active", value: "true")
                .limit(1)
                .execute()
                .value
            
            // Aktif program varsa ve yeni program ile aynıysa, tekrar kaydetme
            if let activeSchedule = activeSchedules.first {
                // Aktif programın bloklarını al
                let activeBlocks = try await getSleepBlocksForSchedule(scheduleId: activeSchedule.id)
                
                // Aktif program ile yeni program aynı mı kontrol et
                let activeScheduleModel = activeSchedule.toUserScheduleModel(with: activeBlocks)
                
                // Blokları karşılaştır
                if areSchedulesEqual(activeScheduleModel.toSleepScheduleModel, schedule) {
                    print("PolySleep Debug: Mevcut program ile yeni program aynı, tekrar kaydedilmiyor")
                    return true
                }
            }
            
            // Mevcut aktif programı pasif yap
            try await client
                .from("user_schedules")
                .update(["is_active": "false"])
                .eq("user_id", value: user.id.uuidString)
                .eq("is_active", value: "true")
                .execute()
            
            // Yeni schedule ID'si oluştur
            let scheduleId = UUID()
            
            // Açıklamaları JSON olarak hazırla
            let descriptionDict = schedule.description.asDictionary()
            let descriptionJson = SupabaseService.shared.encodeToJson(descriptionDict) ?? "{}"
            
            // Supabase'e user_schedules tablosuna kaydet
            try await client
                .from("user_schedules")
                .insert([
                    "id": scheduleId.uuidString,
                    "user_id": user.id.uuidString,
                    "name": schedule.name,
                    "description": descriptionJson,
                    "total_sleep_hours": "\(schedule.totalSleepHours)",
                    "is_active": "true",
                    "adaptation_phase": String(adaptationPeriod),
                    "created_at": ISO8601DateFormatter().string(from: Date()),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            // Schedule bloklarını user_sleep_blocks tablosuna kaydet
            for block in schedule.schedule {
                let blockId = UUID()
                let blockSyncId = UUID().uuidString
                
                try await client
                    .from("user_sleep_blocks")
                    .insert([
                        "id": blockId.uuidString,
                        "schedule_id": scheduleId.uuidString,
                        "start_time": block.startTime,
                        "duration_minutes": String(block.duration),
                        "is_core": String(block.isCore),
                        "created_at": ISO8601DateFormatter().string(from: Date()),
                        "updated_at": ISO8601DateFormatter().string(from: Date()),
                        "sync_id": blockSyncId
                    ])
                    .execute()
            }
            
            print("PolySleep Debug: Program başarıyla kaydedildi")
            return true
        } catch {
            print("PolySleep Debug: Önerilen program kaydedilemedi: \(error)")
            return false
        }
    }
    
    /// İki programın aynı olup olmadığını kontrol eder
    private func areSchedulesEqual(_ schedule1: SleepScheduleModel, _ schedule2: SleepScheduleModel) -> Bool {
        // Program ismi ve toplam uyku saati kontrolü
        guard schedule1.name == schedule2.name && 
              abs(schedule1.totalSleepHours - schedule2.totalSleepHours) < 0.01 else {
            return false
        }
        
        // Blok sayısı kontrolü
        guard schedule1.schedule.count == schedule2.schedule.count else {
            return false
        }
        
        // Blokları karşılaştır
        let blocks1 = schedule1.schedule.sorted { $0.startTime < $1.startTime }
        let blocks2 = schedule2.schedule.sorted { $0.startTime < $1.startTime }
        
        for i in 0..<blocks1.count {
            let block1 = blocks1[i]
            let block2 = blocks2[i]
            
            if block1.startTime != block2.startTime ||
               block1.duration != block2.duration ||
               block1.isCore != block2.isCore {
                return false
            }
        }
        
        return true
    }
    
    /// Aktif uyku programını getirir
    /// - Returns: Aktif uyku programı veya nil
    @MainActor
    func getActiveSchedule() async throws -> UserSchedule? {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await authService.getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, aktif program alınamıyor. Auth durumu kontrol edilmeli.")
            throw SupabaseError.userNotFound
        }
        
        do {
            print("PolySleep Debug: Aktif program alınıyor, kullanıcı ID: \(user.id.uuidString)")
            
            // Aktif programı al
            let scheduleData: [UserSchedule] = try await client
                .from("user_schedules")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("is_active", value: "true")
                .limit(1)
                .execute()
                .value
            
            if let schedule = scheduleData.first {
                print("PolySleep Debug: Aktif program bulundu, ID: \(schedule.id.uuidString)")
            } else {
                print("PolySleep Debug: Kullanıcının aktif programı bulunamadı")
            }
            
            return scheduleData.first
        } catch {
            print("PolySleep Debug: Aktif program alınamadı: \(error.localizedDescription)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Aktif uyku programını ve bloklarını getirir
    /// - Returns: UserScheduleModel tipinde aktif uyku programı veya nil
    @MainActor
    func getActiveScheduleWithBlocks() async throws -> UserScheduleModel? {
        // Aktif programı al
        guard let activeSchedule = try await getActiveSchedule() else {
            return nil
        }
        
        // Program bloklarını al
        let blocks = try await getSleepBlocksForSchedule(scheduleId: activeSchedule.id)
        
        // UserScheduleModel'e dönüştür
        return activeSchedule.toUserScheduleModel(with: blocks)
    }
    
    /// Belirli bir uyku programının bloklarını getirir
    /// - Parameter scheduleId: Uyku programı ID'si
    /// - Returns: Uyku bloklarının listesi
    @MainActor
    func getSleepBlocksForSchedule(scheduleId: UUID) async throws -> [UserSleepBlock] {
        do {
            // Program bloklarını al
            let blocks: [UserSleepBlock] = try await client
                .from("user_sleep_blocks")
                .select()
                .eq("schedule_id", value: scheduleId.uuidString)
                .execute()
                .value
            
            return blocks
        } catch {
            print("PolySleep Debug: Uyku blokları alınamadı: \(error)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Kullanıcının tüm uyku programlarını getirir
    /// - Returns: Kullanıcının uyku programları
    @MainActor
    func getUserSchedules() async throws -> [UserSchedule] {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await authService.getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, programlar alınamıyor")
            throw SupabaseError.userNotFound
        }
        
        do {
            // Kullanıcının programlarını al
            let scheduleData: [UserSchedule] = try await client
                .from("user_schedules")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return scheduleData
        } catch {
            print("PolySleep Debug: Programlar alınamadı: \(error)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Uyku programını aktif yapar
    /// - Parameter scheduleId: Aktif yapılacak program ID'si
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func setActiveSchedule(scheduleId: UUID) async throws -> Bool {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await authService.getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, program aktif yapılamıyor")
            throw SupabaseError.userNotFound
        }
        
        do {
            // Önce mevcut aktif programı pasif yap
            try await client
                .from("user_schedules")
                .update(["is_active": "false"])
                .eq("user_id", value: user.id.uuidString)
                .eq("is_active", value: "true")
                .execute()
            
            // Yeni programı aktif yap
            try await client
                .from("user_schedules")
                .update(["is_active": "true"])
                .eq("id", value: scheduleId.uuidString)
                .execute()
            
            return true
        } catch {
            print("PolySleep Debug: Program aktif yapılamadı: \(error)")
            return false
        }
    }
    
    /// Uyku programını siler
    /// - Parameter scheduleId: Silinecek program ID'si
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func deleteSchedule(scheduleId: UUID) async throws -> Bool {
        do {
            // Önce program bloklarını sil
            try await client
                .from("user_sleep_blocks")
                .delete()
                .eq("schedule_id", value: scheduleId.uuidString)
                .execute()
            
            // Sonra programı sil
            try await client
                .from("user_schedules")
                .delete()
                .eq("id", value: scheduleId.uuidString)
                .execute()
            
            return true
        } catch {
            print("PolySleep Debug: Program silinemedi: \(error)")
            return false
        }
    }
}

extension LocalizedDescription {
    func asDictionary() -> [String: String] {
        return ["en": en, "tr": tr]
    }
}

// MARK: - Sleep Block Operations
extension SupabaseScheduleService {
    /// Bir uyku programına yeni bir uyku bloğu ekler
    /// - Parameters:
    ///   - scheduleId: Uyku programı ID'si
    ///   - block: Eklenecek uyku bloğu
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func addSleepBlock(scheduleId: UUID, block: SleepBlock) async throws -> Bool {
        do {
            let blockId = UUID()
            let blockSyncId = UUID().uuidString
            
            // Bloğu Supabase'e ekle
            try await client
                .from("user_sleep_blocks")
                .insert([
                    "id": blockId.uuidString,
                    "schedule_id": scheduleId.uuidString,
                    "start_time": block.startTime,
                    "duration_minutes": String(block.duration),
                    "is_core": String(block.isCore),
                    "created_at": ISO8601DateFormatter().string(from: Date()),
                    "updated_at": ISO8601DateFormatter().string(from: Date()),
                    "sync_id": blockSyncId
                ])
                .execute()
            
            print("PolySleep Debug: Uyku bloğu başarıyla eklendi")
            return true
        } catch {
            print("PolySleep Debug: Uyku bloğu eklenemedi: \(error)")
            return false
        }
    }
    
    /// Bir uyku programından belirli bir uyku bloğunu siler
    /// - Parameters:
    ///   - blockId: Silinecek bloğun ID'si
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func deleteSleepBlock(blockId: UUID) async throws -> Bool {
        do {
            // Bloğu Supabase'den sil
            try await client
                .from("user_sleep_blocks")
                .delete()
                .eq("id", value: blockId.uuidString)
                .execute()
            
            print("PolySleep Debug: Uyku bloğu başarıyla silindi")
            return true
        } catch {
            print("PolySleep Debug: Uyku bloğu silinemedi: \(error)")
            return false
        }
    }
    
    /// Bir uyku bloğunu günceller
    /// - Parameters:
    ///   - blockId: Güncellenecek bloğun ID'si
    ///   - block: Güncellenmiş uyku bloğu verisi
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func updateSleepBlock(blockId: UUID, block: SleepBlock) async throws -> Bool {
        do {
            // Bloğu Supabase'de güncelle
            try await client
                .from("user_sleep_blocks")
                .update([
                    "start_time": block.startTime,
                    "duration_minutes": String(block.duration),
                    "is_core": String(block.isCore),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: blockId.uuidString)
                .execute()
            
            print("PolySleep Debug: Uyku bloğu başarıyla güncellendi")
            return true
        } catch {
            print("PolySleep Debug: Uyku bloğu güncellenemedi: \(error)")
            return false
        }
    }
}
