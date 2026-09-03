# Vaultify — Garanti Takip Uygulaması (Flutter)

Bu klasör, verdiğiniz tasarımdan üretilmiş çalışan bir **Flutter/Dart**
proje kaynağıdır (`lib/` içeriği). Native Android/iOS "sarmalayıcı"
klasörleri (android/, ios/) bu ortamda internet erişimi ve Flutter SDK
olmadığı için otomatik oluşturulamadı — aşağıdaki 3 adımla siz
bilgisayarınızda saniyeler içinde oluşturabilirsiniz.

## 1) Kurulum (bilgisayarınızda)

```bash
# 1. Bu klasörü Flutter projesi olarak iskeletlendirin (android/ios/ oluşur)
cd vaultify
flutter create . --org com.sizinsirketiniz --project-name vaultify

# 2. "flutter create" bu README, pubspec.yaml ve lib/ klasörünü SİLMEZ,
#    ama üzerine yazmaması için önce lib/ ve pubspec.yaml'ı yedekleyip
#    komuttan sonra geri koymanız daha güvenlidir. Sorun yaşarsanız:
#    lib/ ve pubspec.yaml dosyalarınızı komuttan önce başka bir yere
#    kopyalayın, komuttan sonra geri yapıştırın.

# 3. Paketleri indirin
flutter pub get

# 4. Çalıştırın
flutter run
```

## 2) Android izinleri (android/app/src/main/AndroidManifest.xml)

`<manifest>` etiketinin içine, `<application>` etiketinden ÖNCE ekleyin:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

`android/app/build.gradle` içinde `minSdkVersion`'ı en az **23** yapın
(biyometrik kilit ve bildirimler için gereklidir):

```
minSdkVersion 23
```

## 3) iOS izinleri (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Garanti belgesi fotoğrafı çekmek için kameraya ihtiyaç var.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Galeriden fatura/garanti belgesi seçmek için gerekli.</string>
<key>NSFaceIDUsageDescription</key>
<string>Uygulamayı biyometrik kilitle korumak için gerekli.</string>
```

---

## Sizin isteğiniz üzerine yapılan değişiklikler

1. **Yiyecek / SKT (son kullanma tarihi) takibi tamamen kaldırıldı.**
   Orijinal tasarımdaki "Dolap", "Mutfak", "İlaçlar" sekmeleri ve gıda
   kartları (Süt, Ağrı Kesici vb.) uygulamadan çıkarıldı. Uygulama artık
   yalnızca **değişim/garanti hakkı olan dayanıklı ürünleri** (elektronik,
   beyaz eşya, mobilya, sağlık cihazı, diğer) takip ediyor. Alt menü artık
   3 sekmeden oluşuyor: **Ana Sayfa, Garantiler, Ayarlar**.

2. **Karanlık modda header (üst bar) artık her yerde koyu.**
   `lib/widgets/glass_app_bar.dart` içindeki `GlassAppBar`, temanın
   `Brightness` değerine göre arka plan rengini ve blur efektini birlikte
   değiştiriyor. Önceki tasarımda header hep açık renk kalıyordu; bu
   sürümde koyu modda `#0B0F19` tonunda, saydam/buzlu camla render
   ediliyor.

3. **Ayarlar:** Yazı boyutu (Küçük/Orta/Büyük — kaydırmalı slider),
   Koyu/Aydınlık mod (kaydırmalı buton grubu), bildirim tercihleri
   (kaydırmalı switch'ler: 1 ay önce, son hafta, her sabah 09:00 özeti)
   hepsi kalıcı olarak cihazda saklanıyor ve anında uygulanıyor.

4. **Fatura/garanti belgesi yükleme + otomatik bilgi çıkarma:**
   "Yeni Ürün" ekranında kamera/galeri/dosyalardan fatura yüklenebiliyor.
   Görsel (jpg/png) yüklendiğinde cihaz üzerinde çalışan OCR
   (`google_mlkit_text_recognition`, sunucu gerektirmez) metni okuyor;
   basit bir ayrıştırıcı satıcı adı, fatura no, tarih ve toplam tutarı
   tahmin edip formu **otomatik dolduruyor** — kullanıcı kaydetmeden önce
   kontrol edip düzeltebiliyor (hiçbir şey sessizce/otomatik kaydedilmiyor).
   **Sınır:** PDF olarak yüklenen belgeler bu sürümde OCR ile taranmıyor;
   kullanıcı bilgileri PDF için elle giriyor (PDF sayfa-render + OCR,
   ekstra bir kütüphane/karmaşıklık gerektirdiği için bu sürüme
   eklenmedi — isterseniz ayrı bir adım olarak ekleyebiliriz).

5. **Trendyol/Hepsiburada'dan "paylaş menüsüyle" doğrudan aktarma**
   (işletim sistemi seviyesinde share-intent alma) bu sürüme eklenmedi;
   bunun yerine kullanıcı faturayı kendi galerisine/dosyalarına kaydedip
   uygulama içinden yükleyebiliyor. Gerçek "paylaş ile aktar" özelliği
   ek native yapılandırma gerektirdiği için sormadan eklemedim — isterseniz
   ayrı bir istek olarak ekleyebilirim.

## Bilerek eklemediğim / basitleştirdiğim noktalar (onayınıza açık)

- **Hesap girişi / "Çıkış Yap":** Tasarımda profil ve e-posta vardı ama
  gerçek bir kullanıcı hesabı sistemi (backend/kimlik doğrulama)
  istenmemişti. Bu sürümde profil adı/e-postası sadece yerel bir tercih
  olarak düzenlenebiliyor; "Çıkış Yap" düğmesi bunun bir hesap
  senkronizasyonu olmadığını belirten bir bilgi mesajı gösteriyor.
- **"Bulut Yedekleme" anahtarı:** Arayüzde duruyor ve tercihi
  kaydediyor, ama gerçek bulut senkronizasyonu (örn. Firebase) bir
  backend kurulumu gerektirdiği için bu sürümde pasif.
- Bunların ikisi de sizden onay almadan büyük bir "yeni özellik" (gerçek
  kullanıcı hesabı sistemi) eklemiş olmamak için bilinçli olarak
  sınırlı tutuldu.

## Play Store'a hazırlarken dikkat edilecekler

- Bir **Gizlilik Politikası** metni/sayfası hazırlayıp Play Console'da
  belirtmeniz gerekiyor (kamera, bildirim, biyometrik izinler kullanıldığı
  için zorunlu).
- Uygulama simgesi (`android/app/src/main/res/mipmap-*` ve
  `ios/Runner/Assets.xcassets`) ve açılış ekranı (splash) eklenmeli;
  bu proje şimdilik varsayılan Flutter simgesini kullanıyor.
- `android/app/build.gradle` içinde `applicationId`'yi kendi paket
  adınızla değiştirin (örn. `com.sizinsirketiniz.vaultify`).
- Sürüm imzalama (keystore) ve `flutter build appbundle --release` ile
  `.aab` üretimi standart Flutter yayın adımlarıdır.

## Proje yapısı

```
lib/
  main.dart                 # Giriş noktası
  app.dart                  # Tema + font ölçeği + biyometrik kilit sarmalayıcı
  theme/app_theme.dart      # Renkler, açık/koyu tema (header düzeltmesi burada)
  models/                   # WarrantyProduct, AppSettings
  services/                 # Depolama, bildirim, OCR servisleri
  providers/                # State yönetimi (Provider)
  screens/
    root_shell.dart         # Alt menü (3 sekme)
    home/                   # Ana sayfa
    warranties/             # Tüm garantiler listesi
    product/                # Detay + ekle/düzenle (OCR burada)
    settings/                # Ayarlar, bildirim tercihleri, güvenlik
  widgets/                  # Ortak arayüz bileşenleri (kart, glass app bar, vb.)
```
