<?php
/**
 * send_notification helper fonksiyonu - İKON DESTEKLİ
 * 
 * Bu fonksiyonu mevcut helpers.php dosyandaki send_notification fonksiyonuyla değiştir.
 * Dosya yolu: app/Helpers/helpers.php veya app/helpers.php
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id = 0, $location_id = 0, $tokens = [])
    {
        try {
            $firebase_config = public_path('assets/firebase_config.json');
            if (!file_exists($firebase_config)) {
                return false;
            }

            $config = json_decode(file_get_contents($firebase_config), true);
            $serverKey = $config['server_key'] ?? null;

            if (!$serverKey) {
                \Log::error('FCM server key bulunamadı');
                return false;
            }

            // Token listesi boşsa topic'e gönder
            if (empty($tokens)) {
                // Topic belirleme
                $topic = 'Turkish'; // Varsayılan
                if ($language_id > 0) {
                    $language = \App\Models\Language::find($language_id);
                    if ($language) {
                        $topic = $language->language ?? 'Turkish';
                    }
                }

                // Her bildirim için benzersiz tag
                $uniqueTag = 'newsly_' . time() . '_' . rand(1000, 9999);

                $message = [
                    'to' => '/topics/' . $topic,
                    'notification' => [
                        'title' => $fcmMsg['title'] ?? '',
                        'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
                        'sound' => 'default',
                        // ===== Android için ikon =====
                        'icon' => 'ic_stat_notification',
                        'color' => '#F4220B',
                        // ===== Benzersiz tag - art arda bildirimlerde ikon karışmasını önler =====
                        'tag' => $uniqueTag,
                    ],
                    'data' => $fcmMsg,
                    // ===== Android spesifik ayarlar =====
                    'android' => [
                        'priority' => 'high',
                        'collapse_key' => $uniqueTag,
                        'notification' => [
                            'icon' => 'ic_stat_notification',
                            'color' => '#F4220B',
                            'sound' => 'default',
                            'channel_id' => 'high_importance_channel',
                            'tag' => $uniqueTag,
                        ],
                    ],
                ];
            } else {
                // Belirli token'lara gönder
                // Her bildirim için benzersiz tag
                $uniqueTag = 'newsly_' . time() . '_' . rand(1000, 9999);

                $message = [
                    'registration_ids' => $tokens,
                    'notification' => [
                        'title' => $fcmMsg['title'] ?? '',
                        'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
                        'sound' => 'default',
                        // ===== Android için ikon =====
                        'icon' => 'ic_stat_notification',
                        'color' => '#F4220B',
                        'tag' => $uniqueTag,
                    ],
                    'data' => $fcmMsg,
                    // ===== Android spesifik ayarlar =====
                    'android' => [
                        'priority' => 'high',
                        'collapse_key' => $uniqueTag,
                        'notification' => [
                            'icon' => 'ic_stat_notification',
                            'color' => '#F4220B',
                            'sound' => 'default',
                            'channel_id' => 'high_importance_channel',
                            'tag' => $uniqueTag,
                        ],
                    ],
                ];
            }

            // Resim varsa ekle
            if (!empty($fcmMsg['image'])) {
                $message['notification']['image'] = $fcmMsg['image'];
            }

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: key=' . $serverKey,
                'Content-Type: application/json',
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode >= 400) {
                \Log::error("FCM hatası: HTTP $httpCode - $response");
                return false;
            }

            \Log::info("Bildirim gönderildi: " . ($fcmMsg['title'] ?? 'No title'));
            return true;

        } catch (\Exception $e) {
            \Log::error('Bildirim gönderme hatası: ' . $e->getMessage());
            return false;
        }
    }
}
