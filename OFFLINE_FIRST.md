# Offline-First Mimarisi Uygulaması

Bu projede, SwiftData ve Supabase kullanarak offline-first mimarisi uygulanmıştır. 

## 1. Oluşturulan Dosyalar ve Sınıflar

1. **SwiftDataModels.swift**
   - `ScheduleEntity`: Programları temsil eden SwiftData modeli
   - `SleepBlockEntity`: Uyku bloklarını temsil eden SwiftData modeli
   - `SleepEntryEntity`: Uyku girdilerini temsil eden SwiftData modeli
   - `PendingChange`: Bekleyen değişiklikleri takip eden model

2. **Repository.swift**
   - Veritabanı işlemlerini koordine eden sınıf
   - Model dönüşümleri ve yerel CRUD işlemleri
   - Değişiklikleri kuyruğa ekleyen mekanizma

3. **SyncEngine.swift**
   - Push ve pull senkronizasyon mantığı
   - Ağ bağlantısı izleme
   - Zamanlanmış arka plan senkronizasyonu
   - Last-Write-Wins (LWW) çakışma çözümü

## 2. Mevcut Servislere Eklenen Fonksiyonlar

**SupabaseScheduleService** ve **SupabaseHistoryService** sınıflarına eklenen fonksiyonlar:

- `getUpdatedSchedules(since:)`: Belirli bir tarihten sonra güncellenen programları getir
- `syncSchedule(...)`: Programı senkronize et (oluştur veya güncelle)
- `syncSleepBlock(...)`: Uyku bloğunu senkronize et
- `syncSleepEntry(...)`: Uyku girdisini senkronize et
- `softDeleteSchedule(id:)`: Programı yumuşak sil
- `softDeleteSleepBlock(id:)`: Uyku bloğunu yumuşak sil
- `softDeleteSleepEntry(id:)`: Uyku girdisini yumuşak sil

## 3. MainScreenViewModel Güncelleme

- `loadScheduleFromRepository()`: Öncelikle yerel veritabanından programı yükler
- `loadScheduleFromSupabase()`: Gerektiğinde Supabase'den programı yükler ve yerel veritabanına kaydeder
- `saveSchedule()`: Programı yerel veritabanına kaydeder ve arka planda senkronizasyonu başlatır

## 4. PolySleepApp Güncelleme

- SwiftData modellerini yapılandırmak için `configureSwiftData()` metodu
- ModelContext'i Repository ve SyncEngine ile paylaşma

## 5. Veri Akışı Özeti

1. **Veri Okuma**:
   - Önce Repository üzerinden yerel veritabanına (SwiftData) bakılır
   - Yerel veritabanında veri yoksa Supabase'den alınır ve yerel veritabanına kaydedilir
   - Kullanıcı arayüzü her zaman yerel veritabanındaki verileri gösterir

2. **Veri Yazma**:
   - Veri önce yerel veritabanına kaydedilir
   - Değişiklik bir PendingChange nesnesi olarak kuyruğa alınır
   - Arka planda SyncEngine, kuyruktaki değişiklikleri Supabase'e gönderir

3. **Senkronizasyon**:
   - İnternet bağlantısı yeniden kurulduğunda otomatik senkronizasyon başlar
   - Zamanlayıcı ile düzenli aralıklarla senkronizasyon yapılır
   - Last-Write-Wins stratejisi ile çakışmalar çözülür

## 6. Faydalar

- İnternet bağlantısı olmadan da uygulama tam fonksiyonel çalışır
- Kesintili bağlantı durumlarında veri kaybı yaşanmaz
- Yerel veritabanı tek doğru kaynak olduğu için tutarlılık korunur
- Hızlı kullanıcı deneyimi (veriler için internet bağlantısı beklenmez)
- Ağ trafiği optimizasyonu (sadece değişiklikler senkronize edilir)

## 7. Sonraki Adımlar

- Veri şeması değişiklikleri için migrasyon planlaması
- SwiftData modelleri için daha kapsamlı test kapsama alanı
- Realtime abonelikleri ile gerçek zamanlı güncellemeler
- Senkronizasyon hata günlüğü arayüzü
- Kullanıcı tarafından manuel senkronizasyon tetikleme seçeneği 