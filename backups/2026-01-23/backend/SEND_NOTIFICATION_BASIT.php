<?php
/**
 * BASIT SEND_NOTIFICATION FONKSİYONU
 * 
 * helpers.php dosyasındaki mevcut send_notification fonksiyonunu BUL ve DEĞİŞTİR
 * Dosya: /home/newslyco/public_html/admin/app/helpers.php
 * 
 * NASIL ÇALIŞIR:
 * - Panel'den "Kategori" tipi seçilirse → category_X topic'ine gönderir
 * - Panel'den "Default" tipi seçilirse → Turkish topic'ine gönderir (herkes alır)
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id = null, $location_id = null, $tokens = null)
    {
        try {
            $firebase_config_path = public_path('assets/firebase_config.json');
            
            if (!file_exists($firebase_config_path)) {
                \Log::error('Firebase config bulunamadı');
                return false;
            }
            
            $firebase_config = json_decode(file_get_contents($firebase_config_path), true);
            $server_key = $firebase_config['server_key'] ?? null;
            
            if (empty($server_key)) {
                \Log::error('Server key bulunamadı');
                return false;
            }

            $url = 'https://fcm.googleapis.com/fcm/send';
            
            $headers = [
                'Authorization: key=' . $server_key,
                'Content-Type: application/json'
            ];

            $notification = [
                'title' => $fcmMsg['title'] ?? '',
                'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
                'sound' => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];
            
            if (!empty($fcmMsg['image'])) {
                $notification['image'] = $fcmMsg['image'];
            }

            $data = $fcmMsg;
            $data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';

            // Topic belirleme
            $category_id = $fcmMsg['category_id'] ?? 0;
            $type = $fcmMsg['type'] ?? 'default';
            
            if ($type == 'category' && $category_id > 0) {
                // Kategori seçilmişse sadece o kategoriye gönder
                $topic = 'category_' . $category_id;
                \Log::info("Bildirim category topic'e: $topic");
            } else {
                // Default - herkese gönder
                $topic = 'Turkish';
                \Log::info("Bildirim Turkish topic'e");
            }

            $message = [
                'to' => '/topics/' . $topic,
                'notification' => $notification,
                'data' => $data,
                'priority' => 'high',
            ];

            // Token varsa token'lara gönder
            if (!empty($tokens) && is_array($tokens)) {
                unset($message['to']);
                $message['registration_ids'] = array_values(array_unique($tokens));
            }

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
                \Log::error('FCM cURL error: ' . $error);
                return false;
            }

            $response = json_decode($result, true);
            \Log::info('FCM Response', ['code' => $http_code, 'response' => $response]);

            return $http_code == 200;

        } catch (\Exception $e) {
            \Log::error('send_notification error: ' . $e->getMessage());
            return false;
        }
    }
}
