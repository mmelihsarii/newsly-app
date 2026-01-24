<?php
/**
 * YENİ send_notification fonksiyonu
 * 
 * Bu fonksiyonu helpers.php'deki ESKİ send_notification fonksiyonuyla DEĞİŞTİR
 * 
 * Dosya: /home/newslyco/public_html/admin/app/helpers.php
 * 
 * ESKİ fonksiyonu bul ve SİL, yerine bunu yapıştır.
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id, $location_id = 0, $devicetoken = [])
    {
        // Firebase config dosyası
        $firebase_config = public_path('assets/firebase_config.json');
        
        if (!file_exists($firebase_config)) {
            \Log::error('Firebase config dosyası bulunamadı: ' . $firebase_config);
            return false;
        }
        
        try {
            $firebase = (new \Kreait\Firebase\Factory())->withServiceAccount($firebase_config);
            $messaging = $firebase->createMessaging();
            
            // Topic belirle - dil ID'sine göre
            // Panel'de Turkish dili genelde ID=1
            $topic = 'Turkish'; // Varsayılan topic
            
            // Notification mesajı oluştur
            $notification = \Kreait\Firebase\Messaging\Notification::create(
                $fcmMsg['title'] ?? $fcmMsg['body'] ?? 'Bildirim',
                $fcmMsg['body'] ?? $fcmMsg['message'] ?? ''
            );
            
            // Data payload
            $data = [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'type' => $fcmMsg['type'] ?? 'notification',
                'news_id' => (string)($fcmMsg['news_id'] ?? '0'),
                'category_id' => (string)($fcmMsg['category_id'] ?? '0'),
                'language_id' => (string)$language_id,
            ];
            
            // Resim varsa ekle
            if (!empty($fcmMsg['image'])) {
                $data['image'] = $fcmMsg['image'];
            }
            
            // Topic'e mesaj gönder
            $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('topic', $topic)
                ->withNotification($notification)
                ->withData($data);
            
            $result = $messaging->send($message);
            
            \Log::info('Bildirim gönderildi', [
                'topic' => $topic,
                'title' => $fcmMsg['title'] ?? $fcmMsg['body'],
                'result' => $result
            ]);
            
            return true;
            
        } catch (\Exception $e) {
            \Log::error('Bildirim gönderme hatası: ' . $e->getMessage());
            return false;
        }
    }
}
