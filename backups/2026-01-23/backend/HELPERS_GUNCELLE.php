<?php
/**
 * helpers.php'deki send_notification fonksiyonunu GÜNCELLE
 * 
 * Dosya: /home/newslyco/public_html/admin/app/helpers.php
 * 
 * ESKİ send_notification fonksiyonunu BUL ve bu yeni versiyonla DEĞİŞTİR
 * 
 * DEĞİŞİKLİK: Token yerine TOPIC'e gönderiyor
 * Bu sayede Flutter'ın token kaydetmesine gerek yok
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id, $location_id, $devicetoken = [])
    {
        $firebase_config = public_path('assets/firebase_config.json');
        
        if (!file_exists($firebase_config)) {
            \Log::error('Firebase config bulunamadı');
            return;
        }
        
        try {
            $firebase = (new \Kreait\Firebase\Factory())->withServiceAccount($firebase_config);
            $messaging = $firebase->createMessaging();
            
            // Topic belirle - Turkish sabit topic kullan
            $topic = 'Turkish';
            
            // CloudMessage oluştur - TOPIC'e gönder
            $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('topic', $topic)
                ->withNotification($fcmMsg)
                ->withData($fcmMsg);
            
            // Gönder
            $result = $messaging->send($message);
            
            \Log::info('Bildirim gönderildi (topic)', [
                'topic' => $topic,
                'title' => $fcmMsg['title'] ?? $fcmMsg['body'] ?? '',
            ]);
            
        } catch (\Exception $e) {
            \Log::error('Bildirim hatası: ' . $e->getMessage());
        }
    }
}
