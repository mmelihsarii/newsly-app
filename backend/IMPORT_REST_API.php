<?php
/**
 * Firebase REST API ile import - SDK gerektirmez, memory kullanmaz
 * 
 * routes/web.php'ye ekle (middleware grubunun içine):
 */

Route::get('import-sources-firebase-rest', function() {
    $page = request()->get('page', 1);
    $perPage = 20; // Daha az kaynak
    $offset = ($page - 1) * $perPage;
    
    // Firebase proje ID - değiştir!
    $projectId = 'newsly-app'; // Firebase Console'dan al
    
    $total = \DB::table('rss_sources')->where('status', 1)->count();
    $sources = \DB::table('rss_sources')
        ->where('status', 1)
        ->offset($offset)
        ->limit($perPage)
        ->get();
    
    if ($sources->isEmpty()) {
        return response()->json([
            'success' => true,
            'message' => 'Bitti!',
            'finished' => true
        ]);
    }
    
    $synced = 0;
    $failed = 0;
    $errors = [];
    
    foreach ($sources as $source) {
        $name = $source->name ?? '';
        $url = $source->rss_url ?? $source->url ?? '';
        $cat = $source->category ?? 'Genel';
        
        if (empty($name) || empty($url)) {
            $failed++;
            continue;
        }
        
        $docId = preg_replace('/[^a-z0-9]+/', '_', strtolower(trim($name)));
        $docId = trim($docId, '_');
        
        // Firestore REST API formatı
        $data = [
            'fields' => [
                'category' => ['stringValue' => $cat],
                'id' => ['stringValue' => $docId],
                'is_active' => ['booleanValue' => true],
                'name' => ['stringValue' => $name],
                'rss_url' => ['stringValue' => $url],
            ]
        ];
        
        $apiUrl = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/news_sources/{$docId}";
        
        $ch = curl_init($apiUrl);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode >= 200 && $httpCode < 300) {
            $synced++;
        } else {
            $failed++;
            $errors[] = "$name: HTTP $httpCode";
        }
    }
    
    $hasMore = ($offset + $perPage) < $total;
    
    return response()->json([
        'page' => $page,
        'synced' => $synced,
        'failed' => $failed,
        'processed' => $offset + $sources->count(),
        'total' => $total,
        'hasMore' => $hasMore,
        'nextUrl' => $hasMore ? url('import-sources-firebase-rest?page=' . ($page + 1)) : null,
        'errors' => array_slice($errors, 0, 5)
    ]);
});
