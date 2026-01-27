<?php
/**
 * SendNotificationController - Firestore Entegrasyonlu
 * 
 * Bildirim gönderildiğinde:
 * 1. FCM ile push notification gönderir
 * 2. Firestore 'notifications' collection'ına kaydeder
 * 
 * Bu sayede uygulama içi bildirim listesinde de görünür
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Log;

class SendNotificationController extends Controller
{
    private $projectId;
    private $serviceAccount;
    
    public function __construct()
    {
        $serviceAccountPath = storage_path('firebase-ayar.json');
        if (file_exists($serviceAccountPath)) {
            $this->serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            $this->projectId = $this->serviceAccount['project_id'] ?? null;
        }
    }

    /**
     * Bildirim gönder
     */
    public function send(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'topic' => 'nullable|string',
        ]);

        $title = $request->title;
        $body = $request->body;
        $topic = $request->topic ?? 'Turkish'; // Varsayılan topic
        $data = $request->data ?? [];

        try {
            // 1. FCM ile bildirim gönder
            $fcmResult = $this->sendFCMNotification($title, $body, $topic, $data);
            
            // 2. Firestore'a kaydet (uygulama içi liste için)
            $firestoreResult = $this->saveToFirestore($title, $body, $topic, $data);
            
            return response()->json([
                'error' => false,
                'message' => 'Bildirim başarıyla gönderildi',
                'fcm_result' => $fcmResult,
                'firestore_saved' => $firestoreResult,
            ]);
            
        } catch (\Exception $e) {
            Log::error('Bildirim gönderme hatası: ' . $e->getMessage());
            return response()->json([
                'error' => true,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * FCM ile push notification gönder
     */
    private function sendFCMNotification($title, $body, $topic, $data = [])
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) {
            throw new \Exception('FCM access token alınamadı');
        }

        $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

        $message = [
            'message' => [
                'topic' => $topic,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => array_merge($data, [
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ]),
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'high_importance_channel',
                        'sound' => 'default',
                        'icon' => 'ic_stat_notification',
                        'color' => '#F4220B',
                    ],
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ],
            ],
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode >= 400) {
            Log::error("FCM hatası: HTTP $httpCode - $response");
            return ['success' => false, 'error' => $response];
        }

        return ['success' => true, 'response' => json_decode($response, true)];
    }

    /**
     * Firestore'a bildirim kaydet
     */
    private function saveToFirestore($title, $body, $topic, $data = [])
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken || !$this->projectId) {
            Log::warning('Firestore token alınamadı');
            return false;
        }

        // Benzersiz document ID oluştur
        $docId = 'notif_' . time() . '_' . rand(1000, 9999);
        
        $url = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents/notifications/{$docId}";

        $fields = [
            'title' => ['stringValue' => $this->sanitizeText($title)],
            'body' => ['stringValue' => $this->sanitizeText($body)],
            'topic' => ['stringValue' => $topic],
            'created_at' => ['timestampValue' => date('c')],
            'data' => ['mapValue' => ['fields' => $this->convertToFirestoreMap($data)]],
        ];

        $requestBody = json_encode(['fields' => $fields], JSON_UNESCAPED_UNICODE);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
        curl_setopt($ch, CURLOPT_POSTFIELDS, $requestBody);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json; charset=utf-8',
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode >= 400) {
            Log::error("Firestore bildirim kaydetme hatası: HTTP $httpCode - $response");
            return false;
        }

        Log::info("Bildirim Firestore'a kaydedildi: $docId");
        return true;
    }

    /**
     * Data array'ini Firestore map formatına çevir
     */
    private function convertToFirestoreMap($data)
    {
        $fields = [];
        foreach ($data as $key => $value) {
            if (is_bool($value)) {
                $fields[$key] = ['booleanValue' => $value];
            } elseif (is_int($value)) {
                $fields[$key] = ['integerValue' => (string)$value];
            } elseif (is_null($value)) {
                $fields[$key] = ['nullValue' => null];
            } else {
                $fields[$key] = ['stringValue' => (string)$value];
            }
        }
        return $fields;
    }

    /**
     * Metni UTF-8'e dönüştür ve temizle
     */
    private function sanitizeText($text)
    {
        if (empty($text)) return '';
        if (!is_string($text)) $text = (string)$text;
        
        $encoding = mb_detect_encoding($text, ['UTF-8', 'ISO-8859-9', 'ISO-8859-1', 'Windows-1254'], true);
        if ($encoding && $encoding !== 'UTF-8') {
            $text = mb_convert_encoding($text, 'UTF-8', $encoding);
        }
        
        $text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', $text);
        $text = preg_replace('/\s+/u', ' ', $text);
        
        return trim($text);
    }

    /**
     * JWT Token oluştur
     */
    private function createJWT()
    {
        if (!$this->serviceAccount) return null;
        
        $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
        $header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
        
        $now = time();
        $payload = json_encode([
            'iss' => $this->serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ]);
        $payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
        
        $signatureInput = $header . '.' . $payload;
        openssl_sign($signatureInput, $signature, $this->serviceAccount['private_key'], 'SHA256');
        $signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
        
        return $header . '.' . $payload . '.' . $signature;
    }

    /**
     * Access Token al
     */
    private function getAccessToken()
    {
        $jwt = $this->createJWT();
        if (!$jwt) return null;
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
        
        $response = curl_exec($ch);
        curl_close($ch);
        
        $data = json_decode($response, true);
        return $data['access_token'] ?? null;
    }
}
