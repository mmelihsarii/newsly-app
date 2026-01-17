import 'package:flutter/material.dart';

/// Represents a single news source
class NewsSourceItem {
  final String id;
  final String name;
  final String? logoUrl;

  const NewsSourceItem({required this.id, required this.name, this.logoUrl});
}

/// Represents a category of news sources
class NewsSourceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<NewsSourceItem> sources;

  const NewsSourceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sources,
  });
}

/// All available news sources, cleaned and categorized
const List<NewsSourceCategory> kNewsSources = [
  // ═══════════════════════════════════════════════════════════════════════════
  // BİLİM & TEKNOLOJİ
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'bilim_teknoloji',
    name: 'Bilim & Teknoloji',
    icon: Icons.science,
    color: Color(0xFF6366F1), // Indigo
    sources: [
      // Bilim
      NewsSourceItem(id: 'evrim_agaci', name: 'Evrim Ağacı'),
      NewsSourceItem(id: 'matematiksel', name: 'Matematiksel'),
      NewsSourceItem(id: 'kozmik_anafor', name: 'Kozmik Anafor'),
      NewsSourceItem(id: 'independent_bilim', name: 'Independent Bilim'),
      NewsSourceItem(
        id: 'herkese_bilim_teknoloji',
        name: 'Herkese Bilim Teknoloji',
      ),
      NewsSourceItem(id: 'gelecek_bilimde', name: 'Gelecek Bilimde'),
      NewsSourceItem(id: 'gercek_bilim', name: 'Gerçek Bilim'),
      NewsSourceItem(id: 'fizikist', name: 'Fizikist'),
      NewsSourceItem(id: 'tarihten_yazilar', name: 'Tarihten Yazılar'),
      NewsSourceItem(id: 'tarihli_bilim', name: 'Tarihli Bilim'),
      NewsSourceItem(id: 'bilimup', name: 'Bilimup'),
      NewsSourceItem(id: 'bilimoloji', name: 'Bilimoloji'),
      NewsSourceItem(id: 'bilim_ve_gelecek', name: 'Bilim ve Gelecek'),
      NewsSourceItem(id: 'bilim_gunlugu', name: 'Bilim Günlüğü'),
      NewsSourceItem(id: 'beyinsizler', name: 'Beyinsizler'),
      NewsSourceItem(id: 'arkeofili', name: 'Arkeofili'),
      // Teknoloji
      NewsSourceItem(id: 'webtekno', name: 'Webtekno'),
      NewsSourceItem(id: 'teknoblog', name: 'Teknoblog'),
      NewsSourceItem(id: 'donanim_haber', name: 'Donanım Haber'),
      NewsSourceItem(id: 'technopat', name: 'Technopat'),
      NewsSourceItem(id: 'webrazzi', name: 'Webrazzi'),
      NewsSourceItem(id: 'teknolojiokulu', name: 'Teknolojiokulu'),
      NewsSourceItem(id: 'dijitalx', name: 'Dijitalx'),
      NewsSourceItem(id: 'indir', name: 'İndir'),
      NewsSourceItem(
        id: 'haber_global_bilim_teknoloji',
        name: 'Haber Global Bilim-Teknoloji',
      ),
      NewsSourceItem(id: 'mynet_teknoloji', name: 'Mynet Teknoloji'),
      NewsSourceItem(
        id: 'yeni_akit_bilim_teknoloji',
        name: 'Yeni Akit Bilim-Teknoloji',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // GÜNDEM & POLİTİKA
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'gundem_politika',
    name: 'Gündem & Politika',
    icon: Icons.newspaper,
    color: Color(0xFFEF4444), // Red
    sources: [
      // Büyük Medya
      NewsSourceItem(id: 'ntv', name: 'NTV'),
      NewsSourceItem(id: 'cnn_turk', name: 'CNN Türk'),
      NewsSourceItem(id: 'bbc', name: 'BBC Türkçe'),
      NewsSourceItem(id: 'trt_haber', name: 'TRT Haber'),
      NewsSourceItem(id: 'a_haber', name: 'A Haber'),
      NewsSourceItem(id: 'haber_turk', name: 'Habertürk'),
      NewsSourceItem(id: 'haber_global', name: 'Haber Global'),
      NewsSourceItem(id: 'tgrt_haber', name: 'TGRT Haber'),
      // Gazeteler
      NewsSourceItem(id: 'hurriyet', name: 'Hürriyet'),
      NewsSourceItem(id: 'sozcu', name: 'Sözcü'),
      NewsSourceItem(id: 'sabah', name: 'Sabah'),
      NewsSourceItem(id: 'aksam', name: 'Akşam'),
      NewsSourceItem(id: 'star', name: 'Star'),
      NewsSourceItem(id: 'turkiye_gazetesi', name: 'Türkiye Gazetesi'),
      NewsSourceItem(id: 'yeni_safak', name: 'Yeni Şafak'),
      NewsSourceItem(id: 'yenicag_gazetesi', name: 'Yeniçağ Gazetesi'),
      NewsSourceItem(id: 'yeni_asir', name: 'Yeni Asır'),
      NewsSourceItem(id: 'yeni_akit', name: 'Yeni Akit'),
      NewsSourceItem(id: 'yurt_gazetesi', name: 'Yurt Gazetesi'),
      NewsSourceItem(id: 'milli_gazete', name: 'Milli Gazete'),
      NewsSourceItem(id: 'dunya_gazetesi', name: 'Dünya Gazetesi'),
      // Dijital Medya
      NewsSourceItem(id: 't24', name: 'T24'),
      NewsSourceItem(id: 'oda_tv', name: 'Oda TV'),
      NewsSourceItem(id: 'sol_haber', name: 'Sol Haber'),
      NewsSourceItem(id: 'diken', name: 'Diken'),
      NewsSourceItem(id: 'gazete_duvar', name: 'Gazete Duvar'),
      NewsSourceItem(id: 'independent_turkiye', name: 'Independent Türkiye'),
      NewsSourceItem(id: 'teyit_org', name: 'Teyit.org'),
      NewsSourceItem(id: 'journo', name: 'Journo'),
      NewsSourceItem(id: 'dw_haber', name: 'DW Haber'),
      NewsSourceItem(id: 'sputnik', name: 'Sputnik'),
      NewsSourceItem(id: 'cgtn_turk', name: 'CGTN Türk'),
      // Diğer
      NewsSourceItem(id: 'halk_tv', name: 'Halk TV'),
      NewsSourceItem(id: 'tele1', name: 'Tele1'),
      NewsSourceItem(id: 'bengu_turk', name: 'Bengü Türk'),
      NewsSourceItem(id: 'time_turk', name: 'Time Türk'),
      NewsSourceItem(id: 'agos', name: 'Agos'),
      NewsSourceItem(id: 'arti_gercek', name: 'Artı Gerçek'),
      NewsSourceItem(id: 'aydinlik', name: 'Aydınlık'),
      NewsSourceItem(id: 'evrensel', name: 'Evrensel'),
      NewsSourceItem(id: 'serbestiyet', name: 'Serbestiyet'),
      NewsSourceItem(id: 'korkusuz', name: 'Korkusuz'),
      NewsSourceItem(id: 'kisa_dalga', name: 'Kısa Dalga'),
      NewsSourceItem(id: 'karar', name: 'Karar'),
      NewsSourceItem(id: 'muhalif', name: 'Muhalif'),
      // Haber Portalları
      NewsSourceItem(id: 'haber_7', name: 'Haber 7'),
      NewsSourceItem(id: 'haberler_com', name: 'Haberler.com'),
      NewsSourceItem(id: 'internet_haber', name: 'İnternet Haber'),
      NewsSourceItem(id: 'en_son_haber', name: 'En Son Haber'),
      NewsSourceItem(id: 'f5_haber', name: 'F5 Haber'),
      NewsSourceItem(id: 'haber_port', name: 'Haber Port'),
      NewsSourceItem(id: 'en_politik', name: 'En Politik'),
      NewsSourceItem(id: 'dokuz8_haber', name: 'Dokuz8 Haber'),
      NewsSourceItem(id: 'dogru_haber', name: 'Doğru Haber'),
      NewsSourceItem(id: 'dirilis_postasi', name: 'Diriliş Postası'),
      NewsSourceItem(id: 'dik_gazete', name: 'Dik Gazete'),
      NewsSourceItem(id: 'demokrat_haber', name: 'Demokrat Haber'),
      NewsSourceItem(id: 'bir_gazete', name: 'Bir Gazete'),
      NewsSourceItem(id: 'beyaz_gundem', name: 'Beyaz Gündem'),
      NewsSourceItem(id: 'acik_gazete', name: 'Açık Gazete'),
      NewsSourceItem(id: 'abc_gazetesi', name: 'ABC Gazetesi'),
      NewsSourceItem(id: 'al_ain_turkiye', name: 'Al Ain Türkiye'),
      NewsSourceItem(id: 'fayn', name: 'Fayn'),
      NewsSourceItem(id: 'gzt', name: 'GZT'),
      NewsSourceItem(id: 'gazete_net', name: 'Gazete.net'),
      NewsSourceItem(id: 'gazete_pencere', name: 'Gazete Pencere'),
      NewsSourceItem(id: 'gazete_gundem', name: 'Gazete Gündem'),
      NewsSourceItem(id: 'haberet', name: 'Haberet'),
      NewsSourceItem(id: 'istanbul_gundem', name: 'İstanbul Gündem'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // SPOR
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'spor',
    name: 'Spor',
    icon: Icons.sports_soccer,
    color: Color(0xFF22C55E), // Green
    sources: [
      NewsSourceItem(id: 'a_spor', name: 'A Spor'),
      NewsSourceItem(id: 'fotomac', name: 'Fotomaç'),
      NewsSourceItem(id: 'foto_spor', name: 'Fotospor'),
      NewsSourceItem(id: 'ajans_spor', name: 'Ajans Spor'),
      NewsSourceItem(id: 'kontraspor', name: 'Kontraspor'),
      NewsSourceItem(id: 'megabayt_sport', name: 'Megabayt Sport'),
      NewsSourceItem(id: 'takvim_spor', name: 'Takvim Spor'),
      NewsSourceItem(id: 'haber_global_spor', name: 'Haber Global Spor'),
      NewsSourceItem(id: 'mynet_spor', name: 'Mynet Spor'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // EKONOMİ
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'ekonomi',
    name: 'Ekonomi',
    icon: Icons.trending_up,
    color: Color(0xFFF59E0B), // Amber
    sources: [
      NewsSourceItem(id: 'bloomberg_ht', name: 'Bloomberg HT'),
      NewsSourceItem(id: 'bigpara', name: 'BigPara'),
      NewsSourceItem(id: 'cnbc_e', name: 'CNBC-e'),
      NewsSourceItem(id: 'doviz', name: 'Döviz'),
      NewsSourceItem(id: 'ekonomi_gazetesi', name: 'Ekonomi Gazetesi'),
      NewsSourceItem(id: 'forbes_turkiye', name: 'Forbes Türkiye'),
      NewsSourceItem(id: 'sozcu_ekonomi', name: 'Sözcü Ekonomi'),
      NewsSourceItem(id: 'finans_gundem', name: 'Finans Gündem'),
      NewsSourceItem(id: 'takvim_ekonomi', name: 'Takvim Ekonomi'),
      NewsSourceItem(id: 'mynet_finans', name: 'Mynet Finans'),
      NewsSourceItem(id: 'yeni_akit_ekonomi', name: 'Yeni Akit Ekonomi'),
      NewsSourceItem(id: 'haber_global_ekonomi', name: 'Haber Global Ekonomi'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // SON DAKİKA
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'son_dakika',
    name: 'Son Dakika',
    icon: Icons.flash_on,
    color: Color(0xFFDC2626), // Deep Red
    sources: [
      NewsSourceItem(id: 'hurriyet_son_dakika', name: 'Hürriyet - Son Dakika'),
      NewsSourceItem(id: 'mynet_son_dakika', name: 'Mynet - Son Dakika'),
      NewsSourceItem(
        id: 'yeni_safak_son_dakika',
        name: 'Yeni Şafak - Son Dakika',
      ),
      NewsSourceItem(id: 'sozcu_son_dakika', name: 'Sözcü - Son Dakika'),
      NewsSourceItem(
        id: 'trt_haber_son_dakika',
        name: 'TRT Haber - Son Dakika',
      ),
      NewsSourceItem(id: 'sabah_son_dakika', name: 'Sabah - Son Dakika'),
    ],
  ),
  // ═══════════════════════════════════════════════════════════════════════════
  // YABANCI KAYNAKLAR
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'yabanci_kaynaklar',
    name: 'Yabancı Kaynaklar',
    icon: Icons.language,
    color: Color(0xFF8B5CF6), // Purple
    sources: [
      NewsSourceItem(id: 'new_york_times', name: 'The New York Times'),
      NewsSourceItem(id: 'financial_times', name: 'Financial Times'),
      NewsSourceItem(id: 'the_guardian', name: 'The Guardian'),
      NewsSourceItem(id: 'al_jazeera', name: 'Al Jazeera'),
      NewsSourceItem(id: 'bbc_news', name: 'BBC News'),
      NewsSourceItem(id: 'euro_news', name: 'Euro News'),
      NewsSourceItem(id: 'france_24', name: 'France 24'),
      NewsSourceItem(id: 'deutsche_welle', name: 'Deutsche Welle'),
      NewsSourceItem(id: 'washington_post', name: 'The Washington Post'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // HABER AJANSLARI
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'haber_ajanslari',
    name: 'Haber Ajansları',
    icon: Icons.rss_feed,
    color: Color(0xFF0EA5E9), // Sky Blue
    sources: [
      NewsSourceItem(id: 'bha', name: 'Birlik Haber Ajansı'),
      NewsSourceItem(id: 'iha', name: 'İHA'),
      NewsSourceItem(id: 'dha', name: 'DHA'),
      NewsSourceItem(id: 'aa', name: 'Anadolu Ajansı'),
      NewsSourceItem(id: 'tekha', name: 'Tekha Haber Ajansı'),
      NewsSourceItem(id: 'turkiye_haber_ajansi', name: 'Türkiye Haber Ajansı'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // YEREL HABERLER
  // ═══════════════════════════════════════════════════════════════════════════
  NewsSourceCategory(
    id: 'yerel_haberler',
    name: 'Yerel Haberler',
    icon: Icons.location_city,
    color: Color(0xFF14B8A6), // Teal
    sources: [
      // Aydın
      NewsSourceItem(id: 'aydin_haber_merkezi', name: 'Aydın Haber Merkezi'),
      NewsSourceItem(id: 'ajans_aydin', name: 'Ajans Aydın'),
      NewsSourceItem(id: 'nazilli_havadis', name: 'Nazilli Havadis'),
      NewsSourceItem(id: 'aydin_haberleri', name: 'Aydın Haberleri'),
      NewsSourceItem(id: 'gazete_aydin', name: 'Gazete Aydın'),
      NewsSourceItem(id: 'olay_aydin_gazetesi', name: 'Olay Aydın Gazetesi'),
      NewsSourceItem(id: 'aydin_safak', name: 'Aydın Şafak'),
      NewsSourceItem(id: 'efeler_haber', name: 'Efeler Haber'),
      NewsSourceItem(id: 'yeni_haber', name: 'Yeni Haber'),
      NewsSourceItem(id: 'ses_gazetesi', name: 'Ses Gazetesi'),
      NewsSourceItem(id: 'yeni_kiroba', name: 'Yeni Kiroba'),
      NewsSourceItem(id: 'haber_aydin', name: 'Haber Aydın'),
      NewsSourceItem(id: 'aydin_hedef', name: 'Aydın Hedef'),
      NewsSourceItem(id: 'manset_aydin', name: 'Manşet Aydın'),
      NewsSourceItem(id: 'aydin_denge', name: 'Aydın Denge'),
      NewsSourceItem(id: 'aydin_post', name: 'Aydın Post'),
      // Artvin
      NewsSourceItem(id: 'gundem_artvin', name: 'Gündem Artvin'),
      // Antalya
      NewsSourceItem(id: 'akdeniz_gercek', name: 'Akdeniz Gerçek'),
      NewsSourceItem(id: 'antalya_ekspres', name: 'Antalya Ekspres'),
      NewsSourceItem(id: 'bati_antalya', name: 'Batı Antalya'),
      NewsSourceItem(id: 'antalya_guncel', name: 'Antalya Güncel'),
      NewsSourceItem(id: 'my_gazete', name: 'My Gazete'),
      NewsSourceItem(id: 'antalya_hakkinda', name: 'Antalya Hakkında'),
      NewsSourceItem(id: 'antalya_gundem', name: 'Antalya Gündem'),
      NewsSourceItem(id: 'antalya_haber_takip', name: 'Antalya Haber Takip'),
      NewsSourceItem(id: 'akdeniz_manset', name: 'Akdeniz Manşet'),
      NewsSourceItem(id: 'antalya_haber', name: 'Antalya Haber'),
      NewsSourceItem(id: 'haber_antalya', name: 'Haber Antalya'),
      NewsSourceItem(id: 'gun_haber', name: 'Gün Haber'),
      NewsSourceItem(id: 'flas_gazetesi', name: 'Flaş Gazetesi'),
      // Ankara
      NewsSourceItem(id: 'ankara_masasi', name: 'Ankara Masası'),
      NewsSourceItem(id: 'zafer_gazetesi', name: 'Zafer Gazetesi'),
      NewsSourceItem(id: 'ankara_gazetesi', name: 'Ankara Gazetesi'),
      NewsSourceItem(id: 'anka_radar', name: 'Anka Radar'),
      NewsSourceItem(id: 'ankara_ulus_gazetesi', name: 'Ankara Ulus Gazetesi'),
      NewsSourceItem(id: 'medya_ankara', name: 'Medya Ankara'),
      NewsSourceItem(id: 'baskent_gazete', name: 'Başkent Gazete'),
      NewsSourceItem(id: 'yeni_ankara', name: 'Yeni Ankara'),
      // Ağrı
      NewsSourceItem(id: 'agri_haberleri', name: 'Ağrı Haberleri'),
      NewsSourceItem(id: 'karakose_haber', name: 'Karaköse Haber'),
      NewsSourceItem(id: 'agri_dogru_haber', name: 'Ağrı Doğru Haber'),
      NewsSourceItem(id: 'kent_04', name: 'Kent 04'),
      NewsSourceItem(id: 'agrida_haber', name: 'Ağrıda Haber'),
      NewsSourceItem(id: 'agri_basin', name: 'Ağrı Basın'),
      NewsSourceItem(id: 'agri_hurses', name: 'Ağrı Hürses'),
      // Afyon
      NewsSourceItem(id: 'tv_04', name: 'Tv 04'),
      NewsSourceItem(id: 'afyon_manset_haber', name: 'Afyon Manşet Haber'),
      NewsSourceItem(id: 'afyon_star_haber', name: 'Afyon Star Haber'),
      NewsSourceItem(id: 'afyon_yerel_basin', name: 'Afyon Yerel Basın'),
      NewsSourceItem(id: 'afyon_ana_haber', name: 'Afyon Ana Haber'),
      NewsSourceItem(id: 'afyon_postasi', name: 'Afyon Postası'),
      NewsSourceItem(id: 'afyon_haber', name: 'Afyon Haber'),
      NewsSourceItem(id: 'afyon_zafer', name: 'Afyon Zafer'),
      NewsSourceItem(id: 'kocatepe_gazetesi', name: 'Kocatepe Gazetesi'),
      NewsSourceItem(id: 'odak_gazetesi', name: 'Odak Gazetesi'),
      // Adana
      NewsSourceItem(id: 'adana_ulus', name: 'Adana Ulus'),
      NewsSourceItem(id: 'tam_adana_haber', name: 'Tam Adana Haber'),
      NewsSourceItem(id: 'egemen_gzt', name: 'Egemen Gzt'),
      NewsSourceItem(id: 'gazete_adana', name: 'Gazete Adana'),
      NewsSourceItem(id: 'adana_post', name: 'Adana Post'),
      NewsSourceItem(id: 'kucuk_saat', name: 'Küçük Saat'),
      NewsSourceItem(id: 'adanin_sesi', name: 'Adanın Sesi'),
      NewsSourceItem(id: 'adana_haber_merkezi', name: 'Adana Haber Merkezi'),
      NewsSourceItem(id: 'adana_toros_gazetesi', name: 'Adana Toros Gazetesi'),
      // Adıyaman
      NewsSourceItem(id: 'adiyaman_news', name: 'Adıyaman News'),
      NewsSourceItem(id: 'yeni_adiyaman', name: 'Yeni Adıyaman'),
      NewsSourceItem(id: 'adiyaman_manset', name: 'Adıyaman Manşet'),
      NewsSourceItem(id: 'gozde_tv', name: 'Gözde Tv'),
      NewsSourceItem(id: 'adiyamanda_haber', name: 'Adıyamanda Haber'),
      NewsSourceItem(id: 'isik_gazetesi', name: 'Işık Gazetesi'),
      NewsSourceItem(id: 'gune_bakis_gazetesi', name: 'Güne Bakış Gazetesi'),
      NewsSourceItem(id: 'adiyaman_gundemi', name: 'Adıyaman Gündemi'),
      NewsSourceItem(id: 'adiyamanlilar', name: 'Adıyamanlılar'),
      // Amasya
      NewsSourceItem(id: 'tasova', name: 'Taşova'),
      NewsSourceItem(id: '05_com_tr', name: '05.com.tr'),
      NewsSourceItem(id: 'objektif_amasya', name: 'Objektif Amasya'),
      NewsSourceItem(id: 'besni_guncel', name: 'Besni Güncel'),
      // Alanya
      NewsSourceItem(id: 'yeni_alanya', name: 'Yeni Alanya'),
      NewsSourceItem(id: 'ileri_gazetem', name: 'İleri Gazetem'),
      NewsSourceItem(id: 'ajans_bir', name: 'Ajans Bir'),
    ],
  ),
];

/// Helper to get all source IDs as a flat list
List<String> getAllSourceIds() {
  return kNewsSources
      .expand((category) => category.sources)
      .map((source) => source.id)
      .toList();
}

/// Helper to get a source by ID
NewsSourceItem? getSourceById(String id) {
  for (final category in kNewsSources) {
    for (final source in category.sources) {
      if (source.id == id) return source;
    }
  }
  return null;
}

/// Helper to get category by ID
NewsSourceCategory? getCategoryById(String id) {
  return kNewsSources.cast<NewsSourceCategory?>().firstWhere(
    (c) => c?.id == id,
    orElse: () => null,
  );
}
