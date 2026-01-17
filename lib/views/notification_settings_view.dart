import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Konu Listesi: Başlık -> Topic ID
  final Map<String, String> topics = {
    'Spor': 'spor',
    'Ekonomi': 'ekonomi',
    'Magazin': 'magazin',
    'Teknoloji': 'teknoloji',
    'Siyaset': 'siyaset',
    'Genel': 'genel', // Varsayılan genel duyurular için
  };

  // Switch durumlarını tutan map
  Map<String, bool> switchStates = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Kayıtlı tercihleri yükle
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var entry in topics.entries) {
        // Varsayılan olarak 'genel' konusu true olsun, diğerleri false
        bool defaultValue = entry.value == 'genel';
        switchStates[entry.value] = prefs.getBool(entry.value) ?? defaultValue;
      }
      isLoading = false;
    });
  }

  // Abonelik durumunu değiştir
  Future<void> _toggleSubscription(String topicKey, bool value) async {
    setState(() {
      switchStates[topicKey] = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(topicKey, value);

    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic(topicKey);
      print("✅ Abone olundu: $topicKey");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTopicName(topicKey)} bildirimleri açıldı'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topicKey);
      print("❌ Abonelikten çıkıldı: $topicKey");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTopicName(topicKey)} bildirimleri kapatıldı'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Key'den Görünen Adı bulma helper'ı
  String _getTopicName(String key) {
    return topics.entries.firstWhere((entry) => entry.value == key).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bildirim Ayarları"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  "İlgi Alanlarınızı Seçin",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sadece seçtiğiniz konularda bildirim alacaksınız.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ...topics.entries.map((entry) {
                  final displayName = entry.key;
                  final topicId = entry.value;

                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      value: switchStates[topicId] ?? false,
                      onChanged: (bool value) {
                        _toggleSubscription(topicId, value);
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
