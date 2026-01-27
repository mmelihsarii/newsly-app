import 'package:get/get.dart';
import '../models/news_model.dart';
import '../services/local_news_service.dart';
import '../utils/city_data.dart';

class LocalController extends GetxController {
  final LocalNewsService _localNewsService = LocalNewsService();

  var cityList = <Map<String, dynamic>>[].obs;
  var selectedCity = Rxn<Map<String, dynamic>>();
  var localSources = <LocalSource>[].obs;
  var localNewsList = <NewsModel>[].obs;
  var isCitiesLoading = false.obs;
  var isNewsLoading = false.obs;
  
  // Seçili şehre ait kaynaklar
  var citySourcesList = <LocalSource>[].obs;
  
  // İlçe listesi ve seçili ilçe
  var districtList = <String>[].obs;
  var selectedDistrict = Rxn<String>();
  var districtSourcesList = <LocalSource>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCities();
    _loadLocalSources();
  }

  void _loadCities() {
    cityList.assignAll(CityData.cities);
    if (cityList.isNotEmpty) {
      selectedCity.value = cityList.first;
      _loadDistricts();
    }
  }
  
  void _loadDistricts() {
    if (selectedCity.value == null) {
      districtList.clear();
      return;
    }
    
    final districts = selectedCity.value!['districts'] as List<dynamic>?;
    if (districts != null) {
      districtList.assignAll(districts.cast<String>());
    } else {
      districtList.clear();
    }
    selectedDistrict.value = null;
  }

  Future<void> _loadLocalSources() async {
    isCitiesLoading.value = true;
    try {
      final sources = await _localNewsService.fetchLocalSources(forceRefresh: true);
      localSources.assignAll(sources);
      print('📍 Toplam ${sources.length} yerel kaynak yüklendi');
      
      if (selectedCity.value != null) {
        _updateAllSources();
        await fetchLocalNews();
      }
    } catch (e) {
      print('❌ Yerel kaynak yükleme hatası: $e');
    } finally {
      isCitiesLoading.value = false;
    }
  }

  Future<void> loadSources() async {
    await _loadLocalSources();
  }

  void selectCity(Map<String, dynamic> city) {
    selectedCity.value = city;
    selectedDistrict.value = null;
    _loadDistricts();
    _updateAllSources();
    fetchLocalNews();
  }
  
  void selectDistrict(String? district) {
    selectedDistrict.value = district;
    _updateDistrictSources();
    fetchLocalNews();
  }
  
  /// Tüm kaynakları güncelle (şehir + ilçeler)
  void _updateAllSources() {
    if (selectedCity.value == null) {
      citySourcesList.clear();
      districtSourcesList.clear();
      return;
    }
    
    final cityName = selectedCity.value!['name'] as String;
    
    // Şehir kaynakları
    final citySources = _getMatchingSourcesForLocation(cityName);
    citySourcesList.assignAll(citySources);
    
    // İlçe kaynakları (tüm ilçeler için)
    final allDistrictSources = <LocalSource>[];
    final districts = selectedCity.value!['districts'] as List<dynamic>?;
    if (districts != null) {
      for (var district in districts) {
        final districtSources = _getMatchingSourcesForLocation(district.toString());
        for (var source in districtSources) {
          if (!allDistrictSources.any((s) => s.id == source.id) &&
              !citySources.any((s) => s.id == source.id)) {
            allDistrictSources.add(source);
          }
        }
      }
    }
    districtSourcesList.assignAll(allDistrictSources);
    
    print('📍 $cityName: ${citySources.length} şehir kaynağı, ${allDistrictSources.length} ilçe kaynağı');
  }
  
  /// Seçili ilçeye ait kaynakları güncelle
  void _updateDistrictSources() {
    if (selectedDistrict.value == null) {
      return;
    }
    
    final districtName = selectedDistrict.value!;
    final matchingSources = _getMatchingSourcesForLocation(districtName);
    districtSourcesList.assignAll(matchingSources);
    print('📍 $districtName için ${matchingSources.length} kaynak bulundu');
  }
  
  /// Lokasyon (şehir veya ilçe) için eşleşen kaynakları bul
  List<LocalSource> _getMatchingSourcesForLocation(String locationName) {
    final normalizedLocation = _normalizeText(locationName);
    final locationVariants = _getLocationVariants(locationName);
    
    return localSources.where((source) {
      final normalizedSourceName = _normalizeText(source.name);
      
      // Direkt lokasyon adı kontrolü
      if (normalizedSourceName.contains(normalizedLocation)) return true;
      
      // Varyant kontrolü
      for (var variant in locationVariants) {
        if (normalizedSourceName.contains(_normalizeText(variant))) return true;
      }
      
      return false;
    }).toList();
  }

  Future<void> fetchLocalNews() async {
    if (selectedCity.value == null) return;

    isNewsLoading.value = true;
    localNewsList.clear();

    try {
      List<NewsModel> allNews = [];
      List<LocalSource> sourcesToFetch = [];

      // İlçe seçiliyse sadece ilçe kaynaklarını kullan
      if (selectedDistrict.value != null) {
        sourcesToFetch = _getMatchingSourcesForLocation(selectedDistrict.value!);
        print('🔍 ${selectedDistrict.value} için ${sourcesToFetch.length} kaynak kontrol ediliyor...');
      } else {
        // Şehir ve tüm ilçelerinden haberleri çek
        final cityName = selectedCity.value!['name'] as String;
        sourcesToFetch = _getMatchingSourcesForLocation(cityName);
        
        // İlçe kaynaklarını da ekle
        final districts = selectedCity.value!['districts'] as List<dynamic>?;
        if (districts != null) {
          for (var district in districts) {
            final districtSources = _getMatchingSourcesForLocation(district.toString());
            for (var source in districtSources) {
              if (!sourcesToFetch.any((s) => s.id == source.id)) {
                sourcesToFetch.add(source);
              }
            }
          }
        }
        
        print('🔍 $cityName ve ilçeleri için ${sourcesToFetch.length} kaynak kontrol ediliyor...');
      }

      // Kaynakları logla
      for (var source in sourcesToFetch.take(10)) {
        print('   📰 ${source.name}');
      }
      if (sourcesToFetch.length > 10) {
        print('   ... ve ${sourcesToFetch.length - 10} kaynak daha');
      }

      // Kaynaklardan haberleri çek
      for (var source in sourcesToFetch) {
        final news = await _localNewsService.fetchNewsForSource(source.name, source.rssUrl);
        allNews.addAll(news);
      }

      // Tarihe göre sırala
      allNews.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });

      localNewsList.assignAll(allNews);
      print('✅ Toplam ${allNews.length} haber');
    } catch (e) {
      print('❌ Haber çekme hatası: $e');
    } finally {
      isNewsLoading.value = false;
    }
  }

  /// Lokasyon varyantlarını getir (şehir veya ilçe)
  List<String> _getLocationVariants(String locationName) {
    final variants = <String>[locationName];
    
    // Özel şehir/ilçe varyantları
    final locationMappings = {
      // Şehirler
      'istanbul': ['istanbul', 'ist'],
      'izmir': ['izmir'],
      'ankara': ['ankara', 'ank'],
      'şanlıurfa': ['sanliurfa', 'urfa', 'sanlıurfa'],
      'kahramanmaraş': ['kahramanmaras', 'maras', 'maraş'],
      'afyonkarahisar': ['afyon', 'afyonkarahisar'],
      'gaziantep': ['gaziantep', 'antep'],
      'mersin': ['mersin', 'icel', 'içel'],
      'eskişehir': ['eskisehir'],
      'diyarbakır': ['diyarbakir'],
      'kocaeli': ['kocaeli', 'izmit'],
      'sakarya': ['sakarya', 'adapazari', 'adapazarı'],
      'hatay': ['hatay', 'antakya'],
      // İstanbul ilçeleri
      'kadıköy': ['kadikoy'],
      'beşiktaş': ['besiktas'],
      'şişli': ['sisli'],
      'üsküdar': ['uskudar'],
      'beyoğlu': ['beyoglu'],
      'bakırköy': ['bakirkoy'],
      'ataşehir': ['atasehir'],
      'ümraniye': ['umraniye'],
      'sarıyer': ['sariyer'],
      'çekmeköy': ['cekmekoy'],
      'eyüpsultan': ['eyupsultan', 'eyüp'],
      'gaziosmanpaşa': ['gaziosmanpasa'],
      'başakşehir': ['basaksehir'],
      'avcılar': ['avcilar'],
      'küçükçekmece': ['kucukcekmece'],
      'büyükçekmece': ['buyukcekmece'],
      'beylikdüzü': ['beylikduzu'],
      'çatalca': ['catalca'],
      'arnavutköy': ['arnavutkoy'],
      'şile': ['sile'],
      // İzmir ilçeleri
      'karşıyaka': ['karsiyaka'],
      'çiğli': ['cigli'],
      'bayraklı': ['bayrakli'],
      'karabağlar': ['karabaglar'],
      'balçova': ['balcova'],
      'narlıdere': ['narlidere'],
      'güzelbahçe': ['guzelbahce'],
      'çeşme': ['cesme'],
      'torbalı': ['torbali'],
      'selçuk': ['selcuk'],
      'kuşadası': ['kusadasi'],
      'aliağa': ['aliaga'],
      'ödemiş': ['odemis'],
      'bayındır': ['bayindir'],
      'kemalpaşa': ['kemalpasa'],
      // Ankara ilçeleri
      'çankaya': ['cankaya'],
      'keçiören': ['kecioren'],
      'altındağ': ['altindag'],
      'gölbaşı': ['golbasi'],
      'çubuk': ['cubuk'],
      'beypazarı': ['beypazari'],
      'polatlı': ['polatli'],
      // Antalya ilçeleri
      'muratpaşa': ['muratpasa'],
      'konyaaltı': ['konyaalti'],
      'döşemealtı': ['dosemealti'],
      'kaş': ['kas'],
      'gazipaşa': ['gazipasa'],
      // Bursa ilçeleri
      'nilüfer': ['nilufer'],
      'yıldırım': ['yildirim'],
      'görükle': ['gorukle'],
      'inegöl': ['inegol'],
      'mustafakemalpaşa': ['mustafakemalpasa'],
      // Diğer önemli ilçeler
      'darıca': ['darica'],
      'körfez': ['korfez'],
      'gölcük': ['golcuk'],
      'çorlu': ['corlu'],
      'çerkezköy': ['cerkezkoy'],
      'lüleburgaz': ['luleburgaz'],
      'bandırma': ['bandirma'],
      'ayvalık': ['ayvalik'],
      'söke': ['soke'],
      'ereğli': ['eregli'],
      'akşehir': ['aksehir'],
      'beyşehir': ['beysehir'],
      'viranşehir': ['viransehir'],
      'kızıltepe': ['kiziltepe'],
      'erciş': ['ercis'],
      'doğubayazıt': ['dogubayazit', 'dogubeyazit'],
      'iğdır': ['igdir'],
      'sarıkamış': ['sarikamis'],
      'akçaabat': ['akcaabat'],
      'araklı': ['arakli'],
      'sürmene': ['surmene'],
      'ardeşen': ['ardesen'],
      'fındıklı': ['findikli'],
      'görele': ['gorele'],
      'ünye': ['unye'],
      'çarşamba': ['carsamba'],
      'taşköprü': ['taskopru'],
      'çankırı': ['cankiri'],
      'çorum': ['corum'],
      'osmancık': ['osmancik'],
      'şarkışla': ['sarkisla'],
      'divriği': ['divrigi'],
      'boğazlıyan': ['bogazliyan'],
      'yahyalı': ['yahyali'],
      'bünyan': ['bunyan'],
      'nevşehir': ['nevsehir'],
      'ürgüp': ['urgup'],
      'niğde': ['nigde'],
      'kırşehir': ['kirsehir'],
      'kırıkkale': ['kirikkale'],
      'seydişehir': ['seydisehir'],
      'eğirdir': ['egirdir'],
      'yalvaç': ['yalvac'],
      'çivril': ['civril'],
      'acıpayam': ['acipayam'],
      'uşak': ['usak'],
      'kütahya': ['kutahya'],
      'tavşanlı': ['tavsanli'],
      'bozüyük': ['bozuyuk'],
      'eskişehir': ['eskisehir'],
      'düzce': ['duzce'],
      'akçakoca': ['akcakoca'],
      'çaycuma': ['caycuma'],
      'karabük': ['karabuk'],
      'bartın': ['bartin'],
      'keşan': ['kesan'],
      'uzunköprü': ['uzunkopru'],
      'kırklareli': ['kirklareli'],
      'tekirdağ': ['tekirdag'],
      'çanakkale': ['canakkale'],
      'çınarcık': ['cinarcik'],
      'muğla': ['mugla'],
      'aydın': ['aydin'],
      'balıkesir': ['balikesir'],
      'elazığ': ['elazig'],
      'gümüşhane': ['gumushane'],
      'ağrı': ['agri'],
      'muş': ['mus'],
      'şırnak': ['sirnak'],
      'bingöl': ['bingol'],
      'adıyaman': ['adiyaman'],
      'ısparta': ['isparta'],
    };
    
    // Normalize edilmiş lokasyon adı ile eşleşme ara
    final normalizedLocation = _normalizeText(locationName);
    locationMappings.forEach((key, values) {
      if (_normalizeText(key) == normalizedLocation) {
        variants.addAll(values);
      }
    });
    
    return variants.toSet().toList();
  }

  String _normalizeText(String text) {
    const Map<String, String> turkishChars = {
      'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's',
      'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    };

    String normalized = text.toLowerCase().trim();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    return normalized;
  }

  List<Map<String, dynamic>> searchCities(String query) {
    if (query.isEmpty) return cityList;
    
    final normalizedQuery = _normalizeText(query);
    return cityList.where((city) {
      final cityName = _normalizeText(city['name'] ?? '');
      return cityName.contains(normalizedQuery);
    }).toList();
  }

  // Eski API uyumluluğu
  RxList<Map<String, dynamic>> get sourceList => cityList;
  Rxn<Map<String, dynamic>> get selectedSource => selectedCity;
  void selectSource(Map<String, dynamic> source) => selectCity(source);
}
