import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';
import 'source_selection_view.dart';

class CitySelectionView extends StatefulWidget {
  const CitySelectionView({super.key});

  @override
  State<CitySelectionView> createState() => _CitySelectionViewState();
}

class _CitySelectionViewState extends State<CitySelectionView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String _searchQuery = '';

  // Türkiye'nin 81 ili (plaka koduna göre sıralı: 01-81)
  final List<String> _cities = [
    'Adana', // 01
    'Adıyaman', // 02
    'Afyonkarahisar', // 03
    'Ağrı', // 04
    'Amasya', // 05
    'Ankara', // 06
    'Antalya', // 07
    'Artvin', // 08
    'Aydın', // 09
    'Balıkesir', // 10
    'Bilecik', // 11
    'Bingöl', // 12
    'Bitlis', // 13
    'Bolu', // 14
    'Burdur', // 15
    'Bursa', // 16
    'Çanakkale', // 17
    'Çankırı', // 18
    'Çorum', // 19
    'Denizli', // 20
    'Diyarbakır', // 21
    'Edirne', // 22
    'Elazığ', // 23
    'Erzincan', // 24
    'Erzurum', // 25
    'Eskişehir', // 26
    'Gaziantep', // 27
    'Giresun', // 28
    'Gümüşhane', // 29
    'Hakkari', // 30
    'Hatay', // 31
    'Isparta', // 32
    'Mersin', // 33
    'İstanbul', // 34
    'İzmir', // 35
    'Kars', // 36
    'Kastamonu', // 37
    'Kayseri', // 38
    'Kırklareli', // 39
    'Kırşehir', // 40
    'Kocaeli', // 41
    'Konya', // 42
    'Kütahya', // 43
    'Malatya', // 44
    'Manisa', // 45
    'Kahramanmaraş', // 46
    'Mardin', // 47
    'Muğla', // 48
    'Muş', // 49
    'Nevşehir', // 50
    'Niğde', // 51
    'Ordu', // 52
    'Rize', // 53
    'Sakarya', // 54
    'Samsun', // 55
    'Siirt', // 56
    'Sinop', // 57
    'Sivas', // 58
    'Tekirdağ', // 59
    'Tokat', // 60
    'Trabzon', // 61
    'Tunceli', // 62
    'Şanlıurfa', // 63
    'Uşak', // 64
    'Van', // 65
    'Yozgat', // 66
    'Zonguldak', // 67
    'Aksaray', // 68
    'Bayburt', // 69
    'Karaman', // 70
    'Kırıkkale', // 71
    'Batman', // 72
    'Şırnak', // 73
    'Bartın', // 74
    'Ardahan', // 75
    'Iğdır', // 76
    'Yalova', // 77
    'Karabük', // 78
    'Kilis', // 79
    'Osmaniye', // 80
    'Düzce', // 81
  ];

  List<String> get _filteredCities {
    if (_searchQuery.isEmpty) return _cities;
    return _cities
        .where(
          (city) => city.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _goBack() {
    Get.back();
  }

  void _skip() {
    // Şehir seçimi atlandığında kaynak seçimine git
    Get.to(() => const SourceSelectionView());
  }

  Future<void> _next() async {
    if (_selectedCity != null) {
      // Firestore'a şehri kaydet
      await Get.find<UserService>().updateUserProfile(
        displayName: Get.find<UserService>().userProfile.value?['displayName'],
      );

      // Şehir bilgisini ayrıca kaydet
      // TODO: UserService'e city field eklenebilir

      // Kaynak seçimine git
      Get.to(() => const SourceSelectionView());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Geç',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Şehrinizi\nseçin.',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Şehir ara',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // City List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  final isSelected = _selectedCity == city;
                  final plateCode = _getCityPlateCode(city);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCity = city),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF4220B).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Plate Code Badge
                          Container(
                            width: 48,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                plateCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // City Name
                          Expanded(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Check Icon
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFF4220B),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedCity != null ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4220B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'İleri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCityPlateCode(String city) {
    final plateCodes = {
      'Adana': '01',
      'Adıyaman': '02',
      'Afyonkarahisar': '03',
      'Ağrı': '04',
      'Aksaray': '68',
      'Amasya': '05',
      'Ankara': '06',
      'Antalya': '07',
      'Ardahan': '75',
      'Artvin': '08',
      'Aydın': '09',
      'Balıkesir': '10',
      'Bartın': '74',
      'Batman': '72',
      'Bayburt': '69',
      'Bilecik': '11',
      'Bingöl': '12',
      'Bitlis': '13',
      'Bolu': '14',
      'Burdur': '15',
      'Bursa': '16',
      'Çanakkale': '17',
      'Çankırı': '18',
      'Çorum': '19',
      'Denizli': '20',
      'Diyarbakır': '21',
      'Düzce': '81',
      'Edirne': '22',
      'Elazığ': '23',
      'Erzincan': '24',
      'Erzurum': '25',
      'Eskişehir': '26',
      'Gaziantep': '27',
      'Giresun': '28',
      'Gümüşhane': '29',
      'Hakkari': '30',
      'Hatay': '31',
      'Iğdır': '76',
      'Isparta': '32',
      'İstanbul': '34',
      'İzmir': '35',
      'Kahramanmaraş': '46',
      'Karabük': '78',
      'Karaman': '70',
      'Kars': '36',
      'Kastamonu': '37',
      'Kayseri': '38',
      'Kırıkkale': '71',
      'Kırklareli': '39',
      'Kırşehir': '40',
      'Kilis': '79',
      'Kocaeli': '41',
      'Konya': '42',
      'Kütahya': '43',
      'Malatya': '44',
      'Manisa': '45',
      'Mardin': '47',
      'Mersin': '33',
      'Muğla': '48',
      'Muş': '49',
      'Nevşehir': '50',
      'Niğde': '51',
      'Ordu': '52',
      'Osmaniye': '80',
      'Rize': '53',
      'Sakarya': '54',
      'Samsun': '55',
      'Siirt': '56',
      'Sinop': '57',
      'Sivas': '58',
      'Şanlıurfa': '63',
      'Şırnak': '73',
      'Tekirdağ': '59',
      'Tokat': '60',
      'Trabzon': '61',
      'Tunceli': '62',
      'Uşak': '64',
      'Van': '65',
      'Yalova': '77',
      'Yozgat': '66',
      'Zonguldak': '67',
    };
    return plateCodes[city] ?? '';
  }
}
