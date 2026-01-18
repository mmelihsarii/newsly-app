# 🔧 Laravel Backend - Hesap Silme Kurulum Adımları

## 📋 Hızlı Kurulum (5 Dakika)

### Adım 1: ApiController.php'yi Aç
```bash
nano app/Http/Controllers/ApiController.php
```

### Adım 2: Import'ları Ekle (Dosyanın Başına)
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\JsonResponse;

class ApiController extends Controller
{
    // ... mevcut kodlar
}
```

### Adım 3: deleteUser Fonksiyonunu Ekle (Class İçine)
```php
/**
 * Kullanıcı hesabını sil (Soft Delete)
 * 
 * @param Request $request
 * @return JsonResponse
 */
public function deleteUser(Request $request)
{
    try {
        // Validasyon
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => true,
                'message' => 'user_id parametresi gereklidir',
                'data' => null
            ], 400);
        }

        $userId = $request->input('user_id');

        // Kullanıcıyı bul (ID veya Firebase UID ile)
        $user = DB::table('tbl_users')
            ->where('id', $userId)
            ->orWhere('firebase_uid', $userId)
            ->first();

        if (!$user) {
            return response()->json([
                'error' => true,
                'message' => 'Kullanıcı bulunamadı',
                'data' => null
            ], 404);
        }

        // Soft Delete - status'u 0 yap
        DB::table('tbl_users')
            ->where('id', $user->id)
            ->update([
                'status' => 0,
                'deleted_at' => now(),
                'updated_at' => now()
            ]);

        // Log kaydı
        Log::info('User account deleted (soft delete)', [
            'user_id' => $user->id,
            'email' => $user->email,
            'deleted_at' => now()
        ]);

        return response()->json([
            'error' => false,
            'message' => 'Hesap başarıyla silindi',
            'data' => [
                'user_id' => $user->id,
                'deleted_at' => now()->toDateTimeString()
            ]
        ], 200);

    } catch (\Exception $e) {
        Log::error('Delete user error: ' . $e->getMessage());
        
        return response()->json([
            'error' => true,
            'message' => 'Hesap silinirken bir hata oluştu: ' . $e->getMessage(),
            'data' => null
        ], 500);
    }
}
```

### Adım 4: Route Ekle
```bash
nano routes/api.php
```

Dosyanın sonuna ekle:
```php
// Hesap silme endpoint'i
Route::post('delete_user', [ApiController::class, 'deleteUser']);
```

### Adım 5: Migration Oluştur (Opsiyonel)
Eğer `deleted_at` kolonu yoksa:

```bash
php artisan make:migration add_deleted_at_to_tbl_users
```

Migration dosyasını düzenle:
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            $table->timestamp('deleted_at')->nullable()->after('updated_at');
        });
    }

    public function down()
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            $table->dropColumn('deleted_at');
        });
    }
};
```

Çalıştır:
```bash
php artisan migrate
```

### Adım 6: Test Et
```bash
curl -X POST https://admin.newsly.com.tr/api/delete_user \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test_user_firebase_uid"}'
```

Beklenen yanıt:
```json
{
  "error": false,
  "message": "Hesap başarıyla silindi",
  "data": {
    "user_id": "123",
    "deleted_at": "2026-01-17 12:00:00"
  }
}
```

---

## 🔍 Veritabanı Kontrolü

### Silinen Kullanıcıları Görüntüle
```sql
SELECT id, email, status, deleted_at 
FROM tbl_users 
WHERE status = 0;
```

### Kullanıcıyı Geri Getir (Admin İşlemi)
```sql
UPDATE tbl_users 
SET status = 1, deleted_at = NULL, updated_at = NOW()
WHERE id = 123;
```

### Tamamen Sil (Hard Delete - Dikkatli!)
```sql
DELETE FROM tbl_users WHERE id = 123;
```

---

## 🛡️ Güvenlik Önerileri

### 1. Auth Middleware Ekle (Önerilen)
```php
Route::middleware('auth:sanctum')->post('delete_user', [ApiController::class, 'deleteUser']);
```

### 2. Rate Limiting Ekle
```php
Route::middleware(['throttle:5,1'])->post('delete_user', [ApiController::class, 'deleteUser']);
```

### 3. IP Whitelist (Opsiyonel)
```php
Route::middleware(['ip.whitelist'])->post('delete_user', [ApiController::class, 'deleteUser']);
```

---

## 📊 İlişkili Verileri Silme (Opsiyonel)

Kullanıcının diğer verilerini de silmek isterseniz:

```php
// Kaydedilmiş haberleri sil
DB::table('tbl_user_saved_news')->where('user_id', $user->id)->delete();

// Takip edilen kategorileri sil
DB::table('tbl_user_followed_categories')->where('user_id', $user->id)->delete();

// Takip edilen kaynakları sil
DB::table('tbl_user_followed_sources')->where('user_id', $user->id)->delete();

// Bildirimleri sil
DB::table('tbl_user_notifications')->where('user_id', $user->id)->delete();

// Yorumları sil
DB::table('tbl_user_comments')->where('user_id', $user->id)->delete();
```

Veya hepsini tek seferde:
```php
// İlişkili tüm verileri sil
$tables = [
    'tbl_user_saved_news',
    'tbl_user_followed_categories',
    'tbl_user_followed_sources',
    'tbl_user_notifications',
    'tbl_user_comments'
];

foreach ($tables as $table) {
    DB::table($table)->where('user_id', $user->id)->delete();
}
```

---

## 🔧 Alternatif Yaklaşımlar

### Yaklaşım 1: Eloquent Model Kullanımı
```php
use App\Models\User;

public function deleteUser(Request $request)
{
    $user = User::where('firebase_uid', $request->user_id)->first();
    
    if (!$user) {
        return response()->json(['error' => true, 'message' => 'Kullanıcı bulunamadı']);
    }
    
    $user->status = 0;
    $user->deleted_at = now();
    $user->save();
    
    return response()->json(['error' => false, 'message' => 'Hesap silindi']);
}
```

### Yaklaşım 2: Soft Delete Trait Kullanımı
```php
// User Model'de
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Model
{
    use SoftDeletes;
    
    protected $table = 'tbl_users';
}

// Controller'da
public function deleteUser(Request $request)
{
    $user = User::where('firebase_uid', $request->user_id)->first();
    $user->delete(); // Otomatik soft delete
    
    return response()->json(['error' => false, 'message' => 'Hesap silindi']);
}
```

---

## 📝 Log Dosyası Kontrolü

### Log'ları Görüntüle
```bash
tail -f storage/logs/laravel.log
```

### Silme İşlemi Log Örneği
```
[2026-01-17 12:00:00] local.INFO: User account deleted (soft delete) {"user_id":123,"email":"user@example.com","deleted_at":"2026-01-17 12:00:00"}
```

---

## 🚨 Sorun Giderme

### Hata: "user_id parametresi gereklidir"
**Çözüm:** POST body'de `user_id` gönderildiğinden emin olun.

### Hata: "Kullanıcı bulunamadı"
**Çözüm:** 
- Firebase UID'nin doğru gönderildiğini kontrol edin
- Veritabanında `firebase_uid` kolonunun olduğunu kontrol edin

### Hata: "Column 'deleted_at' not found"
**Çözüm:** Migration'ı çalıştırın veya kolonu manuel ekleyin:
```sql
ALTER TABLE tbl_users ADD COLUMN deleted_at TIMESTAMP NULL AFTER updated_at;
```

### Hata: "Class 'Validator' not found"
**Çözüm:** Import'u ekleyin:
```php
use Illuminate\Support\Facades\Validator;
```

---

## ✅ Kurulum Kontrol Listesi

- [ ] ApiController.php'ye import'lar eklendi
- [ ] deleteUser() fonksiyonu eklendi
- [ ] routes/api.php'ye route eklendi
- [ ] deleted_at kolonu eklendi (opsiyonel)
- [ ] Postman/cURL ile test edildi
- [ ] Log dosyası kontrol edildi
- [ ] Veritabanında status = 0 olduğu görüldü
- [ ] Flutter uygulamasından test edildi

---

## 📞 Destek

Sorun yaşarsanız:
1. `storage/logs/laravel.log` dosyasını kontrol edin
2. `php artisan route:list` ile route'un eklendiğini doğrulayın
3. Postman ile manuel test yapın
4. Database'de `tbl_users` tablosunu kontrol edin

---

**Kurulum Süresi:** ~5 dakika  
**Zorluk Seviyesi:** Kolay  
**Gereksinimler:** Laravel 8+, PHP 7.4+
