# PolySleep - Yapılacaklar Listesi

Bu doküman, PolySleep uygulamasının MVP sürümü için gerekli olan tüm görevleri ve tamamlanan işleri içermektedir. PRD dokümanına dayanarak hazırlanmıştır.

## Yapılacak

### 4. History (Geçmiş) Ekranı
- [ ] Takvim görünümü
  - [ ] Aylık takvim grid yapısı
  - [ ] Durum ikonları (yeşil, sarı, kırmızı)
- [ ] Detay modal / ekranı
  - [ ] Seçilen günün uyku blokları detayı
  - [ ] Düzenleme butonu ve fonksiyonalitesi
- [ ] Manuel kayıt ekleme mekanizması

### 5. Analytics (Analizler) Ekranı
- [ ] Zaman seçici (7/30/90 gün)
- [ ] Trend grafiği
  - [ ] Toplam uyku süresi çizgi grafiği
  - [ ] Sleep Score çizgi grafiği
- [ ] Kazanılan zaman kartı
- [ ] Sleep Breakdown (pasta grafiği)
  - [ ] Core Sleep / Nap dağılımı
- [ ] Paylaş butonu ve fonksiyonalitesi

### 6. Profil Sayfası
- [ ] Streak gösterimi
  - [ ] Güncel streak sayacı
  - [ ] En yüksek streak bilgisi
- [ ] Rozet koleksiyonu
  - [ ] Rozet grid görünümü
  - [ ] Kilitli/açık rozet gösterimi
  - [ ] Rozet detay modalı
- [ ] Emoji/kişiselleştirme bölümü
  - [ ] Core Sleep emoji seçimi
  - [ ] Nap emoji seçimi
- [ ] Diğer bağlantılar (Ayarlar vb.)

### 7. Uyku Kayıt Mekanizması
- [ ] Bildirim sistemi
  - [ ] Planlanan saatlerde bildirim gönderme
  - [ ] Bildirim aksiyonları (Başla, Ertele, İptal)
  - [ ] Kayıt sonrası değerlendirme (1-5 yıldız)
- [ ] Manuel kayıt düzenleme
  - [ ] Başlangıç/bitiş saati düzenleme
  - [ ] Dinçlik seviyesi değerlendirme

### 8. Navigasyon ve Genel UI
- [ ] Tab bar navigasyon yapısı
  - [ ] Ana Sayfa tab'i
  - [ ] History tab'i
  - [ ] Analytics tab'i
  - [ ] Profil tab'i
- [ ] Erişilebilirlik özellikleri
  - [ ] Dinamik tipografi desteği
  - [ ] VoiceOver etiketleri
  - [ ] Renk körlüğü desteği

### 9. Testler ve Optimizasyon
- [ ] Temel unit testleri
- [ ] UI testleri
- [ ] Performans optimizasyonu
- [ ] Bellek yönetimi kontrolü

## Yapıldı

### 1. Proje Kurulumu ve Mimari
- [ ] Yeni Xcode projesi oluşturma (SwiftUI, iOS 17.0+)
- [ ] MVVM mimarisi için klasör yapısını hazırlama
  - [ ] Models
  - [ ] Views
  - [ ] ViewModels
  - [ ] Services
  - [ ] Extensions
  - [ ] Resources
- [ ] Temel renk paletini ve tipografiyi Assets.xcassets'e ekleme
- [ ] Localizable.xcstrings dosyasını hazırlama (TR/EN)

### 2. Onboarding Akışı
- [ ] Onboarding ana yapısını oluşturma
  - [ ] Adım adım ilerleyen akış mekanizması
  - [ ] İlerleme çubuğu (Progress Bar)
- [ ] Onboarding soruları ve UI bileşenlerini hazırlama
  - [ ] Önceki uyku deneyimi sorusu
  - [ ] Yaş aralığı sorusu
  - [ ] İş/Çalışma programı sorusu
  - [ ] Diğer sorular (toplamda 11 adım)
- [ ] Sonuç ekranı (önerilen uyku programı)
  - [ ] Kabul et / Düzenle butonları
  - [ ] Özet kartı tasarımı

  ### 3. Ana Sayfa (Uyku Programı Ekranı)
- [ ] 24 saatlik timeline görünümü
  - [ ] Dairesel saat gösterimi
  - [ ] Uyku bloklarının görselleştirilmesi
- [ ] Düzenleme modu
  - [ ] Kaydet / Vazgeç butonları
- [ ] Bilgi panosu
  - [ ] Toplam uyku süresi gösterimi
  - [ ] Sonraki uyku bloğu bilgisi
  - [ ] Kalan süre gösterimi
- [ ] Ek mini bölüm (ipuçları / öneriler)



---

## Öncelik Sıralaması (MVP için)

1. Proje kurulumu ve temel mimari
2. Ana Sayfa (24 saatlik timeline)
3. Onboarding akışı
4. Uyku kayıt mekanizması
5. History ekranı
6. Analytics ekranı
7. Profil sayfası
8. Bildirim sistemi
9. Testler ve optimizasyon

## Notlar

- MVP, premium özellikler olmadan temel işlevselliği sağlamalıdır
- Kullanıcı deneyimi akıcı ve sezgisel olmalıdır
- Tüm ekranlar ve bileşenler Apple Human Interface Guidelines'a uygun olmalıdır
- Renk paleti ve tipografi tutarlı bir şekilde uygulanmalıdır
- Erişilebilirlik özellikleri baştan düşünülmelidir
