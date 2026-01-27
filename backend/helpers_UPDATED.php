<?php

use App\Models\Language;
use App\Models\Location;
use App\Models\Settings;
use App\Models\Token;
use App\Models\WebSetting;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Kreait\Firebase\Messaging\CloudMessage;
use Intervention\Image\Laravel\Facades\Image;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

if (!function_exists('get_meta_keyword')) {
    function get_meta_keyword($meta_keyword)
    {
        $meta_keyword1 = '';
        if ($meta_keyword) {
            $meta_keyword1 = implode(',', array_map(function ($tag) {
                return $tag['value'];
            }, $meta_keyword));
        }
        return $meta_keyword1;
    }
}

/** Generate Slugs Functions */
if (!function_exists('generateUniqueSlug')) {
    function generateUniqueSlug($title, $originalSlug = null, $exceptId = null)
    {
        if (!$originalSlug) {
            $originalSlug = Str::slug($title);
        } else {
            $originalSlug = Str::slug($originalSlug);
        }

        if (empty($originalSlug)) {
            $originalSlug = "slug";
        }

        return $originalSlug;
    }
}

if (!function_exists('customSlug')) {
    function customSlug($string, $separator = '-')
    {
        $normalizedString = mb_strtolower(trim($string), 'UTF-8');

        if (preg_match('/^[\x00-\x7F]*$/', $normalizedString)) {
            $slug = preg_replace('/[^a-z0-9]+/', $separator, $normalizedString);
        } else {
            $slug = preg_replace('/\s+/', $separator, $string);
        }

        return $slug;
    }
}

if (!function_exists('getSetting')) {
    function getSetting($type = '')
    {
        $settingList = [];
        if ($type == '') {
            $setting = Settings::get();
        } else {
            $setting = Settings::where('type', $type)->get();
        }

        foreach ($setting as $row) {
            $settingList[$row->type] = $row->message;
        }

        return $settingList;
    }
}

if (!function_exists('getSettingMode')) {
    function getSettingMode($type)
    {
        return Settings::where('type', $type)->pluck('message')->first();
    }
}

if (!function_exists('getWebSetting')) {
    function getWebSetting($type = '')
    {
        $settingList = [];
        if ($type == '') {
            $setting = WebSetting::get();
        } else {
            $setting = WebSetting::where('type', $type)->get();
        }

        foreach ($setting as $row) {
            $settingList[$row->type] = $row->message;
        }

        return $settingList;
    }
}

// =====================================================
// FCM HTTP v1 API - BİLDİRİM FONKSİYONLARI
// =====================================================

if (!function_exists('send_notification')) {
    function send_notification($fcmMsg, $language_id = null, $location_id = null, $tokens = null)
    {
        try {
            $serviceAccountPath = public_path('assets/firebase_config.json');
            if (!file_exists($serviceAccountPath)) {
                \Log::error('Service account dosyası bulunamadı');
                return false;
            }

            $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            $projectId = $serviceAccount['project_id'] ?? null;

            if (empty($projectId)) {
                \Log::error('Project ID bulunamadı');
                return false;
            }

            $accessToken = getFirebaseAccessToken($serviceAccount);
            if (empty($accessToken)) {
                \Log::error('Access token alınamadı');
                return false;
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            $headers = [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json'
            ];

            $notification = [
                'title' => $fcmMsg['title'] ?? '',
                'body' => $fcmMsg['body'] ?? $fcmMsg['message'] ?? '',
            ];

            if (!empty($fcmMsg['image'])) {
                $notification['image'] = $fcmMsg['image'];
            }

            $data = [];
            foreach ($fcmMsg as $key => $value) {
                $data[$key] = (string) $value;
            }
            $data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';

            $category_id = $fcmMsg['category_id'] ?? 0;
            $type = $fcmMsg['type'] ?? 'default';

            if ($type == 'category' && $category_id > 0) {
                $topic = 'category_' . $category_id;
            } else {
                $topic = 'Turkish';
            }

            $message = [
                'message' => [
                    'topic' => $topic,
                    'notification' => $notification,
                    'data' => $data,
                    'android' => [
                        'priority' => 'high',
                        'collapse_key' => 'notification_' . time() . '_' . rand(1000, 9999),
                        'notification' => [
                            'sound' => 'default',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                            'icon' => 'ic_stat_notification',
                            'color' => '#F4220B',
                            'channel_id' => 'high_importance_channel',
                            'tag' => 'newsly_' . time() . '_' . rand(1000, 9999),
                        ]
                    ],
                    // ===== iOS APNS - TAM YAPILANDIRMA =====
                    'apns' => [
                        'headers' => [
                            'apns-priority' => '10',
                            'apns-push-type' => 'alert',
                        ],
                        'payload' => [
                            'aps' => [
                                'alert' => [
                                    'title' => $notification['title'],
                                    'body' => $notification['body'],
                                ],
                                'sound' => 'default',
                                'badge' => 1,
                                'content-available' => 1,
                                'mutable-content' => 1,
                            ],
                            // Data payload'ı iOS için de ekle
                            'news_id' => $data['news_id'] ?? '',
                            'type' => $data['type'] ?? 'default',
                            'category_id' => $data['category_id'] ?? '',
                            'image' => $data['image'] ?? '',
                        ],
                        'fcm_options' => [
                            'image' => $notification['image'] ?? '',
                        ]
                    ]
                ]
            ];

            if (!empty($tokens) && is_array($tokens)) {
                $success = true;
                foreach ($tokens as $token) {
                    // Her token için benzersiz tag oluştur
                    $uniqueTag = 'newsly_' . time() . '_' . rand(1000, 9999);
                    $message['message']['android']['collapse_key'] = 'notification_' . time() . '_' . rand(1000, 9999);
                    $message['message']['android']['notification']['tag'] = $uniqueTag;
                    $message['message']['token'] = $token;
                    unset($message['message']['topic']);
                    $result = sendFcmRequest($url, $headers, $message);
                    if (!$result) $success = false;
                }
                return $success;
            }

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
            $expiry = $now + 3600;

            $header = [
                'alg' => 'RS256',
                'typ' => 'JWT'
            ];

            $payload = [
                'iss' => $serviceAccount['client_email'],
                'sub' => $serviceAccount['client_email'],
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $expiry,
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging'
            ];

            $base64Header = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
            $base64Payload = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');

            $signatureInput = $base64Header . '.' . $base64Payload;
            $privateKey = $serviceAccount['private_key'];

            openssl_sign($signatureInput, $signature, $privateKey, 'SHA256');
            $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

            $jwt = $signatureInput . '.' . $base64Signature;

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

// =====================================================
// DİĞER HELPER FONKSİYONLARI
// =====================================================

if (!function_exists('page_type')) {
    function page_type($type)
    {
        $values = [
            'home' => 'Home',
            'video_news' => 'Video News',
            'personal_notifications' => 'Personal notifications',
            'all_breaking_news' => 'All Breaking News',
            'live_streaming_news' => 'Live streaming news',
            'rss_feeds' => 'RSS Feed'
        ];
        return $values[$type] ?? '';
    }
}

if (!function_exists('is_category_enabled')) {
    function is_category_enabled()
    {
        return Settings::where('type', 'category_mode')->pluck('message')->first();
    }
}

if (!function_exists('is_subcategory_enabled')) {
    function is_subcategory_enabled()
    {
        return Settings::where('type', 'subcategory_mode')->pluck('message')->first();
    }
}

if (!function_exists('is_breaking_news_enabled')) {
    function is_breaking_news_enabled()
    {
        $setting = Settings::where('type', 'breaking_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_auto_news_expire_news_enabled')) {
    function is_auto_news_expire_news_enabled()
    {
        $setting = Settings::where('type', 'auto_delete_expire_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_live_streaming_enabled')) {
    function is_live_streaming_enabled()
    {
        $setting = Settings::where('type', 'live_streaming_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_location_news_enabled')) {
    function is_location_news_enabled()
    {
        $setting = Settings::where('type', 'location_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('getTimezoneOptions')) {
    function getTimezoneOptions()
    {
        $list = DateTimeZone::listAbbreviations();
        $idents = DateTimeZone::listIdentifiers();

        $data = $offset = $added = [];
        foreach ($list as $info) {
            foreach ($info as $zone) {
                if (!empty($zone['timezone_id']) && !in_array($zone['timezone_id'], $added) && in_array($zone['timezone_id'], $idents)) {
                    $z = new DateTimeZone($zone['timezone_id']);
                    $c = new DateTime();
                    $c->setTimezone($z);
                    $zone['time'] = $c->format('H:i a');
                    $offset[] = $zone['offset'] = $z->getOffset($c);
                    $data[] = $zone;
                    $added[] = $zone['timezone_id'];
                }
            }
        }

        array_multisort($offset, SORT_ASC, $data);

        $options = [];
        foreach ($data as $row) {
            $options[] = [
                'time' => $row['time'],
                'offset' => formatOffset($row['offset']),
                'timezone_id' => $row['timezone_id'],
            ];
        }

        return $options;
    }
}

if (!function_exists('formatOffset')) {
    function formatOffset($offset)
    {
        $hours = floor($offset / 3600);
        $minutes = abs(($offset % 3600) / 60);
        return sprintf('%+d:%02d', $hours, $minutes);
    }
}

if (!function_exists('generateRandomString')) {
    function generateRandomString($length = 10)
    {
        return substr(str_shuffle(str_repeat($x = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ceil($length / strlen($x)))), 1, $length);
    }
}

if (!function_exists('is_email_setting')) {
    function is_email_setting()
    {
        $builder = new Settings();
        $email_setting = new \stdClass();
        $email_setting->SMTPHost = $builder->where('type', 'smtp_host')->first()->message;
        $email_setting->SMTPUser = $builder->where('type', 'smtp_user')->first()->message;
        $email_setting->SMTPPass = $builder->where('type', 'smtp_password')->first()->message;
        $email_setting->SMTPPort = $builder->where('type', 'smtp_port')->first()->message;
        $email_setting->SMTPCrypto = $builder->where('type', 'smtp_crypto')->first()->message;
        $email_setting->fromName = $builder->where('type', 'from_name')->first()->message;
        $email_setting->mailType = 'html';
        return $email_setting;
    }
}

if (!function_exists('createSlug')) {
    function createSlug($text)
    {
        $slug = str_replace(' ', '-', strtolower($text));
        $slug = preg_replace('/[^A-Za-z0-9\-]/', '', $slug);
        return $slug . '-' . rand(1, 100);
    }
}

if (!function_exists('get_language')) {
    function get_language($status = '')
    {
        if ($status) {
            return Language::where('status', $status)->get();
        } else {
            return Language::get();
        }
    }
}

if (!function_exists('get_default_language')) {
    function get_default_language()
    {
        $language = '';
        $setting = getSetting('default_language');
        if (!empty($setting)) {
            $language = Language::where('id', $setting['default_language'])->first();
        }
        return $language;
    }
}

if (!function_exists('calculateDistance')) {
    function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $lat1 = deg2rad($lat1);
        $lon1 = deg2rad($lon1);
        $lat2 = deg2rad($lat2);
        $lon2 = deg2rad($lon2);

        $earthRadius = 6371;

        $dlat = $lat2 - $lat1;
        $dlon = $lon2 - $lon1;

        $a = sin($dlat / 2) * sin($dlat / 2) + cos($lat1) * cos($lat2) * sin($dlon / 2) * sin($dlon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}

if (!function_exists('hideEmailAddress')) {
    function hideEmailAddress($email)
    {
        $demo_mode = env('DEMO_MODE');
        if ($demo_mode == true && $email != '') {
            return 'xyz@gmail.com';
        } else {
            return $email;
        }
    }
}

if (!function_exists('hideMobileNumber')) {
    function hideMobileNumber($mobile)
    {
        $demo_mode = env('DEMO_MODE');
        if ($demo_mode == true && $mobile != '') {
            return '***********';
        } else {
            return $mobile;
        }
    }
}

if (!function_exists('compressAndUpload')) {
    function compressAndUpload($requestFile, $folder, $quality = 75)
    {
        $extension = strtolower($requestFile->getClientOriginalExtension());
        $mime = $requestFile->getMimeType();
        $file_name = uniqid() . '.' . $extension;

        try {
            if ($extension === 'svg' || $mime === 'image/svg+xml') {
                return $requestFile->storeAs($folder, $file_name, 'public');
            }

            if ($extension === 'gif' || $mime === 'image/gif') {
                return $requestFile->storeAs($folder, $file_name, 'public');
            }

            $image = Image::read($requestFile);

            switch ($extension) {
                case 'jpg':
                case 'png':
                case 'jpeg':
                    $encoded = $image->toJpeg($quality);
                    break;
                case 'webp':
                    $encoded = $image->toWebp($quality);
                    break;
                default:
                    return $requestFile->storeAs($folder, $file_name, 'public');
            }

            Storage::disk('public')->put("$folder/$file_name", $encoded->toString());

        } catch (\Exception $e) {
            return $requestFile->storeAs($folder, $file_name, 'public');
        }

        return "$folder/$file_name";
    }
}

if (!function_exists('compressAndReplace')) {
    function compressAndReplace($requestFile, $folder, $deleteRawOriginalImage)
    {
        if (!empty($deleteRawOriginalImage) && Storage::disk('public')->exists($deleteRawOriginalImage)) {
            Storage::disk('public')->delete($deleteRawOriginalImage);
        }
        return compressAndUpload($requestFile, $folder);
    }
}

if (!function_exists('uploadOriginalImage')) {
    function uploadOriginalImage($requestFile, $folder)
    {
        $extension = strtolower($requestFile->getClientOriginalExtension());
        $mime = $requestFile->getMimeType();
        $file_name = uniqid() . '.' . $extension;

        Storage::disk('public')->put("$folder/$file_name", $requestFile->get());

        return "$folder/$file_name";
    }
}
