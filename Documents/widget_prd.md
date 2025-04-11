Aşağıda, mevcut dokümanı **Widget** (iOS 17’deki yeni **interaktif widget** imkânları dahil), **Alarm** ve **Bildirim** özelliklerini de kapsayacak şekilde genişletiyoruz. Bu eklemelerle birlikte, PolySleep uygulaması iOS ekosistemiyle daha derin bir entegrasyon sağlayacak ve kullanıcılar polifazik uyku planlarını çok daha kolay takip edebilecekler.

---

# 1. Widget Özellikleri

**Hedef**: Kullanıcıların uygulamaya girmeden de temel bilgilere erişebilmesi, uyku bloklarını veya “Nap” butonunu hızlıca kullanabilmesi.

## 1.1 Widget Türleri ve Boyutları

1. **Küçük (Small) Widget**  
   - **Gösterilen Bilgiler**:  
     - Güncel Saat + Bir Sonraki Uyku Bloğuna Kalan Süre (örn. “Sonraki: 14:00, Kalan: 1s 20d”)  
     - Mevcut Streak Sayısı (“Streak: 17 Gün”) - İsteğe Bağlı  
   - **Etkileşim**: Kullanıcı widget’a dokununca uygulamanın **Ana Sayfa** veya **Güncel Uyku Durumu** ekranına yönlendirilir (kısa yol).  

2. **Orta (Medium) Widget**  
   - **Gösterilen Bilgiler**:  
     - Günün 24 saatlik ufak timeline’ı (basitleştirilmiş).  
     - **Geri sayım** (kalan süre), “Bugün hedefin 4.5 saat” gibi kısa bir metin.  
   - **Etkileşim**:  
     - iOS 17 ile gelen **interaktif widget** desteği varsa, widget üzerinden “Alarm Kur” veya “Nap Başlat” butonuna tıklanabilir.  
     - Aksi halde, widget dokunulunca uygulamanın ilgili ekranına yönlendirme yapar.

3. **Büyük (Large) Widget**  
   - **Gösterilen Bilgiler**:  
     - Daha detaylı timeline.  
     - Geçmişten kısa bir özet (dünkü Sleep Score gibi).  
     - Streak/rozet görseli.  
   - **Etkileşim**: 1-2 buton konumlandırılabilir (örn. “Hemen Nap Başlat” veya “Analytics’e Git”).  

## 1.2 Widget İçerik Örnekleri

- **Küçük Widget Metni**:  
  - Üst satır: “Sonraki Blok”  
  - Alt satır: “14:00 → 1s 20d kaldı”  

- **Orta Widget Metni**:  
  - Üst satır: “Bugün Planlanan Uyku: 4.5 saat”  
  - Alt satır (güncel durum): “Core Sleep bitti, Nap1: 14:00”  
  - Basit bir ilerleme çubuğu ile şu ana kadar harcanan uyku süresi gösterilebilir.

**Teknoloji**:  
- SwiftUI WidgetKit. iOS 17 ile **interaktif** widget’lar destekleniyorsa “Nap Başlat” gibi anlık eylemler sunulabilir.

## 1.3 Widget Güncelleme Sıklığı

- iOS widget’lar çoğunlukla sistem tarafından planlanan zamanlarda güncellenir.  
- **Zaman Kritik Bilgiler** (kalan süre vb.): Apple’ın kısıtları nedeniyle anlık olarak yenilenemeyebilir, ancak “RelativeDateTimeFormatter” gibi yaklaşımlarla zaman yakınlığı gösterilebilir.  

---

# 2. Alarm & Bildirim Özellikleri

PolySleep, kullanıcıya planlanan uyku blokları ve kritik hatırlatma noktalarında alarm/bildirim gönderecektir. Burada **iOS 17**’deki `UserNotifications` framework ve potansiyel **Background Tasks** kullanımından söz edilmektedir.

## 2.1 Alarm Kurma Mantığı

- **Her Blok İçin Otomatik Alarm**: Kullanıcı timeline’ında örneğin 14:00’te bir Nap planlıyorsa, uygulama bu süreye uygun yerel bildirim ayarlar.  
- **Erteleme (Snooze) Seçeneği**: Kullanıcı bildirimde “Ertele” seçerse 10 dk sonraya yeni bir yerel bildirim planlanır.  

### 2.1.1 Alarm Ekranı (Uygulama İçinde)

- **Alarm Ayarları** (Ayarlar/Profil menüsünden ulaşılabilir):  
  - “Her uyku bloğu için otomatik alarm kur” (Toggle)  
  - “Ses Seç” veya “Titreşim” (örn. avfoundation ile basit alarm sesi)  
  - “Ertele (default: 10 dk)”  

- **Sistem Bildirim İzni**: İlk yüklemede kullanıcıdan bildirim izni istenir. İzin verilmezse alarm özelliği kısıtlı çalışır (kullanıcının onayı olmazsa bildirim çıkmaz).

## 2.2 Bildirim İçeriği

### 2.2.1 Uyku Başlangıç Hatırlatması

- **Metin**: “Nap Zamanı! (14:00) Hazır mısın?”  
- **Aksiyon Butonları**:  
  - **“Başla”**: Uygulama içinde timer veya kayda geçiş yapar.  
  - **“Ertele (10dk)”**: Yeni yerel bildirim 10 dk sonraya ayarlanır.  
  - **“İptal”**: Bu bloğu iptal eder (kullanıcı History’de “uyku kaçırıldı” olarak işaretleyebilir).

### 2.2.2 Uyku Bitişi / Uyanma Alarmı

- **Metin**: “Nap Bitti! Uyanma Vakti”  
- **Aksiyon Butonları**:  
  - **“Uyandım”**: Uygulama kaydı otomatik kapatır ve bir “Nasıl hissettin?” popup’ı gösterebilir.  
  - **“Ertele (5dk)”**: 5 dk daha ekler.  

### 2.2.3 Günlük Hatırlatma

- İsteğe bağlı: “Bugün planladığın toplam uyku 4.5 saat. Takipte kal!” gibi sabah bildirimleri.  

## 2.3 Bildirim Zamanlaması & İçerik Kuralları

| Bildirim Türü               | Zaman / Koşul                           | Metin Örneği                                                |
|-----------------------------|------------------------------------------|--------------------------------------------------------------|
| **Uyku Başlangıcı**         | Planlı blok saatinden 5 dk önce         | “Saat 14:00 Nap Zamanı! Hazır mısın?”                        |
| **Uyku Bitişi**             | Blok süresi dolduğunda                  | “Nap Bitti! Keyifli bir mola oldu mu?”                       |
| **Günlük Hatırlatma**       | Sabah 08:00 (kullanıcı ayarlayabilir)   | “Bugün planladığın uyku: 4.5 saat. Hadi harekete geç!”        |
| **Ertele Bildirimi**        | Kullanıcı “Ertele” seçtiğinde +10 dk     | “Nap Zamanı (Ertele Sonrası)! Artık başlamak ister misin?”    |

**Not**: Tüm metinlerde samimi bir üslup kullanılabilir, ancak çok sık veya gereksiz bildirim gönderilmesi kullanıcı deneyimini olumsuz etkileyebilir. Kullanıcıya bildirim sıklığı ayarı sunmak önemlidir.

---

# 3. Entegrasyon ve Çıkış Planı (Widget, Alarm & Bildirim)

Aşağıda, widget, alarm ve bildirimlerin hangi sürümde veya aşamada devreye alınabileceğine dair öneri bulunmaktadır.

1. **MVP (v1.0)**  
   - **Temel Bildirimler**: Uyku Başlangıcı ve Bitişi için yerel bildirim. Ertele (Snooze) seçeneği.  
   - **Alarm Ekranı / Ayarlar**: Basit alarm ayarları, ses seçimi.  
   - **Basit Widget (Small veya Medium)**: Sadece istatistik gösteren veya “Sonraki Uyku”yu belirten, dokununca uygulamaya yönlendiren pasif widget.

2. **v1.1**  
   - **Gelişmiş Widget**: iOS 17 interaktif widget desteğiyle “Nap Başlat” butonu eklenebilir.  
   - **Günlük Hatırlatma Bildirimi**: Kullanıcı “her sabah saat X’te planımı hatırlat” şeklinde ayarlayabilir.  

3. **v1.2 ve Sonrası**  
   - **Özel Alarm Sesleri**: Premium kullanıcılar farklı alarm ses paketleri kullanabilir.  
   - **Kişiselleştirilmiş Bildirim Metinleri**: Yapay zekâ tavsiyeleriyle “Son rapora göre Nap süreni 5 dk uzatmalısın” gibi.  
   - **Lock Screen / Live Activity** (Örneğin “Nap sürüyor: 15 dk kaldı”).  

---

# 4. Kullanım Senaryosu Örneği

1. **Kullanıcı, 14:00’te bir Nap planladı**.  
2. **14:00’den 5 dk önce** (13:55) yerel bildirim: “Yaklaşan Nap: Başlamak ister misin?”  
   - **“Başla”**’ya tıklarsa uygulama açılır veya doğrudan sayıyor (interaktif widget varsa widget üzerinden de başlayabilir).  
   - **“Ertele (10 dk)”** derse 14:05’e yeni bildirim planlanır.  
3. **14:00 veya 14:05’te** (erteleme yoksa) alarm devreye girer, Nap başlar.  
4. **Uyku süresi bittiğinde** (örneğin 20 dk sonra, 14:20’de) “Nap Bitti! Nasıl hissediyorsun?” bildirimi.  
5. Kullanıcı “Uyandım” diyerek History kaydı otomatik oluşturur; “Dinçlik Seviye”sini puanlar.  

Bu döngü kullanıcıyı sürekli uygulamaya girmeye mecbur kılmadan, planını verimli şekilde takip etmesine yardımcı olur.

---

# 5. Teknik Detaylar & Öneriler

1. **UserNotifications Framework**  
   - **UNUserNotificationCenter**’ı kullanarak yerel bildirimleri planlamak.  
   - **UNNotificationAction**, **UNNotificationCategory** ile “Başla”, “Ertele” gibi aksiyon butonları eklemek.  
   - iOS 15+ (veya iOS 17) uyumluluğu.  

2. **Alarm Sesi & AVFoundation**  
   - Yerel alarm sesi oynatmak için **AVAudioPlayer** veya **SystemSoundID** kullanılabilir.  
   - Uygulama arka planda ise sistem kısıtları nedeniyle bildirim sesiyle sınırlı kalınabilir.

3. **WidgetKit**  
   - SwiftUI tabanlı widget’lar.  
   - **TimelineProvider** yapısıyla periyodik veya “relative date” formatında güncelleme.  
   - iOS 17’nin interaktif widget özelliği: `WidgetURL` veya “app intents” ile aksiyon.  

4. **Performans & Akü Tüketimi**  
   - Çok sık bildirim ve güncelleme planlamaktan kaçınılmalı (Apple kısıtlarını göz önünde bulundurun).  

5. **Kullanıcı Kontrolü**  
   - **Ayarlar Ekranı**: Kullanıcı bildirim sıklığını, ertele süresini, alarm sesini değiştirebilmeli.  
   - Düşük rahatsız etme politikasıyla, kullanıcıya “Rahatsız Etme saatleri” tanımlama opsiyonu vermek de yararlı olabilir (örn. gece 23:00 - 07:00 arası sadece kritik bildirimler).  

---

# 6. Özet

Bu genişletilmiş dokümanda, **PolySleep** uygulamasının **widget, alarm ve bildirim** özellikleri detaylandırılmıştır. Temel amaç, kullanıcının polifazik uyku takibini daha pratik ve etkili hâle getirmektir:

- **Widget’lar**: Ana ekranda veya kilit ekranında hızlı bilgi ve (iOS 17 interaktif imkânlarla) eylem.  
- **Alarm**: Planlı uyku blokları için otomatik veya manuel kurulum, erteleme fonksiyonu.  
- **Bildirim**: Uyku başlangıcı, bitiş, günlük özet ve diğer hatırlatmalarla kullanıcıyı doğru zamanda yönlendirme.  

Bu özellikler, uygulamanın çekirdeğini oluşturan **uyku planlama** ve **takip** deneyimini tamamlar. Kullanıcı, uygulamaya her an girmek zorunda kalmadan planını sürdürebilir, böylelikle polifazik uyku düzenine daha rahat uyum sağlayabilir. 

Gelecekte, premium kullanıcılar için özel alarm ses paketleri, kişiselleştirilmiş akıllı bildirimler ve “Live Activity” (iOS 16+) veya “Widget Interactivity” (iOS 17) gibi güncel iOS özellikleriyle entegrasyon daha da geliştirilebilir. Bu sayede PolySleep, polifazik uyku yönetiminde kapsamlı ve kullanıcı dostu bir uygulama haline gelecektir.