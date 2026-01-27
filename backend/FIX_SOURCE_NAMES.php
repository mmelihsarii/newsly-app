<?php
/**
 * Firestore'daki news_sources koleksiyonunda kaynak isimlerini düzeltme scripti
 * 
 * Bu script, aynı isimle kaydedilmiş kaynakların name alanlarını benzersiz hale getirir.
 * 
 * KULLANIM:
 * 1. Bu dosyayı Laravel projenizin içine koyun (örn: /home/newslyco/public_html/admin/)
 * 2. Tarayıcıdan çalıştırın veya CLI'dan: php FIX_SOURCE_NAMES.php
 * 
 * NOT: Çalıştırmadan önce $sourceNameMap dizisini kendi kaynaklarınıza göre düzenleyin!
 */

// Laravel bootstrap (eğer Laravel içinde çalıştırıyorsanız)
// require __DIR__ . '/vendor/autoload.php';
// $app = require_once __DIR__ . '/bootstrap/app.php';

// Firebase ayarları
$projectId = 'newsly-70ef9';
$firebaseJsonPath = '/home/newslyco/public_html/admin/storage/firebase-ayar.json';

// =====================================================
// DÜZELTME HARİTASI - KENDİ KAYNAKLARINIZA GÖRE DÜZENLEYİN
// =====================================================
// Format: 'document_id' => 'Yeni Görünen İsim'
$sourceNameMap = [
    // Sözcü kaynakları
    'sozcu' => 'Sözcü',
    'sozcuekonomi' => 'Sözcü Ekonomi',
    'sozcuspor' => 'Sözcü Spor',
    'sozcusondakika' => 'Sözcü Son Dakika',
    
    // Hürriyet kaynakları (örnek)
    'hurriyet' => 'Hürriyet',
    'hurriyetspor' => 'Hürriyet Spor',
    'hurriyetekonomi' => 'Hürriyet Ekonomi',
    
    // Milliyet kaynakları (örnek)
    'milliyet' => 'Milliyet',
    'milliyetspor' => 'Milliyet Spor',
    'milliyetekonomi' => 'Milliyet Ekonomi',
    
    // Sabah kaynakları (örnek)
    'sabah' => 'Sabah',
    'sabahspor' => 'Sabah Spor',
    'sabahekonomi' => 'Sabah Ekonomi',
    
    // Diğer kaynakları buraya ekleyin...
];

// =====================================================
// FONKSİYONLAR
// =====================================================

/**
 * Firebase Access Token al
 */
function getFirebaseAccessToken($jsonPath) {
    if (!file_exists($jsonPath)) {
        throw new Exception("Firebase JSON dosyası bulunamadı: $jsonPath");
    }
    
    $serviceAccount = json_decode(file_get_contents($jsonPath), true);
    
    if (!$serviceAccount || !isset($serviceAccount['private_key'])) {
        throw new Exception("Geçersiz Firebase JSON dosyası");
    }
    
    // JWT oluştur
    $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    
    $now = time();
    $payload = base64_encode(json_encode([
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/datastore',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600,
    ]));
    
    $signatureInput = str_replace(['+', '/', '='], ['-', '_', ''], $header) . '.' . 
                      str_replace(['+', '/', '='], ['-', '_', ''], $payload);
    
    $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
    openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
    
    $jwt = $signatureInput . '.' . str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    // Token al
    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]),
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Token alma hatası: $response");
    }
    
    $data = json_decode($response, true);
    return $data['access_token'];
}

/**
 * Firestore'dan tüm kaynakları getir
 */
function getAllSources($projectId, $accessToken) {
    $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/news_sources";
    
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            "Authorization: Bearer $accessToken",
            "Content-Type: application/json",
        ],
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Kaynak listesi alma hatası: $response");
    }
    
    $data = json_decode($response, true);
    return $data['documents'] ?? [];
}

/**
 * Firestore'da kaynak ismini güncelle
 */
function updateSourceName($projectId, $accessToken, $documentId, $newName) {
    $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/news_sources/{$documentId}?updateMask.fieldPaths=name";
    
    $data = [
        'fields' => [
            'name' => ['stringValue' => $newName],
        ],
    ];
    
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => 'PATCH',
        CURLOPT_POSTFIELDS => json_encode($data),
        CURLOPT_HTTPHEADER => [
            "Authorization: Bearer $accessToken",
            "Content-Type: application/json",
        ],
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return $httpCode === 200;
}

// =====================================================
// ANA İŞLEM
// =====================================================

header('Content-Type: text/html; charset=utf-8');
echo "<h1>🔧 Firestore Kaynak İsmi Düzeltme</h1>";
echo "<pre>";

try {
    // 1. Token al
    echo "📝 Firebase token alınıyor...\n";
    $accessToken = getFirebaseAccessToken($firebaseJsonPath);
    echo "✅ Token alındı\n\n";
    
    // 2. Mevcut kaynakları listele
    echo "📋 Mevcut kaynaklar listeleniyor...\n";
    $sources = getAllSources($projectId, $accessToken);
    echo "📊 Toplam " . count($sources) . " kaynak bulundu\n\n";
    
    // 3. Mevcut durumu göster
    echo "=== MEVCUT DURUM ===\n";
    $duplicateNames = [];
    foreach ($sources as $doc) {
        $docPath = $doc['name'];
        $docId = basename($docPath);
        $currentName = $doc['fields']['name']['stringValue'] ?? 'İsimsiz';
        
        echo "📄 $docId => \"$currentName\"\n";
        
        // Tekrar eden isimleri bul
        if (!isset($duplicateNames[$currentName])) {
            $duplicateNames[$currentName] = [];
        }
        $duplicateNames[$currentName][] = $docId;
    }
    
    // 4. Tekrar edenleri göster
    echo "\n=== TEKRAR EDEN İSİMLER ===\n";
    $hasDuplicates = false;
    foreach ($duplicateNames as $name => $ids) {
        if (count($ids) > 1) {
            $hasDuplicates = true;
            echo "⚠️ \"$name\" ismi " . count($ids) . " kez kullanılmış: " . implode(', ', $ids) . "\n";
        }
    }
    
    if (!$hasDuplicates) {
        echo "✅ Tekrar eden isim yok!\n";
    }
    
    // 5. Düzeltmeleri uygula
    echo "\n=== DÜZELTMELER UYGULANACAK ===\n";
    $updated = 0;
    $skipped = 0;
    
    foreach ($sources as $doc) {
        $docPath = $doc['name'];
        $docId = basename($docPath);
        $currentName = $doc['fields']['name']['stringValue'] ?? '';
        
        // Haritada varsa güncelle
        if (isset($sourceNameMap[$docId])) {
            $newName = $sourceNameMap[$docId];
            
            if ($currentName !== $newName) {
                echo "🔄 $docId: \"$currentName\" => \"$newName\"... ";
                
                if (updateSourceName($projectId, $accessToken, $docId, $newName)) {
                    echo "✅\n";
                    $updated++;
                } else {
                    echo "❌ HATA\n";
                }
            } else {
                echo "⏭️ $docId: Zaten doğru (\"$currentName\")\n";
                $skipped++;
            }
        }
    }
    
    echo "\n=== SONUÇ ===\n";
    echo "✅ Güncellenen: $updated\n";
    echo "⏭️ Atlanan: $skipped\n";
    echo "📊 Toplam: " . count($sources) . "\n";
    
    echo "\n💡 İPUCU: Haritada olmayan kaynaklar için \$sourceNameMap dizisine ekleyin.\n";
    
} catch (Exception $e) {
    echo "❌ HATA: " . $e->getMessage() . "\n";
}

echo "</pre>";
?>
