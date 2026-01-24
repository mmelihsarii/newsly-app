<?php
/**
 * Basit Bildirim Controller
 * 
 * Bu dosyayı kopyala:
 * /home/newslyco/public_html/admin/app/Http/Controllers/SimpleNotificationController.php
 * 
 * Route ekle (web.php):
 * Route::get('/simple-notification', [SimpleNotificationController::class, 'index'])->name('simple-notification');
 * Route::post('/simple-notification/send', [SimpleNotificationController::class, 'send'])->name('simple-notification.send');
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class SimpleNotificationController extends Controller
{
    public function index()
    {
        return view('simple-notification');
    }
    
    public function send(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:100',
            'body' => 'required|string|max:500',
        ]);
        
        $title = $request->input('title');
        $body = $request->input('body');
        $topic = $request->input('topic', 'Turkish');
        
        try {
            // Firebase config - panelin kullandığı dosya
            $configPath = public_path('assets/firebase_config.json');
            
            if (!file_exists($configPath)) {
                return back()->with('error', 'Firebase config dosyası bulunamadı: assets/firebase_config.json');
            }
            
            $firebase = (new Factory())->withServiceAccount($configPath);
            $messaging = $firebase->createMessaging();
            
            // Notification oluştur
            $notification = Notification::create($title, $body);
            
            // Topic'e gönder
            $message = CloudMessage::withTarget('topic', $topic)
                ->withNotification($notification)
                ->withData([
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'type' => 'manual',
                    'title' => $title,
                    'body' => $body,
                ]);
            
            $result = $messaging->send($message);
            
            \Log::info('Basit bildirim gönderildi', [
                'topic' => $topic,
                'title' => $title,
                'result' => $result
            ]);
            
            return back()->with('success', "Bildirim başarıyla gönderildi! ✅ (Topic: $topic)");
            
        } catch (\Exception $e) {
            \Log::error('Bildirim hatası: ' . $e->getMessage());
            return back()->with('error', 'Hata: ' . $e->getMessage());
        }
    }
}
