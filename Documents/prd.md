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

Aşağıda, **Analytics (Analizler)** sayfasının hem fonksiyonel hem de görsel tasarım detaylarını bulabilirsiniz. Bu tasarım önerisi; **Apple Human Interface Guidelines** (HIG), **SwiftUI** prensipleri ve uygulamanızın genel stil rehberini (renk, tipografi, köşe yuvarlaklıkları, vb.) referans alarak hazırlanmıştır.

---

### 4.1. Genel Amaç ve Bilgi Mimarisi

**Analytics (Analizler)** sayfası, kullanıcının polifazik uyku düzeniyle ilgili **uzun vadeli verileri** inceleyebileceği, performansını kıyaslayabileceği ve **derinlemesine analiz** yapabileceği bir ekrandır.  
Bu ekranda kullanıcı;  
1. Belirli bir zaman aralığındaki **toplam uyku süresi**, **ortalama dinçlik skoru** ve **uyku blokları dağılımı** gibi metrikleri görebilir.  
2. Gün veya hafta bazında trend grafikleri (line chart, bar chart vb.) inceleyebilir.  
3. **“Kazanılan zaman”**, **uyku verimliliği**, **sleep score** gibi ek özet metrikleri bulabilir.  
4. Gerekirse raporlarını paylaşabilir veya ekran görüntüsünü alabilir.

---

### 4.2. Sayfa Düzeni (Layout)

Analytics sayfası, tab bar veya benzeri bir navigasyon yapısı üzerinden erişildiğinde **tam ekran** açılır. Yukarıdan aşağıya doğru şu bölümler sıralanır:

1. **Üst Başlık ve Zaman Seçici**  
2. **Özet Kart(lar)**  
3. **Trend Grafikleri**  
4. **Sleep Breakdown (Pasta veya Bar Grafiği)**  
5. **Kazanılan Zaman / Ek Metrikler**  
6. **Paylaş Butonu**  

Aşağıda her bölümün detaylarını bulabilirsiniz.

---

### 4.3. Bölüm Bazlı Detaylar

#### 4.3.1 Üst Başlık ve Zaman Seçici

- **Başlık (Title)**:  
  - Metin: “Analizler” (H1, 28pt, `SF Pro Rounded Bold` veya benzeri).  
  - Renk: `TextColor` (Light modda koyu, Dark modda açık).  
  - Konum: Sayfanın en üstünde, sol kenara yaslı. Sağ üstte opsiyonel “Share” ikonu yer alabilir.

- **Zaman Aralığı Seçici (Segmented Control veya Picker)**:  
  - Kullanıcı, “7 Gün”, “30 Gün”, “90 Gün” veya “Özel Tarih Aralığı” gibi seçenekler arasında geçiş yapabilir.  
  - SwiftUI `SegmentedControl` veya iOS 17 için `Picker` (menu style) kullanılabilir.  
  - Seçim değiştikçe, alttaki grafik ve metrikler **animasyonlu** olarak güncellenir (0.3s fade veya slide transition).  
  - UI/UX Notu:  
    - **SegmentedControl**: Ekranın üst kısmında, başlığın hemen altında.  
    - Seçili segmentin arka planı `AccentColor` veya `PrimaryColor` olabilir.  
    - Dynamic Type desteği: Metinler büyüdüğünde bile butonların taşmaması için yeterli genişlik sağlanır.

#### 4.3.2 Özet Kart(lar)

- **Amaç**: Kullanıcıya seçilen zaman aralığı için hızlı bir bakış sağlamak.  
- **İçerik**:  
  1. **Toplam Uyku Süresi** (Örn. “Bu dönemde toplam 32 saat uyudun”)  
  2. **Günlük Ortalama** (Örn. “Günlük ortalama 4.6 saat”)  
  3. **Ortalama Sleep Score** (Örn. “3.8 / 5”)  
- **Tasarım**:  
  - Kart arka planı: `CardBackground` (Light modda beyaz, Dark modda koyu gri).  
  - Köşe yuvarlaklığı: 12px veya 20px.  
  - Hafif gölge: `0px 2px 8px rgba(0,0,0,0.1)`  
  - İçeride veriler, **2 veya 3 sütun** halinde (örneğin satırda 2-3 metrik).  
  - Önemli rakamlar `PrimaryColor` veya `AccentColor` ile vurgulanabilir.  
- **Etkileşim**: Kartın kendisi genelde tıklanmaz, sadece bilgi amaçlı. İstenirse “Daha fazla bilgi” butonu eklenebilir.

#### 4.3.3 Trend Grafikleri (Line Chart / Bar Chart)

- **Amaç**: Kullanıcının seçilen zaman diliminde uyku trendini görmesini sağlamak. Örneğin:  
  - Toplam Uyku Süresi (günlük veya haftalık bazda)  
  - Sleep Score (0–5 arası veya 1–5 yıldız)  
- **UI Önerisi**:  
  1. **Çizgi Grafiği (Line Chart)**  
     - X Ekseni: Tarih veya gün numarası (örn. 1-7, 1-30).  
     - Y Ekseni: Süre (saat) veya skor (0–5).  
     - Renk: `PrimaryColor` (mavi) veya `SecondaryColor` (yeşil) çizgi.  
     - Noktalar (Data Points): Hafif bir nokta veya dairesel işaretçi.  
     - **Tooltip**: Kullanıcı bir veri noktasına dokunduğunda, ufak bir `CardBackground` baloncuğu açılır ve “Tarih: 24 Şub, Uyku: 5.2 saat, Skor: 4/5” gibi bilgi gösterir.  
  2. **Bar Chart** (Alternatif veya ek olarak)  
     - Özellikle “Günlük Core Sleep / Nap Süresi” karşılaştırması için uygun.  
     - Her sütun 24 saatteki toplam uyku bloklarını temsil eder, farklı renkte segmentler (Core Sleep, Nap 1, Nap 2) üst üste gelebilir.  
- **Etkileşim ve Animasyon**:  
  - Grafikler ilk yüklendiğinde hafif bir **draw** animasyonu ile çizilebilir.  
  - Segment değiştirdiğinde (7 Gün / 30 Gün / 90 Gün) veri **fade** veya **slide** animasyonu ile güncellenir.  
  - **Haptic feedback**: Kullanıcı grafik üzerinde gezindiğinde hafif titreşim hissedebilir (opsiyonel).

#### 4.3.4 Sleep Breakdown (Pasta Grafiği veya Yüzdesel Dağılım)

- **Amaç**: Kullanıcının Core Sleep ve Nap’lerin (örneğin Nap 1, Nap 2, Nap 3) toplam süre içindeki dağılımını görmesi.  
- **UI Detayları**:  
  - **Pasta Grafiği**:  
    - Her dilim farklı renk (Core Sleep için `AccentColor`, Nap 1 için `PrimaryColor`, Nap 2 için `SecondaryColor` vb.).  
    - Ortada toplam uyku saati (örneğin “4.5h avg / day”).  
    - Yanında bir legend (açıklama) olabilir:  
      - Renk kutusu + “Core Sleep %60 (2.7 saat)”  
      - Renk kutusu + “Nap 1 %25 (1.1 saat)”  
      - Renk kutusu + “Nap 2 %15 (0.7 saat)”  
  - **Alternatif**: Bar veya stacked bar chart (her günün core/nap oranlarını görebilmek).  
- **Etkileşim**: Dokunulduğunda dilim üzerinde yine bir tooltip veya mini kart açılabilir.  
- **Stil**: 12px köşe yuvarlaklığı, net ve kontrast renkler. Apple HIG’e göre metin ve arka plan arasındaki kontrast en az 4.5:1 olmalı.

#### 4.3.5 Kazanılan Zaman / Ek Metrikler

- **Kazanılan Zaman**:  
  - Kullanıcı polifazik uykuya geçtiğinde, geleneksel uyku (örneğin 8 saat) ile karşılaştırıldığında “teoride” kazandığı süre.  
  - Örneğin: “Bu hafta +14 saat kazandın!” gibi.  
  - Kart şeklinde sunulabilir:  
    - Arka plan: `SecondaryColor` %10 opaklık.  
    - Metin: “Toplam 54 saat kazanım” gibi.  
  - Yanında küçük bir kutlama ikonu (🎉) veya rozet olabilir.  
- **Ek Metrikler** (opsiyonel):  
  - “Uyanma sayısı” (gece bölünmeleri).  
  - “Dinç uyanma yüzdesi” (kullanıcının giriş yaptığı hissiyat skoruna göre).  
  - “En sık kullanılan erteleme süresi” gibi ilginç istatistikler.

#### 4.3.6 Paylaş Butonu

- **Konum**: Sayfanın sağ üstünde (Title bar seviyesinde) veya en altta sabit bir buton olarak konumlanabilir.  
- **İkon**: iOS’un varsayılan “Share” ikonu (square and arrow).  
- **İşlev**: Dokununca iOS Share Sheet açılır. Kullanıcı;  
  - Ekran görüntüsü,  
  - PDF veya resim formatında rapor,  
  - Metin bazlı özet  
  paylaşabilir.  
- **UI/UX Notu**:  
  - Butona basıldığında hafif scale-down animasyonu + haptic feedback.  
  - Paylaş sayfasında “Bu haftaki polifazik uyku istatistiklerim” gibi otomatik bir başlık oluşturulabilir.

---

### 4.4. Stil, Tipografi ve Renk Kullanımı

1. **Renkler**:  
   - **PrimaryColor** (Mavi) ve **AccentColor** (Turuncu) en kritik vurgular için.  
   - **SecondaryColor** (Yeşil) başarı ve pozitif durumlar (örneğin Sleep Score yüksekse).  
   - **CardBackground** ve **BackgroundColor** arasındaki kontrast, grafikler için arka plan oluştururken önemli.  
2. **Tipografi**:  
   - Başlıklar: `SF Pro Rounded Bold`, 28pt (H1)  
   - Alt Başlıklar: `SF Pro Rounded Semibold`, 22pt (H2)  
   - Gövde Metin: `SF Pro Text Regular`, 16pt  
   - İstatistikler / Rakamsal Vurgular: Bold veya Semibold, 16–20pt arası.  
3. **Köşe Yuvarlaklığı (Corner Radius)**:  
   - Kartlar: 12px veya 20px (uygulamanın genel stiline bağlı).  
   - Grafikleri içeren container’lar: 12px.  
4. **Gölgeler**: Hafif veya orta yoğunlukta (örneğin `0px 2px 8px rgba(0,0,0,0.1)`).  
5. **Animasyonlar**:  
   - Geçiş (transition) süresi 0.3s, Ease-In-Out.  
   - Tooltip veya popover’larda hafif fade-in animasyonu (0.2s).  
6. **Erişilebilirlik**:  
   - Dynamic Type’a uygun olacak şekilde metin boyutları otomatik büyümeli/küçülmeli.  
   - VoiceOver için grafiklerde de metinsel açıklamalar sağlanmalı (örn. “Pasta grafiği: %60 Core Sleep, %25 Nap1, %15 Nap2”).

---

### 4.5. Kullanıcı Akışı (User Flow)

1. **Segment Seçimi**: Kullanıcı “7 Gün” seçtiğinde, tüm metrikler ve grafikler 7 günlük veriyi gösterir.  
2. **Özet Kartı**: Hızlıca toplam uyku, ortalama skor ve günlük ortalama bilgiyi okur.  
3. **Trend Grafiği**: Gün gün toplam uyku saatlerini veya skor trendini inceler. Üzerine dokunarak spesifik güne ait detayı görür.  
4. **Breakdown Grafiği**: Pasta grafiği üzerinden core sleep ve nap’lerin yüzdesel dağılımını anlar.  
5. **Kazanılan Zaman**: Geleneksel uyku ile kıyaslamada bu periyotta ne kadar “fazla zaman” kaldığını görür.  
6. **Paylaş**: Uygulamanın raporunu veya ekran görüntüsünü arkadaşlarıyla paylaşabilir.

---

### 4.6. Özet

Bu **Analytics** sayfası tasarımı, kullanıcıya **derinlemesine uyku analizi** sunacak ve polifazik uyku düzeninde **ilerlemeyi**, **kazanımları** ve **trendleri** rahatlıkla takip etmeyi amaçlar.  
- **Üst Başlık** ve **Zaman Seçici** ile kolay tarih aralığı değiştirme,  
- **Özet Kart(lar)** ile hızlı bakış,  
- **Trend Grafikleri** ve **Breakdown** grafikleriyle görsel analiz,  
- **Kazanılan Zaman** gibi motivasyonel metrikler,  
- **Paylaş** butonuyla sosyal veya kişisel raporlama,  
hepsi Apple HIG prensiplerine uyacak şekilde düzenlenmiştir.

Bu sayede kullanıcılar, **uyku kalitelerini** ve **verimliliklerini** daha iyi anlar, motivasyon kazanır ve uygulamanın değerini net biçimde görürler.




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

Öğrenme kısmında polifazik uyku hakkında bilgiler olacak ve ve bazı soruların cevapları olacak. 