# PolySleep - Polifazik Uyku Programı Asistanı  
## Ürün Gereksinimleri Dokümanı (PRD) + UI/UX Önerileri  

---

## 1. Ürün Genel Bakış  
**PolySleep**, kullanıcıların polifazik uyku düzenlerini kolayca takip etmelerine ve optimize etmelerine yardımcı olan bir iOS uygulamasıdır. Uygulama, kullanıcıların uyku programlarını kişiselleştirmelerine, günlük uyku alışkanlıklarını kaydetmelerine ve analiz etmelerine olanak tanır. MVP'de temel uyku takibi, geçmiş kayıtları, analizler ve rozet sistemi bulunurken, premium özellikler ve sosyal paylaşım gibi gelişmiş özellikler gelecek sürümlerde entegre edilecektir.  

**UI/UX Notu**  
- Uygulama ilk açılışta kullanıcıları onboarding akışıyla karşılar.  
- Tab bar veya benzeri bir navigasyon yapısıyla "Ana Sayfa", "History", "Analytics", "Profil" sekmelerine hızlı erişim sağlanır.  

---

## 2. Teknik Mimari  

### 2.1 Teknoloji Yığını  
- **Framework**: SwiftUI  
- **Veri Kalıcılığı**: SwiftData  
- **Mimari Desen**: MVVM (Model-View-ViewModel)  
- **Bildirimler**: `UserNotifications` + `AVFoundation` (Alarm için)  
- **Monetizasyon**: RevenueCat (Abonelik Yönetimi)  
- **Minimum iOS Sürümü**: iOS 17.0  

---

## 3. Özellik Seti  

### 3.1 Onboarding Akışı (11 Adım)  
Kullanıcıdan aşağıdaki bilgiler toplanır:  
1. **Önceki Uyku Deneyimi**  
2. **Yaş Aralığı**  
3. **İş/Çalışma Programı**  
4. **Şekerleme Yapabileceği Ortam**  
5. **Uyku Hedefleri**  
6. **Sağlık Koşulları**  
7. **Yaşam Tarzı Faktörleri**  
8. **Uyku Ortamı Kalitesi**  
9. **Günlük Yükümlülükler**  
10. **Uyku Tercihleri**  
11. **Kronotip**  

**Onboarding Sonu Ekranı**:  
- Önerilen uyku programı görsel olarak gösterilir.  
- Kullanıcı programı kabul edip ana sayfaya geçebilir veya düzenleyebilir.  

**UI/UX Önerileri**  
- **Adım Tabanlı Ekranlar**: Her adım için tam ekran bir sayfa kullanarak (ör. `TabView` veya `NavigationStack`) kullanıcıya net bir odak sağlanır.  
- **İlerleme Göstergesi (Progress Bar)**: Ekranın üst kısmında % değerinde veya noktasal ilerleme göstergesi olmalı.  
- **Kısa Soru - Net Cevap**: Her adımda metin alanlarının yanı sıra radyo butonları, toggle veya picker gibi arayüz bileşenleri kullanılabilir.  
- **Özet Kartı**: Son adımda, toplanan verilerin kısa bir özeti ve bu verilere göre oluşturulmuş uyku programı timeline şeklinde sunulur.  
- **Kabul & Düzenleme Butonları**: “Kabul Et” (birincil buton) ve “Düzenle” (ikincil buton) şeklinde ekrana yerleştirilir.  

---

### 3.2 Ana Sayfa  
- **Uyku Programı Görselleştirme**: 24 saatlik timeline üzerinde uyku blokları (mavi dikdörtgenler).  
- **Program Düzenleme**: Sürükle-bırak veya zaman aralığı girme.  
- **Toplam Uyku Süresi**: Gerçek zamanlı hesaplama.  
- **Şu Anki Uyku Durumu**:  
  - "Sonraki Uyku: 14:00"  
  - "Kalan Süre: 1h 20m"  
- **Alarm Butonu**: Bildirim ayarlarına gider.  

**UI/UX Önerileri**  
- **Sekme Yerleşimi**: Ana Sayfa, uygulamanın tab barında (ör. sol başta) veya varsayılan açılış ekranı olarak konumlandırılabilir.  
- **24 Saatlik Timeline**: Ekranın üst kısmında yatay olarak kaydırılabilir veya dikey bir "saat çizgisi" kullanılabilir. Mavi dikdörtgenler, planlanan uyku bloklarını gösterir.  
- **Blok Etkileşimi**:  
  - **Dokun + Sürükle**: Bloğu sağa sola kaydırarak başlama ve bitiş saatleri ayarlanabilir.  
  - **Uzun Basma**: Düzenleme modu açılır, saat seçmek için bir `DatePicker` veya benzeri bir modal görüntülenir.  
- **Bilgi Kartı**: Timeline’ın altında kullanıcıya "Toplam Uyku Süresi" ve "Şu Anki Uyku Durumu"nu gösteren bir kart bulunur. Renkli ikonlar veya küçük infografikler ile zenginleştirilebilir.  
- **Alarm Butonu**: Ekranın sağ üst köşesinde çan veya çalar saat simgesi bulunur, dokununca uygulama bildirim/alarmlar için ayar ekranına yönlendirir (veya sistem ayarlarına yönlendirebilir).  
- **Kullanıcı Geri Bildirimi**: Düzenleme sonrası bir "Kaydedildi" uyarısı veya kısa bir animasyon göstererek başarılı kaydı bildirmek kullanıcı deneyimini artırır.  

---

### 3.3 History (Geçmiş) Sayfası  
- **Takvim Görünümü**:  
  - Yeşil daire: Tamamlanan program (%100)  
  - Sarı yarım daire: Kısmen tamamlanan (%50)  
  - Kırmızı çarpı: Kaçırılan uyku  
- **Günlük Detay**:  
  - 🌙 Core Sleep: 3h 20m (⭐️⭐️⭐️⭐️)  
  - ⚡️ Nap 1: 20m (⭐️⭐️)  
  - "Detayları Düzenle" butonu (Emoji/yıldız güncelleme)  
- **Filtreleme Seçenekleri**:  
  - "Bu Hafta" | "Bu Ay" | "Tüm Zamanlar"  
- **İstatistik Özeti**:  
  - "Ortalama Sleep Score: 4.2/5 ⭐️"  

**UI/UX Önerileri**  
- **Tab Bar Konumu**: History sekmesi, Ana Sayfa’nın hemen yanında konumlandırılabilir.  
- **Takvim Tasarımı**: Grid şeklinde aylık görünüm veya haftalık görünüm seçilebilir.  
  - *Renk Kodlaması*: Her günün altında/dairesinde plan uyumu gösterilir.  
  - *Animasyon*: Geçmişteki bir günü seçince, seçilen tarih daha büyük veya farklı renkte vurgulanır.  
- **Günlük Detay Ekranı**:  
  - Aşağıdan açılan bir sheet veya tam ekran bir sayfa olarak tasarlanabilir.  
  - Core Sleep ve Nap bloklarının süreleri, verilen yıldız veya emoji ile sıralanır.  
  - "Detayları Düzenle" butonu, sağ üst köşede "kalem" ikonu veya altında bir “Düzenle” butonu olarak sunulabilir.  
- **Filtre Çubuğu**: Ekranın üst kısmında segment kontrolü (Bu Hafta | Bu Ay | Tüm Zamanlar) şeklinde tasarlanabilir. Seçime göre takvim veya liste görünümü değişir.  
- **İstatistik Özeti**:  
  - Ekranın altında veya üstünde sabit bir kart tasarımı olabilir.  
  - Renkli ikonlar ile Sleep Score, ortalama uyku süresi gibi metrikler gösterilir.  

---

### 3.4 Analytics (Analiz) Sayfası  
- **Sleep Quality Trends**:  
  - Çizgi grafik: Uyku süresi (mavi) ve Sleep Score (yeşil).  
  - Zaman Aralığı: "Son 7 Gün" | "Son 30 Gün" | "Son 90 Gün"  
- **Kazanılan Zaman Hesaplama**:  
  - "Normal Uykuya Göre Kazanç: 412 saat 🎉"  
  - "Bu Haftaki Tasarruf: 14 saat"  
- **Sleep Breakdown**:  
  - Pasta grafiği: Core Sleep (%65), Nap 1 (%20), Nap 2 (%15).  
  - Detaylı yüzdelikler: "Ortalama Core Uyku Süresi: 2h 50m"  
- **Paylaşım Özelliği**:  
  - Özelleştirilebilir görsel oluşturur (Haftalık performans infografiği).  

**UI/UX Önerileri**  
- **Grafik Bileşenleri**: SwiftUI’da yerleşik `Chart` veya 3. parti kütüphaneler kullanılabilir.  
- **Segment Kontrolü/Zaman Aralığı**: Ekranın üst kısmında "7 Gün / 30 Gün / 90 Gün" gibi seçenekler, grafiğin verilerini dinamik olarak günceller.  
- **Kazanılan Zaman Kartı**: Grafiğin altına "Kazanılan Zaman" ve "Bu Haftaki Tasarruf"u vurgulayan renkli veya resimli bir kart konabilir.  
- **Pasta Grafiği**: Alt kısımda “Sleep Breakdown” bölümünde küçük bir donut chart/pie chart kullanılabilir; renkli dilimler hangi bloğa ne kadar süre ayrıldığını gösterir.  
- **Paylaş Butonu**: Ekranın sağ üst köşesinde klasik “share” ikonu veya alt tarafta büyük bir buton olabilir. Dokunulduğunda haftalık/aylık/özet verilerin olduğu bir infografik hazırlanarak iOS Share Sheet açılır.  
- **Animasyonlar**: Grafik geçişlerinde veya segment seçimlerinde basit fade/slide animasyonları deneyimi güçlendirir.  

---

### 3.5 Profil Sayfası  
- **Streak Sistemi**:  
  - 🔥 "17 Günlük Streak!" (Animasyonlu ateş efekti)  
  - "En Yüksek Streak: 23 Gün"  
- **Rozet Koleksiyonu**:  
  - 3 sütunlu grid (Kilitli/Açık).  
  - Örnek Rozetler: "Yeni Başlayan" 🟢, "Demir İrade" 🏋️♂️, "Gece Kuşu" 🌙.  
- **Kişiselleştirme**:  
  - Emoji Seçici: Core Sleep için 🌙/💤/😴, Nap için ⚡/☕/👁️.  

**UI/UX Önerileri**  
- **Streak Gösterimi**:  
  - Üst kısımda büyük ve dikkat çekici bir şekilde gün sayısı gösterilir.  
  - Ateş efekti, animasyonlu veya hareketli bir gif benzeri bir komponent ile dikkat çeker.  
- **Rozetler**:  
  - Grid görünümünde, kilitli rozetler grileştirilmiş veya yarı saydam gösterilir.  
  - Rozetlerin altına küçük açıklama ve ilerleme yüzdesi (örn. “10/20 gün tamamlandı”) eklenebilir.  
  - Rozet üzerine tıklayınca açılan bir modal veya sheet ile rozetin açılma koşulu gösterilebilir.  
- **Kişiselleştirme Kartı**:  
  - Profil ekranının alt kısmında “Core Sleep Emojini Seç” veya “Nap Emojini Seç” gibi alanlar olabilir.  
  - Kullanıcı emojiye dokunduğunda, bir `GridPicker` ya da iOS benzeri bir picker açılır.  
- **Diğer Ayarlar**: Profil ekranında, premium abonelik durumu veya hesap ayarlarına gitmek için bir “Ayarlar” butonu da bulunabilir.  

---

### 3.6 Uyku Kayıt Mekanizması  
- **Otomatik Takip**:  
  - Program saatinde bildirim: "Uyku Zamanı! Nasıl Geçti?"  
  - Hızlı Yanıt Seçenekleri: "Tamamlandı 🌟", "Yarıda Kesti ❌", "Erteleme ⏸️".  
- **Manuel Düzenleme**:  
  - History → Takvim → Gün seç → "Eksik Kaydı Ekle".  

**UI/UX Önerileri**  
- **Bildirim Tasarımı**:  
  - Bildirimde kısaca “Uyku zamanın geldi. Tamamladın mı?” gibi bir metin ve 2-3 aksiyon butonu bulunur.  
  - Hızlı yanıtlar, iOS bildirim eylemleri olarak eklenir (örn. sürükleme veya basılı tutma ile görünür).  
- **Manuel Kayıt**:  
  - History sayfasında kullanıcı bir güne dokunduğunda, açılan detayda "Kayıt Ekle" butonu görünür.  
  - Süre seçimi ve başlangıç/bitiş saatini ayarlamak için bir `DatePicker` açılır.  
- **Katkı ve Geri Bildirim**:  
  - Kullanıcı tamamlama sonrası “ne kadar dinç hissediyorsun?” şeklinde bir 5 yıldız rating veya emoji seçici de sunulabilir.  
- **Tutarlılık Uyarıları**:  
  - Planlanan uyku ile kaydedilen uyku arasında büyük farklar varsa uyarı ile hatırlatılabilir.  

---

### 3.7 Sleep Score Algoritması  
```swift
func calculateSleepScore() -> Double {
    let timingAccuracy = (gerçekBaşlangıç - planlananBaşlangıç) < 5dk ? 1.0 : 0.7
    let durationRatio = min(gerçekSüre / planlananSüre, 1.0)
    let consistencyBonus = streak >= 7 ? 0.2 : 0
    return (timingAccuracy * 0.4 + durationRatio * 0.6 + consistencyBonus) * 5
}
```

**UI/UX Önerileri**  
- **Skor Gösterimi**:  
  - 5 üzerinden yıldızla gösterim (örn. 4.2 / 5 ⭐️).  
  - Özellikle "History" veya "Analytics" sayfasındaki günlük detaylarda bu skor net şekilde vurgulanabilir.  
- **Renkli Geri Bildirim**:  
  - Skor yüksekse (4-5 aralığı) yeşil, orta (2-4) sarı, düşük (0-2) kırmızı bir tema kullanılabilir.  
- **İpucu Mesajları**:  
  - Düşük skor durumunda “Zamanlamayı düzenle” veya “Daha uzun uyku bloğu planla” gibi öneri mesajları eklenebilir.  

---

## 4. Veri Modelleri (SwiftData)  

### 4.1 `SleepSchedule`  
```swift
@Model
class SleepSchedule {
    var scheduleID: String
    var name: String
    var sleepBlocks: [SleepBlock]
    var isPremium: Bool
}
```

### 4.2 `DailySleepEntry`  
```swift
@Model
class DailySleepEntry {
    var date: Date
    var sleepBlocks: [SleepBlock]
    var selectedEmoji: String
    var sleepScore: Double
}
```

### 4.3 `Achievement`  
```swift
@Model
class Achievement {
    var badgeID: String
    var unlockCondition: String
    var isUnlocked: Bool
}
```

**UI/UX Önerileri**  
- Veriler arka planda SwiftData ile senkronize edilir; kullanıcıya veri kaybolmaması için çeşitli “Güncellendi” geri bildirimleri verilebilir.  
- Çok büyük veri setlerinde performans optimizasyonu için lazy loading veya sayfalama stratejileri düşünülebilir (takvimde uzun yıllar).  

---

## 5. Monetizasyon Stratejisi  

### 5.1 RevenueCat Entegrasyonu  
- **Abonelik Planları**: Aylık ($4.99) / Yıllık ($39.99).  
- **Ücretsiz Deneme**: 7 günlük trial süresi.  
- **Premium Özellikler**:  
  - Sınırsız geçmiş kaydı.  
  - Gelişmiş analizler.  
  - Rozet özelleştirme.  

**UI/UX Önerileri**  
- **Premium Sayfası**: Profil veya Ayarlar ekranında “Premium’a Geç” butonu. Dokunulduğunda RevenueCat paywall ekranı veya özel tasarlanmış abonelik ekranı açılır.  
- **Özellik Kilitleri**: Premium özelliklere tıklandığında “Bu özellik Premium kullanıcılar için” şeklinde bir modal veya pop-up göstermek, kullanıcıyı aboneliğe yönlendirmek.  
- **Abonelik Durumu**: Profil ekranının üstünde veya altında “Aktif Abonelik”/“Deneme Sürümü - X Gün Kaldı” şeklinde göstergeler olabilir.  

---

## 6. Gelecek Özellikler  
1. **Sosyal Karşılaştırma**: Arkadaşlarla streak yarışmaları.  
2. **Uyku Sesleri Entegrasyonu**: Beyaz gürültü oynatıcı (Premium özellik).  
3. **AI Tavsiyeleri**: "Uyku Verimliliğini %15 Artırmak İçin..."  

**UI/UX Önerileri**  
- **Sosyal Skor Listesi**: Arkadaş listesi veya global bir leaderboard sekmesi eklenebilir.  
- **Ses Oynatıcı**: Ana sayfada veya ayrı bir “Relax” sekmesinde beyaz gürültü, yağmur sesi gibi seçenekler sunulabilir; oynatma/ duraklatma kontrolü basit bir player bar ile sağlanabilir.  
- **AI Tavsiyeleri**:  
  - Analytics sayfasının altında “Kişisel Öneriler” başlığıyla basit kartlar çıkar.  
  - Kullanıcı davranışlarını analiz ederek push notifikasyon veya menü içi bildirimle kısa öneriler sunulur.  

---

## 7. Güvenlik ve Gizlilik  
- **Veri Şifreleme**: SwiftData modelleri için `@Attribute(.encrypt)`.  
- **GDPR Uyumluluğu**: Kullanıcı verileri yalnızca yerelde saklanır.  

**UI/UX Önerileri**  
- **Gizlilik Sayfası**: Profil/Ayarlar menüsünde “Gizlilik Politikası” linki bulunmalı.  
- **İzin Ekranları**: İlk başta bildirim izinleri veya sağlık verisi izni istenirken, kullanıcıya açık ve anlaşılır metinlerle neden bu verilerin istendiği belirtilmeli.  

---

## 8. Çıkış Planı  
- **MVP**: Temel uyku takibi, geçmiş kayıtları, analizler, rozet sistemi.  
- **1.1 Sürüm**: RevenueCat entegrasyonu ve premium özellikler.  
- **1.2 Sürüm**: Sosyal paylaşım ve AI tavsiyeleri.  

**UI/UX Önerileri**  
- MVP sürümünde basit tasarımları hızlıca doğrulayın, kullanıcı geri bildirimlerini toplayın.  
- 1.1 sürümünde premium paywall ve abonelik akışı net ve basit olmalı, kullanıcıyı karmaşık adımlara maruz bırakmamalı.  
- 1.2 sürümünde sosyal özelliklerin eklenmesiyle birlikte profil ve paylaşımlar için tasarımları genişletmek gerekebilir.  

---

**Not:** Bu PRD, **SwiftUI + MVVM + SwiftData** mimarisi ve RevenueCat entegrasyonu dikkate alınarak hazırlanmıştır. MVP'de temel özellikler sunulurken, gelecek sürümlerde kullanıcı geri bildirimlerine göre strateji esnetilebilir. Bu dokümandaki UI/UX önerileri uygulama genelinde rehber niteliğindedir ancak tasarım ekibiyle birlikte iteratif olarak geliştirilebilir.