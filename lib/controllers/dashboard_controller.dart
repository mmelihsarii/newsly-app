import 'package:get/get.dart';

class DashboardController extends GetxController {
  // Hangi sekmedeyiz? (0: Anasayfa)
  var tabIndex = 0.obs;

  // Sekme değiştirme fonksiyonu
  void changeTabIndex(int index) {
    tabIndex.value = index;
    update(); // GetBuilder için UI güncelleme
  }
}
