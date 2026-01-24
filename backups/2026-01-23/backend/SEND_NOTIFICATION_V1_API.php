<?php
/**
 * FCM HTTP v1 API ile Bildirim Gönderme
 * 
 * Legacy API kapatıldığı için yeni v1 API kullanıyoruz.
 * Service Account ile OAuth2 token alıp bildirim gönderiyoruz.
 * 
 * helpers.php dosyasındaki send_notification fonksiyonunu BU İLE DEĞİŞTİR
 * Dosya: /home/newslyco/public_html/admin/app/helpers.php
 */

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id = null, $location_id = null, $tokens = null)
    {
        try {
            // Service account dosyası
            $serviceAccountPath = public_path('assets/firebase_config.json');
            
            if (!file_exists($serviceAccountPath)) {
                \Log::error('Service account dosyası bulunamadı');
                return false;
            }
            
            $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            
            // Project ID
            $projectId = $serviceAccount['project_id'] ?? null;
            if (empty($projectId)) {
                \Log::error('Project ID bulunamadı');
                return false;
            }
            
            // Access Token al
            $accessToken = getFirebaseAccessToken($serviceAccount);
            if (empty($accessToken)) {
                \Log::error('Access token alınamadı');
                return false;
            }
            
            // FCM v1 API URL
            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
            
            // Headers
            $headers = [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json'
            ];

            // Bildirim içeriği
            $notification = [
                'title' => $fcmMsg['title'] ?? '',
                'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
            ];
            
            // Resim varsa ekle
            if (!empty($fcmMsg['image'])) {
                $notification['image'] = $fcmMsg['image'];
            }

            // Data payload
            $data = [];
            foreach ($fcmMsg as $key => $value) {
                $data[$key] = (string) $value;
            }
            $data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';

            // Topic belirleme
            $category_id = $fcmMsg['category_id'] ?? 0;
            $type = $fcmMsg['type'] ?? 'default';
            
            if ($type == 'category' && $category_id > 0) {
                $topic = 'category_' . $category_id;
            } else {
                $topic = 'Turkish';
            }

            // Mesaj yapısı - v1 API formatı
            $message = [
                'message' => [
                    'topic' => $topic,
                    'notification' => $notification,
                    'data' => $data,
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'sound' => 'default',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        ]
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'default'
                            ]
                        ]
                    ]
                ]
            ];

            // Token varsa topic yerine token kullan
            if (!empty($tokens) && is_array($tokens)) {
                // v1 API'de tek tek göndermek gerekiyor
                $success = true;
                foreach ($tokens as $token) {
                    $message['message']['token'] = $token;
                    unset($message['message']['topic']);
                    
                    $result = sendFcmRequest($url, $headers, $message);
                    if (!$result) $success = false;
                }
                return $success;
            }

            // Topic'e gönder
            $result = sendFcmRequest($url, $headers, $message);
            
            \Log::info('FCM v1 Bildirim gönderildi', [
                'topic' => $topic,
                'title' => $fcmMsg['title'] ?? '',
                'result' => $result
            ]);
            
            return $result;

        } catch (\Exception $e) {
            \Log::error('send_notification error: ' . $e->getMessage());
            return false;
        }
    }
}

if (!function_exists('getFirebaseAccessToken')) {
    function getFirebaseAccessToken($serviceAccount)
    {
        try {
            $now = time();
            $expiry = $now + 3600; // 1 saat
            
            // JWT Header
            $header = [
                'alg' => 'RS256',
                'typ' => 'JWT'
            ];
            
            // JWT Payload
            $payload = [
                'iss' => $serviceAccount['client_email'],
                'sub' => $serviceAccount['client_email'],
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $expiry,
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging'
            ];
            
            // Base64 encode
            $base64Header = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
            $base64Payload = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');
            
            // Sign
            $signatureInput = $base64Header . '.' . $base64Payload;
            $privateKey = $serviceAccount['private_key'];
            
            openssl_sign($signatureInput, $signature, $privateKey, 'SHA256');
            $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
            
            $jwt = $signatureInput . '.' . $base64Signature;
            
            // Token al
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt
            ]));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            
            $response = curl_exec($ch);
            curl_close($ch);
            
            $data = json_decode($response, true);
            
            return $data['access_token'] ?? null;
            
        } catch (\Exception $e) {
            \Log::error('getFirebaseAccessToken error: ' . $e->getMessage());
            return null;
        }
    }
}

if (!function_exists('sendFcmRequest')) {
    function sendFcmRequest($url, $headers, $message)
    {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);

        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($error) {
            \Log::error('FCM cURL error: ' . $error);
            return false;
        }

        $response = json_decode($result, true);
        
        if ($httpCode != 200) {
            \Log::error('FCM Error', ['code' => $httpCode, 'response' => $response]);
            return false;
        }
        
        return true;
    }
}
