<?php
/**
 * SendNotificationController - Haber Seçimli Bildirim
 * 
 * Bu dosyayı mevcut SendNotificationController.php ile DEĞİŞTİR
 * Yol: /app/Http/Controllers/SendNotificationController.php
 */

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Language;
use App\Models\Location;
use App\Models\News;
use App\Models\SendNotification;
use App\Models\Settings;
use App\Models\UserCategory;
use App\Models\Token;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SendNotificationController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['notification-list', 'notification-create', 'notification-delete']);

        try {
            $firebase_config = public_path('assets/firebase_config.json');
            if (!file_exists($firebase_config)) {
                return redirect('firebase-configuration')->with('error', __('file_not_exists'));
            }

            $languageList = Language::where('status', 1)->get();
            $categoryList = [];
            if (count($languageList) == 1) {
                $language_id = $languageList[0]->id;
                $categoryList = Category::select('id', 'category_name')->where('language_id', $language_id)->get();
            }

            $locationList = Location::get();
            $settings = Settings::whereIn('type', ['subcategory_mode', 'category_mode'])->pluck('message', 'type');

            return view('notifications', compact('languageList', 'categoryList', 'locationList', 'settings'));
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('notification-create');

        $request->validate([
            'language' => 'required',
            'category_id' => 'required',
            'news_id' => 'required',
        ]);

        $language_id = $request->language;
        $location_id = $request->location_id ?? 0;
        $category_id = $request->category_id;
        $news_id = $request->news_id;
        $is_user_category = $request->is_user_category ?? 0;
        $category_preference = ($is_user_category == 1) ? 1 : 0;

        // Haber bilgilerini al
        $news = News::find($news_id);
        if (!$news) {
            return response()->json([
                'error' => true,
                'message' => 'Haber bulunamadı',
            ]);
        }

        // Başlık ve mesajı haberden al
        $title = $news->title;
        
        // Description'dan HTML taglerini temizle
        $message = strip_tags($news->description ?? '');
        $message = html_entity_decode($message, ENT_QUOTES, 'UTF-8');
        $message = preg_replace('/\s+/', ' ', $message);
        $message = trim($message);
        if (mb_strlen($message) > 150) {
            $message = mb_substr($message, 0, 147) . '...';
        }

        // Resmi haberden al
        $image = '';
        if (!empty($news->image)) {
            $image = $news->image; // Model accessor zaten URL döndürüyor
        }

        // Veritabanına kaydet
        $data = SendNotification::create([
            'language_id' => $language_id,
            'location_id' => $location_id,
            'type' => 'category',
            'category_id' => $category_id,
            'subcategory_id' => 0,
            'news_id' => $news_id,
            'title' => $title,
            'message' => $message,
            'image' => $image,
            'category_preference' => $category_preference,
            'date_sent' => date('Y-m-d H:i:s'),
        ]);

        // FCM mesajı hazırla
        $fcmMsg = [
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'title' => $title,
            'body' => $message,
            'message' => $message,
            'language_id' => (string) $language_id,
            'type' => 'category',
            'category_id' => (string) $category_id,
            'subcategory_id' => '0',
            'news_id' => (string) $news_id,
            'image' => $image,
            'sound' => 'default',
            'icon' => 'ic_stat_notification',
            'color' => '#F4220B',
        ];

        // Kategori tercihine göre gönder
        if ($is_user_category == 1 && $category_id > 0) {
            // Sadece bu kategoriyi takip edenlere gönder
            $userIds = UserCategory::whereRaw("FIND_IN_SET(?, category_id)", [$category_id])
                ->orWhere('category_id', $category_id)
                ->pluck('user_id')
                ->toArray();

            $fcmIds = DB::table('tbl_users')
                ->whereIn('id', $userIds)
                ->where('fcm_id', '!=', '')
                ->whereNotNull('fcm_id')
                ->pluck('fcm_id')
                ->toArray();

            $tokens = Token::whereIn('token', $fcmIds)
                ->where('language_id', $language_id)
                ->pluck('token')
                ->toArray();

            if (!empty($tokens)) {
                send_notification($fcmMsg, $language_id, $location_id, $tokens);
            }
        } else {
            // Herkese gönder
            send_notification($fcmMsg, $language_id, $location_id);
        }

        return response()->json([
            'error' => false,
            'message' => __('sent_success'),
        ]);
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('notification-list');

        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = SendNotification::with(['language', 'category', 'sub_category'])->orderBy($sort, $order);

        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                    ->orwhere('title', 'LIKE', "%{$search}%");
            });
        }

        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit);

        $rows = $sql->get()->map(function ($row) {
            $operate = '';
            if (Gate::allows('notification-delete')) {
                $operate =
                    '<a data-url="' .
                    url('notifications', $row->id) .
                    '" class="btn btn-secondary me-4 text-white delete-form" data-id="' .
                    $row->id .
                    '" title="' .
                    __('delete') .
                    '"><span class="fa fa-trash"></span></a>';
            }

            // Haber başlığını al
            $newsTitle = '';
            if ($row->news_id) {
                $news = News::find($row->news_id);
                if ($news) {
                    $newsTitle = mb_substr($news->title, 0, 50) . '...';
                }
            }

            return [
                'id' => $row->id,
                'langauge_id' => $row->language_id,
                'langauge_name' => $row->language->language ?? '',
                'category_id' => $row->category_id,
                'category_name' => $row->category->category_name ?? '',
                'subcategory_id' => $row->subcategory_id,
                'subcategory_name' => $row->sub_category->subcategory_name ?? '',
                'news_id' => $row->news_id,
                'news_title' => $newsTitle,
                'title' => mb_substr($row->title, 0, 50) . (mb_strlen($row->title) > 50 ? '...' : ''),
                'message' => mb_substr($row->message, 0, 50) . (mb_strlen($row->message) > 50 ? '...' : ''),
                'category_preference' => $row->category_preference == 1 ? __('yes') : __('no'),
                'image' => $row->image ? '<a href="' . $row->image . '" data-toggle="lightbox" data-title="Image"><img class="images_border" src="' . $row->image . '" height="50" width="50"></a>' : '-',
                'date' => date('d-m-Y H:i:s', strtotime($row->date_sent)),
                'operate' => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('notification-delete');

        SendNotification::find($id)->delete();

        return response()->json([
            'error' => false,
            'message' => __('deleted_success'),
        ]);
    }
}
