<?php
/**
 * Bildirim Gönderme Controller
 * 
 * Bu dosyayı Laravel projesine kopyala:
 * app/Http/Controllers/NotificationController.php
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    // Firebase proje bilgileri
    private $projectId = 'newsly-70ef9';
    private $serviceAccountPath = '/home/newslyco/firebase-service-account.json';
    
    /**
     * Bildirim gönderme sayfası
     */
    public function index()
    {
        return view('notification');
    }
    
    /**
     * Bildirim gönder
     */
    public function send(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:100',
            'body' => 'required|string|max:500',
        ]);
        
        $title = $request->input('title');
        $body = $request->input('body');
        $url = $request->input('url', '');
        
        try {
            // Access token al
            $accessToken = $this->getAccessToken();
            
            if (!$accessToken) {
                return back()->with('error', 'Firebase bağlantı hatası. Service account dosyasını kontrol edin.');
            }
            
            // FCM API'ye gönder - SADECE newsly_important topic'ine
            // Bu topic'e sadece bu panelden bildirim gider
            // Otomatik bildirimler farklı topic kullanır, Flutter onları filtreler
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $accessToken,
                'Content-Type' => 'application/json',
            ])->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'message' => [
                    'topic' => 'newsly_important', // Özel topic - spam olmaz
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => [
                        'url' => $url,
                        'type' => 'manual',      // Flutter bu değeri kontrol eder
                        'priority' => 'high',    // Yüksek öncelik
                        'source' => 'admin_panel', // Kaynak bilgisi
                    ],
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'channel_id' => 'important_news',
                            'sound' => 'default',
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
            ]);
            
            $responseData = $response->json();
            $statusCode = $response->status();
            
            Log::info('FCM Response', [
                'status' => $statusCode,
                'body' => $response->body(),
                'json' => $responseData,
            ]);
            
            if ($response->successful()) {
                $messageId = $responseData['name'] ?? 'unknown';
                
                Log::info('Bildirim gönderildi', [
                    'title' => $title,
                    'body' => $body,
                    'message_id' => $messageId,
                ]);
                
                return back()->with('success', "Bildirim başarıyla gönderildi! ✅ (ID: $messageId)");
            } else {
                $errorMsg = $responseData['error']['message'] ?? $response->body();
                
                Log::error('Bildirim hatası', [
                    'status' => $statusCode,
                    'error' => $errorMsg,
                    'full_response' => $response->body(),
                ]);
                
                return back()->with('error', "Bildirim gönderilemedi (HTTP $statusCode): $errorMsg");
            }
            
        } catch (\Exception $e) {
            Log::error('Bildirim exception', ['error' => $e->getMessage()]);
            return back()->with('error', 'Hata: ' . $e->getMessage());
        }
    }
    
    /**
     * Firebase Access Token al (Service Account ile)
     */
    private function getAccessToken()
    {
        try {
            if (!file_exists($this->serviceAccountPath)) {
                Log::error('Service account dosyası bulunamadı: ' . $this->serviceAccountPath);
                return null;
            }
            
            $serviceAccount = json_decode(file_get_contents($this->serviceAccountPath), true);
            
            // JWT Header
            $header = $this->base64UrlEncode(json_encode([
                'alg' => 'RS256',
                'typ' => 'JWT'
            ]));
            
            // JWT Payload
            $now = time();
            $payload = $this->base64UrlEncode(json_encode([
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));
            
            // İmzala
            $signature = '';
            $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
            openssl_sign("$header.$payload", $signature, $privateKey, OPENSSL_ALGO_SHA256);
            $signature = $this->base64UrlEncode($signature);
            
            $jwt = "$header.$payload.$signature";
            
            // Token al
            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);
            
            if ($response->successful()) {
                return $response->json()['access_token'];
            }
            
            Log::error('Token alma hatası', ['response' => $response->body()]);
            return null;
            
        } catch (\Exception $e) {
            Log::error('Token exception', ['error' => $e->getMessage()]);
            return null;
        }
    }
    
    /**
     * URL-safe Base64 encode
     */
    private function base64UrlEncode($data)
    {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }
}
