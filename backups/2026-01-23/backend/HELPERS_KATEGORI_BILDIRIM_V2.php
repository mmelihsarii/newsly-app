<?php
/**
 * KATEGORİYE GÖRE BİLDİRİM GÖNDERME - V2
 * 
 * Bu fonksiyonu helpers.php dosyasındaki send_notification fonksiyonuyla DEĞİŞTİR
 * Dosya: /home/newslyco/public_html/admin/app/helpers.php
 * 
 * ÖNEMLİ: Kategori seçildiğinde SADECE o kategorinin topic'ine gönderir
 * Kullanıcı hangi kategorileri takip ediyorsa sadece o bildirimleri alır
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id = null, $location_id = null, $tokens = null)
    {
        try {
            // Firebase config dosyasını oku
            $firebase_config_path = public_path('assets/firebase_config.json');
            
            if (!file_exists($firebase_config_path)) {
                \Log::error('Firebase config dosyası bulunamadı');
                return false;
            }
            
            $firebase_config = json_decode(file_get_contents($firebase_config_path), true);
            $server_key = $firebase_config['server_key'] ?? null;
            
            if (empty($server_key)) {
                \Log::error('Firebase server key bulunamadı');
                return false;
            }

            // FCM API URL
            $url = 'https://fcm.googleapis.com/fcm/send';
            
            // Headers
            $headers = [
                'Authorization: key=' . $server_key,
                'Content-Type: application/json'
            ];

            // Bildirim içeriği
            $notification = [
                'title' => $fcmMsg['title'] ?? '',
                'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
                'sound' => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];
            
            // Resim varsa ekle
            if (!empty($fcmMsg['image'])) {
                $notification['image'] = $fcmMsg['image'];
            }

            // Data payload
            $data = $fcmMsg;
            $data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';

            // =====================================================
            // KATEGORİYE GÖRE TOPIC BELİRLE
            // =====================================================
            $category_id = $fcmMsg['category_id'] ?? 0;
            $type = $fcmMsg['type'] ?? 'default';
            
            // Eğer kategori seçilmişse, SADECE o kategorinin topic'ine gönder
            // Kullanıcı bu kategoriye abone değilse bildirim ALMAZ
            if ($type == 'category' && $category_id > 0) {
                $topic = 'category_' . $category_id;
                \Log::info("Bildirim SADECE kategori topic'ine gönderiliyor: $topic");
            } else {
                // Default tip seçilmişse - HİÇBİR YERE GÖNDERME
                // Çünkü kullanıcılar artık genel topic'lere abone değil
                \Log::warning("Default tip seçildi - bildirim gönderilmedi. Kategori seçin!");
                return false;
            }

            // Mesaj yapısı - Topic'e gönder
            $message = [
                'to' => '/topics/' . $topic,
                'notification' => $notification,
                'data' => $data,
                'priority' => 'high',
            ];

            // Token listesi varsa (belirli kullanıcılara gönderim)
            if (!empty($tokens) && is_array($tokens)) {
                unset($message['to']);
                $message['registration_ids'] = array_values(array_unique($tokens));
                \Log::info("Bildirim " . count($tokens) . " token'a gönderiliyor");
            }

            // cURL ile gönder
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);

            $result = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);

            if ($error) {
                \Log::error('FCM cURL hatası: ' . $error);
                return false;
            }

            $response = json_decode($result, true);
            
            if ($http_code == 200) {
                \Log::info('FCM Bildirim gönderildi', [
                    'topic' => $topic,
                    'category_id' => $category_id,
                    'title' => $fcmMsg['title'] ?? '',
                    'response' => $response
                ]);
                return true;
            } else {
                \Log::error('FCM Hata', [
                    'http_code' => $http_code,
                    'response' => $response
                ]);
                return false;
            }

        } catch (\Exception $e) {
            \Log::error('send_notification exception: ' . $e->getMessage());
            return false;
        }
    }
}
