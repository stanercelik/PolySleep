# PolySleep - Polifazik Uyku Programı Asistanı  
## Ürün Gereksinimleri Dokümanı (PRD)  

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

# 1. Ürün Genel Bakış  
**PolySleep**, kullanıcıların polifazik uyku düzenlerini kolayca takip etmelerine ve optimize etmelerine yardımcı olan bir iOS uygulamasıdır. Uygulama, kullanıcıların uyku programlarını kişiselleştirmelerine, günlük uyku alışkanlıklarını kaydetmelerine ve analiz etmelerine olanak tanır. İlk sürümde (MVP) temel uyku takibi, geçmiş kayıtları, analizler ve rozet sistemi bulunacaktır. İlerleyen sürümlerde **premium** özellikler (RevenueCat abonelik yönetimi), sosyal paylaşım, ileri düzey kişiselleştirme, yapay zekâ tavsiyeleri vb. özellikler eklenecektir.

**Başlıca Hedefler**  
1. Kolay ve hızlı başlama (kullanıcıyı login/register zorunluluğuna sokmadan).  
2. Kişiselleştirilmiş uyku programı oluşturma ve düzenleme.  
3. Geçmiş ve analiz ekranlarıyla ilerlemenin takibi.  
4. Motivasyonu artıran rozet, streak sistemi.  

---

# 2. MVP'de Olması Gereken Özellikler

**1. Onboarding Akışı**  
- Kullanıcıdan çeşitli bilgiler (uyku deneyimi, yaş, kronotip vb.) toplanır.  
- Son adımda önerilen polifazik uyku programı oluşturulur.  
- Kullanıcı bu programı kabul edebilir veya düzenleyebilir.

**2. Ana Sayfa (Uyku Programı Ekranı)**  
- 24 saatlik timeline üzerinde planlanan uyku bloklarını gösterir.  
- Blokları düzenleyebilme (edit modu).  
- Güncel uyku durumu (kalan süre, sonraki blok).  

**3. History (Geçmiş)**  
- Takvim veya liste görünümünde geçmiş kayıtlar.  
- Kişisel Sleep Score, tamamlanma oranı (yeşil, sarı, kırmızı ikonlar).  
- Gün seçilince detay modal veya sayfası.

**4. Analytics (Analizler)**  
- Temel çizgi grafik (toplam uyku süresi, Sleep Score).  
- Pasta grafiğiyle Core Sleep/Nap dağılımı.  
- Kazanılan zaman bilgisi ("Bu hafta 14 saat kazandın!" vb.).  

**5. Profil (Streak ve Rozetler)**  
- Günlük veya haftalık streak takibi.  
- Açılmış/kilitli rozetler.  
- Basit emoji kişiselleştirmeleri (Core Sleep, Nap).  

**6. Uyku Kayıt Mekanizması**  
- Planlanan saatlerde bildirim (alarm).  
- Bildirimde hızlı yanıt ("Başlıyorum", "Ertele", "İptal").  
- Manuel düzenleme (History ekranından eksik kaydı ekleme).  

> **Not**: Premium özellikler (sınırsız tarih kaydı, gelişmiş analiz vb.) sonraki sürüme ertelenebilir ya da kısmi olarak sunulabilir.

---

# 3. Tasarım Sistematiği & Global Stiller

Bu bölüm, Apple Human Interface Guidelines doğrultusunda tasarım dili ve görsel standartları tanımlar. Tüm ekranlar ve bileşenler bu sisteme uyum sağlayacaktır.

## 3.1 Renk Paleti

| Renk Adı            | Light Modu      | Dark Modu       | Kullanım                          |
| ------------------- | --------------- | --------------- | --------------------------------- |
| **AccentColor**     | `#FF9800`       | `#FF9800`       | Önemli butonlar, aktif toggles    |
| **BackgroundColor** | `#F8F9FA`       | `#121212`       | Ana sayfa arka planı             |
| **CardBackground**  | `#FFFFFF`       | `#171717`       | Kartlar, modal yüzeyler          |
| **PrimaryColor**    | `#2196F3`       | `#2196F3`       | Başlıklar, önemli etkileşimler   |
| **SecondaryColor**  | `#4CAF50`       | `#4CAF50`       | Başarı durumları, pozitif vurgu  |
| **TextColor**       | `#2C2C2C`       | `#FEFFFF`       | Ana metin rengi                  |
| **SecondaryTextColor** | `#6C757D`   | `#BDBDBD`       | Yardımcı metin, alt başlıklar    |

- **Kontrast**: Metin ve arka plan arasındaki kontrast, WCAG gereksinimlerini (en az 4.5:1) karşılayacak şekilde kullanılır.  
- **Örnek Kullanım**:  
  - **AccentColor** genelde CTA (Call-to-Action) butonlarında kullanılır.  
  - **PrimaryColor** (mavi) başlıkların veya önemli label’ların rengi olabilir.  

## 3.2 Tipografi

- **Başlık 1 (H1)**: `SF Pro Rounded Bold`, 28pt  
- **Başlık 2 (H2)**: `SF Pro Rounded Semibold`, 22pt  
- **Body**: `SF Pro Text Regular`, 16pt  
- **Caption**: `SF Pro Text Light`, 14pt  

> Apple HIG ile **Dynamic Type** desteği uygulanır. Yazı boyutu kullanıcı ayarlarına göre otomatik büyüyüp küçülebilir.

## 3.3 Köşe Yuvarlaklığı (Corner Radius)

- **Butonlar, Kartlar**: 12px  
- **Daha Büyük Kartlar / Modallar**: 20px  
- **Yuvarlak Bileşenler (Progress, Daire)**: %100 (dairesel)

## 3.4 Gölge (Shadow)

- **Hafif**: `0px 2px 8px rgba(0,0,0,0.1)`  
- **Orta**: `0px 4px 12px rgba(0,0,0,0.15)`  
- **Yoğun**: `0px 8px 24px rgba(0,0,0,0.2)`  

Kart ve butonların genelde “hafif” veya “orta” gölge kullanarak yumuşak bir görünüm vermesi önerilir.

## 3.5 Animasyonlar

- **Hafif Etkileşimler**: `0.2s Ease-In-Out` (Butona dokunma, hover vs.)  
- **Modallar**: `0.3s Spring Effect` (Alttan açılma, kapatma)  
- **Transition**: Ekranlar arasında yatay “slide” veya yumuşak fade geçişleri.

## 3.6 Mikro-Etkileşimler & Geri Bildirim

- **Buton Tıklaması**: Hafif “scale-down” (`0.95`) ve opaklık azaltma (`0.8`).  
- **Haptic Feedback**: Başarılı işlemlerde yumuşak (`soft`), hatalarda sert (`rigid`).  
- **Bildirim Eylemleri**: Uzun basınca ek aksiyon butonları.

## 3.7 Erişilebilirlik

- **Dinamik Tipografi**: Otomatik ölçeklendirme.  
- **VoiceOver Etiketleri**: Her etkileşimli öğe için anlaşılır açıklamalar.  
- **Renk Körlüğü Desteği**: Kritik öğelerde renk + ikon/doku beraber kullanılması.

---

# 4. Ekran Bazlı UI/UX Detayları

Aşağıda, MVP kapsamında yer alan ana ekranların tasarım ve etkileşim detayları yer almaktadır.

## 4.1 Onboarding Akışı

### 4.1.1 Genel Layout

- **Üst Kısım**:  
  - **Progress Bar** (12px yüksekliğinde, `PrimaryColor` dolumu).  
  - Adım başlığı: “Adım 1 / 11” gibi.  
- **Soru Kartı**: `CardBackground` rengi, 20px köşe yuvarlaklığı, orta gölge.  
- **Cevap Seçenekleri**:  
  - Her bir seçenek 12px radius’lu mini kart şeklinde.  
  - Seçim yapıldığında `AccentColor` ile sınır çizgisi (`2px`), hafif **scale-up** animasyonu.  

### 4.1.2 Onboarding Adımları

Her adımda tek bir soru, cevap seçenekleri (radyo buton, picker vb.). Metinler 16pt (Body) veya 22pt (Başlık 2) olabilir.

Örnek Sorular:  
1. Önceki Uyku Deneyimi  
2. Yaş Aralığı  
3. İş/Çalışma Programı  
...  
11. Motivasyon Seviyesi

> **Geçişler**: “İleri” butonuna basınca yeni soru, **slideFromRight** animasyonuyla gelir. Geri butonunda **slideFromLeft**.

### 4.1.3 Onboarding Son Ekran (Özet)

- **Önerilen Uyku Programı**: Yatay çizgi veya dairesel saat gösterimi.  
- **Özet Kartı**: Kullanıcının seçtiği değerler kısaca listelenir.  
- **Kabul Et** (PrimaryColor arka plan, beyaz metin) ve **Düzenle** (SecondaryTextColor border) butonları.

---

## 4.2 Ana Sayfa

### 4.2.1 Üst Kısım

- **Başlık**: “Bugünün Programı” (H1, 28pt).  
- **Tarih/Hoş Geldin Metni**: 16pt, SecondaryTextColor.  

### 4.2.2 24 Saatlik Timeline

- **Zaman Çizelgesi**: Şu anki hali gibi gözükecek. Bir çember olacak ve uyku blokları orada gösterilecek.  
- **Uyku Blokları**: `AccentColor` dolgu, 12px radius. Üzerinde küçük emoji (🌙 Core Sleep, ⚡ Nap).  
- **Düzenleme Modu**: Ekranın sağ üst köşesindeki “Düzenle” ikonu/penceresi  
  - Aktifken blokların kenarlarında tutma noktaları belirir. Sürükle-bırak ile saat ayarlanır.  
  - “Kaydet” ve “Vazgeç” butonları alt tarafta çıkar.

### 4.2.3 Bilgi Panosu (Kısa Özet)

- **Toplam Uyku Süresi**: Büyük fontla (PrimaryColor).  
- **Sonraki Uyku Bloğu**: “14:00 - 1s 20d kaldı” (SecondaryColor vurgusu).  
- Arka plan: `CardBackground`, 12px radius, hafif gölge.

### 4.2.4 Ek Mini Bölüm (Öneriler / Güncel İpuçları)

- “Bugünkü hedefin 4.5 saat total uyku” vb.  
- Küçük progress bar (ne kadarını tamamladın).  
- Detaylara tıklandığında Analytics sayfasına geçiş.

---

## 4.3 History (Geçmiş)

### 4.3.1 Takvim Görünümü

- **Grid**: Aylık takvim, her gün 40x40px hücre.  
- **Durum İkonları**:  
  - Yeşil: %100 tamamlama  
  - Sarı: %50 kısmen tamam  
  - Kırmızı: Kaçırılan uyku  
- Seçili gün: `PrimaryColor` border, 3px kalınlık + hafif scale-up animasyonu.

### 4.3.2 Detay Modal / Ekran

- **Header**: Tarih (Başlık 2), kapatma butonu sağ üstte (kare X ikonu).  
- **Uyku Blokları**: Kart görünümünde Core Sleep, Nap 1, Nap 2 detayları. Yanlarında yıldızlı skor/emoji.  
- **Düzenle Butonu**: Ekranın alt kısmında sabit, `AccentColor` dolgulu.

---

## 4.4 Analytics (Analizler)

### 4.4.1 Üst Başlık / Zaman Seçici

- “Analizler” (H1).  
- Segment kontrol: “7 Gün / 30 Gün / 90 Gün” (veya Picker).  

### 4.4.2 Trend Grafik

- **Çizgi Grafik**: Mavi (`PrimaryColor`) toplam uyku süresi, yeşil (`SecondaryColor`) Sleep Score (0-5).  
- Dokununca tooltip: `CardBackground` üzerinde değer gösterilir.

### 4.4.3 Kazanılan Zaman Kartı

- Arka plan: `SecondaryColor` ile %10 opacity, 12px radius.  
- Metin: “412 saat kazandın! Bu hafta +14 saat” (🎉 emojisi eklenebilir).

### 4.4.4 Sleep Breakdown (Pasta Grafiği)

- Dilimler: `AccentColor`, `PrimaryColor`, `SecondaryColor`.  
- Altında yüzdelik ve ortalama süre bilgileri.

### 4.4.5 Paylaş Butonu

- Sağ üstte “Share” ikonu. Dokununca iOS Share Sheet açılır, haftalık/aylık rapor görseli oluşturulur.

---

## 4.5 Profil Sayfası

### 4.5.1 Streak Gösterimi

- “17 Günlük Streak!” (H1, AccentColor veya beyaz üstüne turuncu).  
- Ateş ikonu animasyonu (Lottie ile).  
- Altında “En yüksek streak: 23 gün” (Caption).

### 4.5.2 Rozet Koleksiyonu

- Grid (3 sütun), 60x60px rozet görselleri.  
- Kilitli rozetler yarı saydam.  
- Tıklayınca açılan modal: “Bu rozet için 10 gün aralıksız planı uygulamalısın.”

### 4.5.3 Emoji/Kişiselleştirme

- “Core Sleep Emojini Seç”: Tıklayınca bir GridPicker (5 sütun, 40x40px).  
- Seçim yapıldığında `AccentColor` ile çerçeve.

### 4.5.4 Diğer Bağlantılar

- “Ayarlar”: Gizlilik, bildirim vb.  
- “Premium’a Geç”: Gelecek sürümde aktif olacak abonelik sayfası.

---

# 5. Uyku Kayıt Mekanizması

## 5.1 Bildirimler

- **Plan Saati Geldiğinde**: “14:00 - Nap Zamanı! Hazır mısın?”  
- Bildirime uzun basınca hızlı aksiyonlar: “Başla”, “Ertele (10 dk)”, “İptal”.  
- Kayıt sonrası “Nasıl hissediyorsun?” 1-5 yıldız rating.

## 5.2 Manuel Kayıt

- History ekranından bir güne dokunup “Kayıt Ekle” veya “Düzenle”.  
- Başlangıç / bitiş saati, dinçlik seviyesi (yıldız/emoji).  
- Kaydet’le SwiftData’ya işlenir.

---

# 6. Ek Özellik Tavsiyeleri (Geleceğe Yönelik)

1. **Sosyal Karşılaştırma**: Arkadaşlarla streak yarışı, rozet paylaşımı.  
2. **Uyku Sesleri**: Beyaz gürültü oynatıcı (Premium).  
3. **AI Tavsiyeleri**: Uyku verimliliğini artırmaya yönelik kişiselleştirilmiş öneriler.  
4. **Acil Şekerleme (Nap) Modu**: Ana sayfada tek dokunuşla 20 dk’lık kronometre ve alarm.  
5. **Motivasyon Mesajları**: Günün belli saatlerinde mini ipuçları.

---

# 7. Monetizasyon Stratejisi (Sonraki Sürümlerde)

- **RevenueCat Entegrasyonu**: Aylık/Yıllık abonelik.  
- **Ücretsiz Deneme**: 7 gün.  
- **Premium Özellikler**: Sınırsız geçmiş kaydı, gelişmiş analitik, ek rozet tasarımları vb.

---

# 8. Güvenlik ve Gizlilik

- **Veri Şifreleme**: SwiftData şifrelemesi (`@Attribute(.encrypt)`).  
- **GDPR Uyumluluğu**: Kişisel veriler yalnızca cihazda saklanır veya kullanıcı iznine göre iCloud ile senkronize edilir.  
- **Gizlilik Ayarları**: Bildirim ve veri paylaşımı izinleri açıkça belirtilmeli.

---

# 9. Çıkış Planı

1. **MVP**: Temel uyku takibi, geçmiş kayıtları, basit analizler, rozet sistemi (v1.0).  
2. **1.1 Sürüm**: RevenueCat abonelik entegrasyonu, premium özelliklerin aktif edilmesi.  
3. **1.2 Sürüm**: Sosyal paylaşım, AI tavsiyeleri, ek kişiselleştirme modülleri.

---

## Sonuç

Bu doküman, **PolySleep** uygulamasının fonksiyonel gereksinimlerini (PRD) detaylandırmaktadır. MVP aşamasında kullanıcıların hızlıca uygulamaya adapte olmalarını sağlayacak **Onboarding**, **Ana Sayfa** (24 saatlik timeline), **History**, **Analytics** ve **Profil** ekranları tanımlanmıştır.

Gelecekteki sürümlerde premium abonelik, sosyal özellikler ve yapay zekâ destekli önerilerle uygulama daha geniş bir kullanıcı kitlesine hitap edecek; böylece polifazik uyku düzenleri konusunda kullanıcı dostu, işlevsel ve motive edici bir platform oluşturulmuş olacaktır.