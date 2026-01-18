import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LegalPageView extends StatelessWidget {
  final String title;
  final String slug;

  const LegalPageView({
    super.key,
    required this.title,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _loadContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF4220B),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'İçerik yüklenirken hata oluştu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Son güncelleme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  snapshot.data ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadContent() async {
    // Simüle edilmiş içerik yükleme
    await Future.delayed(const Duration(milliseconds: 500));

    switch (slug) {
      case 'kvkk':
        return _getKvkkContent();
      case 'kisisel-verilerin-saklama-ve-imha-etme-proseduru':
        return _getDataStorageContent();
      case 'cerez-politikasi':
        return _getCookiePolicyContent();
      case 'about-us':
        return _getAboutUsContent();
      case 'contact-us':
        return _getContactContent();
      case 'terms-condition':
        return _getTermsContent();
      case 'privacy-policy':
        return _getPrivacyPolicyContent();
      default:
        return 'İçerik bulunamadı.';
    }
  }

  String _getKvkkContent() {
    return '''
6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, kişisel verilerinizin işlenmesine ilişkin aydınlatma metnimiz aşağıdaki gibidir:

1. VERİ SORUMLUSU
Newsly olarak, kişisel verilerinizin işlenmesinden sorumlu veri sorumlusuyuz.

2. KİŞİSEL VERİLERİN İŞLENME AMAÇLARI
Kişisel verileriniz aşağıdaki amaçlarla işlenmektedir:
• Haber içeriklerinin kişiselleştirilmesi
• Kullanıcı deneyiminin iyileştirilmesi
• İstatistiksel analizler yapılması
• Yasal yükümlülüklerin yerine getirilmesi
• Güvenlik önlemlerinin alınması

3. İŞLENEN KİŞİSEL VERİLER
• Kimlik bilgileri (ad, soyad)
• İletişim bilgileri (e-posta adresi)
• Kullanıcı işlem bilgileri
• Konum bilgileri (izin verildiğinde)
• Cihaz bilgileri

4. KİŞİSEL VERİLERİN AKTARILMASI
Kişisel verileriniz, KVKK'nın 8. ve 9. maddelerinde belirtilen şartlar dahilinde:
• İş ortaklarımıza
• Hizmet sağlayıcılarımıza
• Yasal yükümlülükler çerçevesinde yetkili kamu kurum ve kuruluşlarına
aktarılabilir.

5. VERİ SAHİBİNİN HAKLARI
KVKK'nın 11. maddesi uyarınca, veri sahibi olarak:
• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşlenmişse buna ilişkin bilgi talep etme
• İşlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme
• Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme
• Eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme
• KVKK'nın 7. maddesinde öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme
• Düzeltme, silme ve yok edilme işlemlerinin kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme
• İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme
• Kanuna aykırı olarak işlenmesi sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme
haklarına sahipsiniz.

6. BAŞVURU YOLLARI
Yukarıda belirtilen haklarınızı kullanmak için destek@newsly.com adresine e-posta gönderebilirsiniz.
''';
  }

  String _getDataStorageContent() {
    return '''
KİŞİSEL VERİLERİN SAKLAMA VE İMHA PROSEDÜRÜ

1. AMAÇ
Bu prosedür, Newsly tarafından işlenen kişisel verilerin saklanması ve imha edilmesine ilişkin usul ve esasları belirlemek amacıyla hazırlanmıştır.

2. KAPSAM
Bu prosedür, Newsly tarafından işlenen tüm kişisel verileri kapsar.

3. SAKLAMA SÜRELERİ
Kişisel verileriniz, işlenme amaçları doğrultusunda gerekli olan süre boyunca saklanır:

3.1. Kullanıcı Hesap Bilgileri
• Hesap aktif olduğu sürece + 1 yıl
• Hesap kapatıldıktan sonra yasal saklama yükümlülüğü varsa ilgili süre

3.2. İşlem Kayıtları
• İşlem tarihinden itibaren 10 yıl (Vergi mevzuatı gereği)

3.3. İletişim Kayıtları
• İletişim tarihinden itibaren 3 yıl

3.4. Log Kayıtları
• Oluşturulma tarihinden itibaren 2 yıl

4. İMHA YÖNTEMLERİ
Kişisel verileriniz aşağıdaki yöntemlerle imha edilir:

4.1. Elektronik Ortamdaki Veriler
• Güvenli silme yazılımları kullanılarak geri getirilemeyecek şekilde silinir
• Veritabanlarından kalıcı olarak silinir
• Yedekleme sistemlerinden temizlenir

4.2. Fiziksel Ortamdaki Veriler
• Kağıt dokümanlar parçalanır veya yakılır
• Optik diskler fiziksel olarak tahrip edilir

5. PERİYODİK İMHA
• Her 6 ayda bir periyodik imha işlemi gerçekleştirilir
• İmha edilen veriler kayıt altına alınır
• İmha tutanakları düzenlenir

6. OLAĞANÜSTÜ İMHA
Aşağıdaki durumlarda olağanüstü imha gerçekleştirilir:
• Veri sahibinin silme talebi
• Verilerin hukuka aykırı işlendiğinin tespit edilmesi
• İşlenme amacının ortadan kalkması

7. İMHA SONRASI İŞLEMLER
• İmha işlemi tamamlandıktan sonra veri sahibine bildirim yapılır
• İmha kayıtları 3 yıl süreyle saklanır
• Üçüncü kişilere aktarılmış veriler için bildirim yapılır

8. SORUMLULUKLAR
• Veri sorumlusu: İmha süreçlerinin yönetimi
• Teknik ekip: İmha işlemlerinin gerçekleştirilmesi
• Hukuk birimi: Yasal uyumluluğun sağlanması
''';
  }

  String _getCookiePolicyContent() {
    return '''
ÇEREZ POLİTİKASI

1. ÇEREZ NEDİR?
Çerezler, ziyaret ettiğiniz internet siteleri tarafından tarayıcılar aracılığıyla cihazınıza veya ağ sunucusuna depolanan küçük metin dosyalarıdır.

2. ÇEREZ KULLANIM AMAÇLARIMIZ
Newsly olarak çerezleri aşağıdaki amaçlarla kullanıyoruz:
• Kullanıcı deneyimini iyileştirmek
• Uygulama performansını optimize etmek
• Kullanıcı tercihlerini hatırlamak
• Güvenlik önlemlerini sağlamak
• İstatistiksel analizler yapmak

3. KULLANDIĞIMIZ ÇEREZ TÜRLERİ

3.1. Zorunlu Çerezler
Uygulamanın temel işlevlerini yerine getirmesi için gerekli çerezlerdir. Bu çerezler olmadan uygulama düzgün çalışmaz.

3.2. Performans Çerezleri
Uygulamanın performansını ölçmek ve iyileştirmek için kullanılır. Hangi sayfaların en çok ziyaret edildiğini ve kullanıcıların uygulamada nasıl gezindiğini anlamamıza yardımcı olur.

3.3. İşlevsellik Çerezleri
Kullanıcı tercihlerinizi hatırlamak için kullanılır (örneğin, dil tercihi, haber kategorileri).

3.4. Hedefleme/Reklam Çerezleri
Size ve ilgi alanlarınıza daha uygun içerik sunmak için kullanılır.

4. ÜÇÜNCÜ TARAF ÇEREZLERİ
Uygulamamızda aşağıdaki üçüncü taraf hizmetleri kullanılmaktadır:
• Google Analytics: Kullanım istatistikleri
• Firebase: Uygulama performansı ve crash raporları
• Reklam ağları: Kişiselleştirilmiş reklamlar

5. ÇEREZ YÖNETİMİ
Çerezleri yönetmek için:
• Cihaz ayarlarınızdan çerezleri silebilirsiniz
• Tarayıcı ayarlarından çerezleri engelleyebilirsiniz
• Uygulama ayarlarından tercihlerinizi değiştirebilirsiniz

Not: Zorunlu çerezleri engellerseniz, uygulama düzgün çalışmayabilir.

6. ÇEREZ SAKLAMA SÜRELERİ
• Oturum çerezleri: Oturum sonuna kadar
• Kalıcı çerezler: 1 yıl
• Üçüncü taraf çerezleri: İlgili hizmet sağlayıcının politikasına göre

7. ÇEREZ POLİTİKASI DEĞİŞİKLİKLERİ
Bu çerez politikası zaman zaman güncellenebilir. Önemli değişiklikler olduğunda sizi bilgilendireceğiz.

8. İLETİŞİM
Çerez politikamız hakkında sorularınız için: destek@newsly.com
''';
  }

  String _getAboutUsContent() {
    return '''
HAKKIMIZDA

Newsly, Türkiye'nin en güncel ve güvenilir haber kaynaklarını tek bir platformda toplayan modern bir haber uygulamasıdır.

VİZYONUMUZ
Kullanıcılarımıza tarafsız, doğru ve güncel haberleri en hızlı şekilde ulaştırmak, bilgiye erişimi kolaylaştırmak ve haber okuma deneyimini kişiselleştirmek.

MİSYONUMUZ
• Güvenilir haber kaynaklarından içerik sağlamak
• Kullanıcı dostu ve modern bir arayüz sunmak
• Kişiselleştirilmiş haber deneyimi oluşturmak
• Haber okuma alışkanlıklarını dijital çağa taşımak

ÖZELLİKLERİMİZ
• 200+ güvenilir haber kaynağı
• Kişiselleştirilmiş haber akışı
• Kategori bazlı filtreleme
• Yerel haberler
• Canlı yayın desteği
• Offline okuma
• Karanlık mod
• Bildirim sistemi

DEĞERLERİMİZ
• Tarafsızlık: Tüm görüşlere eşit mesafede duruyoruz
• Güvenilirlik: Sadece doğrulanmış kaynaklardan haber sunuyoruz
• Gizlilik: Kullanıcı verilerini korumaya önem veriyoruz
• İnovasyon: Sürekli gelişim ve yenilik peşindeyiz

EKİBİMİZ
Newsly, deneyimli yazılım geliştiriciler, tasarımcılar ve haber editörlerinden oluşan bir ekip tarafından geliştirilmektedir.

İLETİŞİM
E-posta: destek@newsly.com
Telefon: +90 212 XXX XX XX
Adres: İstanbul, Türkiye

Sosyal Medya:
• Twitter: @newsly_tr
• Instagram: @newsly_tr
• Facebook: /newsly.tr

© 2024 Newsly. Tüm hakları saklıdır.
''';
  }

  String _getContactContent() {
    return '''
İLETİŞİM

Newsly ekibi olarak, sorularınızı, önerilerinizi ve geri bildirimlerinizi duymaktan mutluluk duyarız.

GENEL İLETİŞİM
E-posta: destek@newsly.com
Telefon: +90 212 XXX XX XX
Çalışma Saatleri: Hafta içi 09:00 - 18:00

ADRES
Newsly Teknoloji A.Ş.
Maslak Mahallesi
Büyükdere Caddesi No: 123
Sarıyer / İstanbul
Türkiye

TEKNİK DESTEK
Teknik sorunlar için: teknik@newsly.com
Yanıt süresi: 24 saat içinde

İŞ BİRLİĞİ VE REKLAM
İş birlikleri için: isbirligi@newsly.com
Reklam için: reklam@newsly.com

BASIN VE MEDYA
Basın sorguları için: basin@newsly.com

HUKUK VE UYUMLULUK
Hukuki konular için: hukuk@newsly.com
KVKK başvuruları için: kvkk@newsly.com

SOSYAL MEDYA
Twitter: @newsly_tr
Instagram: @newsly_tr
Facebook: /newsly.tr
LinkedIn: /company/newsly

HABER KAYNAĞI BAŞVURUSU
Haber kaynağı olarak eklenmek için:
• E-posta: kaynaklar@newsly.com
• Başvuru formu: www.newsly.com/kaynak-basvuru

GERİ BİLDİRİM
Uygulamamızı geliştirmemize yardımcı olun:
• Önerileriniz için: oneriler@newsly.com
• Şikayet ve talepler için: destek@newsly.com

SORU VE CEVAPLAR
Sık sorulan sorular için: www.newsly.com/sss

ÇALIŞMA SAATLERİ
Pazartesi - Cuma: 09:00 - 18:00
Cumartesi: 10:00 - 16:00
Pazar: Kapalı

ACİL DURUMLAR
7/24 acil destek hattı: +90 212 XXX XX XX

Bize ulaştığınız için teşekkür ederiz!
''';
  }

  String _getTermsContent() {
    return '''
KULLANIM ŞARTLARI VE KOŞULLARI

Son güncelleme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. GENEL HÜKÜMLER
Bu kullanım şartları, Newsly mobil uygulamasını kullanan tüm kullanıcılar için geçerlidir. Uygulamayı kullanarak bu şartları kabul etmiş sayılırsınız.

2. HİZMET TANIMI
Newsly, çeşitli haber kaynaklarından içerik toplayarak kullanıcılara sunan bir haber agregasyon platformudur.

3. KULLANICI HESABI
3.1. Hesap Oluşturma
• 18 yaşından büyük olmalısınız
• Doğru ve güncel bilgiler vermelisiniz
• Hesap güvenliğinden siz sorumlusunuz

3.2. Hesap Güvenliği
• Şifrenizi kimseyle paylaşmayın
• Şüpheli aktivite durumunda bizi bilgilendirin
• Hesabınızdan yapılan tüm işlemlerden siz sorumlusunuz

4. KULLANIM KURALLARI
Aşağıdaki davranışlar yasaktır:
• Yasadışı içerik paylaşmak
• Başkalarının haklarını ihlal etmek
• Spam veya zararlı içerik göndermek
• Sistemi manipüle etmeye çalışmak
• Otomatik botlar kullanmak

5. İÇERİK VE TELİF HAKLARI
5.1. Haber İçerikleri
• Tüm haber içerikleri kaynak sitelere aittir
• Newsly sadece içerikleri toplar ve sunar
• Telif hakları orijinal yayıncılara aittir

5.2. Kullanıcı İçerikleri
• Paylaştığınız içeriklerden siz sorumlusunuz
• Newsly'ye sınırlı kullanım hakkı verirsiniz
• Telif hakkı ihlali yapmamalısınız

6. GİZLİLİK
Kişisel verilerinizin işlenmesi Gizlilik Politikamızda detaylı olarak açıklanmıştır.

7. HİZMET DEĞİŞİKLİKLERİ
Newsly, önceden haber vermeksizin:
• Hizmeti değiştirebilir
• Özellikleri ekleyebilir veya kaldırabilir
• Hizmeti geçici olarak durdurabilir

8. SORUMLULUK SINIRLAMALARI
8.1. İçerik Sorumluluğu
• Haber içeriklerinin doğruluğundan kaynak siteler sorumludur
• Newsly içerikleri kontrol etmekle yükümlü değildir

8.2. Hizmet Kesintileri
• Teknik arızalar olabilir
• Bakım çalışmaları yapılabilir
• Kesintilerden dolayı sorumluluk kabul edilmez

9. HİZMET BEDELİ
• Temel hizmetler ücretsizdir
• Premium özellikler ücretli olabilir
• Fiyatlar değiştirilebilir

10. HESAP SONLANDIRMA
10.1. Kullanıcı Tarafından
• İstediğiniz zaman hesabınızı kapatabilirsiniz
• Verileriniz politikamıza göre silinir

10.2. Newsly Tarafından
Aşağıdaki durumlarda hesabınız kapatılabilir:
• Kullanım şartlarını ihlal etmeniz
• Yasadışı aktivite
• Uzun süre kullanılmaması

11. UYUŞMAZLIK ÇÖZÜMÜ
• Türkiye Cumhuriyeti yasaları geçerlidir
• İstanbul mahkemeleri yetkilidir
• Önce dostane çözüm aranır

12. DEĞİŞİKLİKLER
Bu şartlar zaman zaman güncellenebilir. Önemli değişiklikler bildirilir.

13. İLETİŞİM
Sorularınız için: destek@newsly.com

14. KABUL
Uygulamayı kullanarak bu şartları kabul etmiş sayılırsınız.

© 2024 Newsly. Tüm hakları saklıdır.
''';
  }

  String _getPrivacyPolicyContent() {
    return '''
GİZLİLİK POLİTİKASI

Son güncelleme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. GİRİŞ
Newsly olarak, gizliliğinize önem veriyoruz. Bu politika, kişisel verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu açıklar.

2. TOPLANAN BİLGİLER

2.1. Doğrudan Sağladığınız Bilgiler
• Ad ve soyad
• E-posta adresi
• Profil fotoğrafı
• Haber tercihleri
• İlgi alanları

2.2. Otomatik Toplanan Bilgiler
• Cihaz bilgileri (model, işletim sistemi)
• IP adresi
• Konum bilgisi (izin verilirse)
• Uygulama kullanım verileri
• Çerez verileri

3. BİLGİLERİN KULLANIMI
Topladığımız bilgileri şu amaçlarla kullanırız:
• Hizmet sunmak ve geliştirmek
• Kişiselleştirilmiş içerik sağlamak
• Kullanıcı deneyimini iyileştirmek
• Güvenlik sağlamak
• İstatistiksel analizler yapmak
• Size bildirim göndermek
• Müşteri desteği sağlamak

4. BİLGİ PAYLAŞIMI
Bilgilerinizi aşağıdaki durumlarda paylaşabiliriz:

4.1. Hizmet Sağlayıcılar
• Bulut depolama hizmetleri
• Analitik hizmetler
• Reklam ağları
• Ödeme işlemcileri

4.2. Yasal Gereklilikler
• Yasal talep olması durumunda
• Haklarımızı korumak için
• Güvenlik tehditlerine karşı

4.3. İş Transferi
Şirket birleşme veya satın alma durumunda veriler devredebilir.

5. VERİ GÜVENLİĞİ
Verilerinizi korumak için:
• Şifreleme kullanıyoruz
• Güvenli sunucularda saklıyoruz
• Erişim kontrolü uyguluyoruz
• Düzenli güvenlik denetimleri yapıyoruz

6. VERİ SAKLAMA
• Hesap aktif olduğu sürece veriler saklanır
• Hesap kapatıldıktan sonra yasal süre kadar tutulur
• Silme talebiniz üzerine veriler silinir

7. HAKLARINIZ
KVKK kapsamında haklarınız:
• Verilerinize erişim
• Düzeltme talep etme
• Silme talep etme
• İşlemeye itiraz etme
• Veri taşınabilirliği
• Otomatik karar alma süreçlerine itiraz

8. ÇOCUKLARIN GİZLİLİĞİ
• Uygulamamız 18 yaş altı için değildir
• Bilerek çocuklardan veri toplamayız
• Fark edersek derhal sileriz

9. ÜÇÜNCÜ TARAF LİNKLER
• Uygulamamız üçüncü taraf linkleri içerebilir
• Bu sitelerin gizlilik politikalarından sorumlu değiliz
• Dikkatli olmanızı öneririz

10. ULUSLARARASI VERİ TRANSFERİ
• Verileriniz Türkiye'de saklanır
• Gerekirse yurt dışına aktarılabilir
• Uygun güvenlik önlemleri alınır

11. ÇEREZLER
Çerez kullanımı hakkında detaylı bilgi için Çerez Politikamıza bakın.

12. BİLDİRİMLER
• E-posta ile bildirim gönderebiliriz
• Push notification kullanabiliriz
• Ayarlardan yönetebilirsiniz

13. POLİTİKA DEĞİŞİKLİKLERİ
• Bu politika güncellenebilir
• Önemli değişiklikler bildirilir
• Devam eden kullanım kabul anlamına gelir

14. İLETİŞİM
Gizlilik konularında:
• E-posta: gizlilik@newsly.com
• KVKK başvuruları: kvkk@newsly.com
• Adres: İstanbul, Türkiye

15. RIZA
Uygulamayı kullanarak bu politikayı kabul etmiş sayılırsınız.

© 2024 Newsly. Tüm hakları saklıdır.
''';
  }
}
