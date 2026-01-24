# 🔔 Laravel Admin Panel - Bildirim Gönderme Kurulumu

Admin panelden tüm kullanıcılara bildirim göndermek için kurulum rehberi.

---

## 📁 Dosya Yapısı

```
app/
├── Http/Controllers/
│   └── NotificationController.php    # YENİ
resources/views/
├── notification.blade.php            # YENİ
routes/
└── web.php                           # Güncelle
```

---

## ADIM 1: Firebase Service Account Key

1. Firebase Console > Project Settings > Service Accounts
2. "Generate new private key" tıkla
3. JSON dosyasını indir
4. Sunucuya yükle: `/home/newslyco/firebase-service-account.json`
5. Dosya izinlerini ayarla: `chmod 600 firebase-service-account.json`

---

## ADIM 2: NotificationController.php Oluştur

`app/Http/Controllers/NotificationController.php`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

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
            
            // FCM API'ye gönder
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $accessToken,
                'Content-Type' => 'application/json',
            ])->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'message' => [
                    'topic' => 'all_users',
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => [
                        'url' => $url,
                        'type' => 'manual',
                    ],
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'channel_id' => 'default',
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
            
            if ($response->successful()) {
                // Başarılı - log kaydet
                \Log::info('Bildirim gönderildi', [
                    'title' => $title,
                    'body' => $body,
                    'response' => $response->json(),
                ]);
                
                return back()->with('success', 'Bildirim başarıyla gönderildi!');
            } else {
                \Log::error('Bildirim hatası', [
                    'response' => $response->body(),
                ]);
                
                return back()->with('error', 'Bildirim gönderilemedi: ' . $response->body());
            }
            
        } catch (\Exception $e) {
            \Log::error('Bildirim exception', ['error' => $e->getMessage()]);
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
                \Log::error('Service account dosyası bulunamadı: ' . $this->serviceAccountPath);
                return null;
            }
            
            $serviceAccount = json_decode(file_get_contents($this->serviceAccountPath), true);
            
            // JWT oluştur
            $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            
            $now = time();
            $payload = base64_encode(json_encode([
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
            $signature = base64_encode($signature);
            
            // URL-safe base64
            $jwt = str_replace(['+', '/', '='], ['-', '_', ''], "$header.$payload.$signature");
            
            // Token al
            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);
            
            if ($response->successful()) {
                return $response->json()['access_token'];
            }
            
            \Log::error('Token alma hatası', ['response' => $response->body()]);
            return null;
            
        } catch (\Exception $e) {
            \Log::error('Token exception', ['error' => $e->getMessage()]);
            return null;
        }
    }
}
```

---

## ADIM 3: View Dosyası Oluştur

`resources/views/notification.blade.php`:

```blade
@extends('layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-md-8 offset-md-2">
            <div class="card">
                <div class="card-header">
                    <h4><i class="fas fa-bell"></i> Bildirim Gönder</h4>
                </div>
                <div class="card-body">
                    
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show">
                            <i class="fas fa-check-circle"></i> {{ session('success') }}
                            <button type="button" class="close" data-dismiss="alert">&times;</button>
                        </div>
                    @endif
                    
                    @if(session('error'))
                        <div class="alert alert-danger alert-dismissible fade show">
                            <i class="fas fa-exclamation-circle"></i> {{ session('error') }}
                            <button type="button" class="close" data-dismiss="alert">&times;</button>
                        </div>
                    @endif
                    
                    <form action="{{ route('notification.send') }}" method="POST">
                        @csrf
                        
                        <div class="form-group">
                            <label for="title"><strong>Başlık</strong></label>
                            <input type="text" 
                                   name="title" 
                                   id="title" 
                                   class="form-control @error('title') is-invalid @enderror" 
                                   placeholder="🔴 Son Dakika"
                                   value="{{ old('title') }}"
                                   maxlength="100"
                                   required>
                            @error('title')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            <small class="text-muted">Maksimum 100 karakter</small>
                        </div>
                        
                        <div class="form-group">
                            <label for="body"><strong>Mesaj</strong></label>
                            <textarea name="body" 
                                      id="body" 
                                      class="form-control @error('body') is-invalid @enderror" 
                                      rows="4"
                                      placeholder="Bildirim mesajınızı yazın..."
                                      maxlength="500"
                                      required>{{ old('body') }}</textarea>
                            @error('body')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            <small class="text-muted">Maksimum 500 karakter</small>
                        </div>
                        
                        <div class="form-group">
                            <label for="url"><strong>Haber Linki</strong> (Opsiyonel)</label>
                            <input type="url" 
                                   name="url" 
                                   id="url" 
                                   class="form-control" 
                                   placeholder="https://..."
                                   value="{{ old('url') }}">
                            <small class="text-muted">Kullanıcı bildirime tıklayınca bu sayfaya yönlendirilir</small>
                        </div>
                        
                        <hr>
                        
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle"></i>
                            <strong>Not:</strong> Bu bildirim tüm uygulama kullanıcılarına gönderilecektir.
                        </div>
                        
                        <button type="submit" class="btn btn-primary btn-lg btn-block">
                            <i class="fas fa-paper-plane"></i> Bildirim Gönder
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
```

---

## ADIM 4: Route Ekle

`routes/web.php` dosyasına ekle:

```php
// Bildirim gönderme
Route::get('/notification', [App\Http\Controllers\NotificationController::class, 'index'])->name('notification.index');
Route::post('/notification/send', [App\Http\Controllers\NotificationController::class, 'send'])->name('notification.send');
```

---

## ADIM 5: Menüye Ekle (Opsiyonel)

Admin panel menüsüne "Bildirim Gönder" linki ekle:

```html
<li class="nav-item">
    <a href="{{ route('notification.index') }}" class="nav-link">
        <i class="nav-icon fas fa-bell"></i>
        <p>Bildirim Gönder</p>
    </a>
</li>
```

---

## 📱 Flutter Tarafı

Flutter uygulamasında `all_users` topic'ine abone olmak gerekiyor. `notification_service.dart`'ı güncelle:

```dart
// _unsubscribeFromAllTopics yerine sadece all_users'a abone ol
Future<void> _subscribeToAllUsers() async {
  try {
    await _messaging.subscribeToTopic('all_users');
    print('✅ all_users topic\'ine abone olundu');
  } catch (e) {
    print('Topic abonelik hatası: $e');
  }
}
```

---

## ✅ Test

1. Admin panele giriş yap
2. `/notification` sayfasına git
3. Başlık ve mesaj yaz
4. "Bildirim Gönder" tıkla
5. Uygulamada bildirim geldiğini kontrol et

---

## 🔒 Güvenlik

- Service account JSON dosyasını public klasöre KOYMA
- Dosya izinlerini kısıtla: `chmod 600`
- Route'ları auth middleware ile koru
