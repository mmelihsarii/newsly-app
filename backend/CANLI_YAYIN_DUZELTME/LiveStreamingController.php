<?php
/**
 * LiveStreamingController - Düzeltilmiş Versiyon
 * 
 * Düzeltmeler:
 * 1. show() metodu DataTable formatında veri döndürüyor (düzenleme/silme butonları ile)
 * 2. store() ve update() metodları resim yükleme desteği eklendi
 * 3. getLiveStreamsForApp() logo alanı eklendi
 * 
 * Bu dosyayı mevcut LiveStreamingController.php ile DEĞİŞTİR
 * Yol: /app/Http/Controllers/LiveStreamingController.php
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Gate;
use App\Services\ResponseService;

class LiveStreamingController extends Controller
{
    /**
     * Panel için canlı yayın listesi sayfası
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['live-streaming-list', 'live-streaming-create', 'live-streaming-edit', 'live-streaming-delete']);
        
        $languageList = DB::table('tbl_languages')->where('status', 1)->get();
        $streams = DB::table('tbl_live_streaming')->get();

        return view('live-streaming', compact('languageList', 'streams'));
    }

    /**
     * DataTable için liste - Düzenleme ve Silme butonları ile
     */
    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('live-streaming-list');
        
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        
        $sql = DB::table('tbl_live_streaming')
            ->leftJoin('tbl_languages', 'tbl_live_streaming.language_id', '=', 'tbl_languages.id')
            ->select('tbl_live_streaming.*', 'tbl_languages.language as language_name');
        
        // Dil filtresi
        if ($request->has('language_id') && $request->language_id > 0) {
            $sql->where('tbl_live_streaming.language_id', $request->language_id);
        }
        
        // Arama
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql->where(function ($q) use ($search) {
                $q->where('tbl_live_streaming.title', 'LIKE', "%{$search}%")
                  ->orWhere('tbl_live_streaming.url', 'LIKE', "%{$search}%");
            });
        }
        
        $total = $sql->count();
        
        $rows = $sql->orderBy("tbl_live_streaming.$sort", $order)
            ->skip($offset)
            ->take($limit)
            ->get()
            ->map(function ($row) {
                // Düzenleme butonu
                $edit = '';
                if (Gate::allows('live-streaming-edit')) {
                    $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="Düzenle">
                        <i class="fa fa-pen mr-1 text-primary"></i>Düzenle
                    </a>';
                }
                
                // Silme butonu
                $delete = '';
                if (Gate::allows('live-streaming-delete')) {
                    $delete = '<a data-url="' . url('live_streaming', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="Sil">
                        <i class="fa fa-trash mr-1 text-danger"></i>Sil
                    </a>';
                }
                
                // İşlem dropdown
                $operate = '-';
                if ($edit != '' || $delete != '') {
                    $operate = '<div class="dropdown">
                        <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                            <button class="btn btn-primary btn-sm px-3"><i class="fas fa-ellipsis-v"></i></button>
                        </a>
                        <div class="dropdown-menu dropdown-scrollbar">' . $edit . $delete . '</div>
                    </div>';
                }
                
                // Resim URL'i oluştur
                $imageUrl = '';
                $imageHtml = '-';
                if (!empty($row->image)) {
                    if (str_starts_with($row->image, 'http')) {
                        $imageUrl = $row->image;
                    } else {
                        $imagePath = $row->image;
                        if (strpos($imagePath, 'liveStreaming/') === false) {
                            $imagePath = 'liveStreaming/' . $imagePath;
                        }
                        if (Storage::disk('public')->exists($imagePath)) {
                            $imageUrl = url(Storage::url($imagePath));
                        } else {
                            $imageUrl = url('storage/' . $imagePath);
                        }
                    }
                    $imageHtml = '<a href="' . $imageUrl . '" data-toggle="lightbox" data-title="Image">
                        <img class="images_border" src="' . $imageUrl . '" height="50" width="50" style="object-fit: cover; border-radius: 5px;">
                    </a>';
                }
                
                return [
                    'id' => $row->id,
                    'language_id' => $row->language_id,
                    'language' => $row->language_name ?? '',
                    'image' => $imageHtml,
                    'image_url' => $imageUrl, // Edit modal için
                    'title' => $row->title,
                    'type' => $row->type,
                    'type1' => $row->type, // Edit modal için (select value)
                    'url' => '<a href="' . $row->url . '" target="_blank" class="text-primary">' . mb_substr($row->url, 0, 50) . '...</a>',
                    'url_raw' => $row->url, // Edit modal için
                    'schema_markup' => $row->schema_markup ?? '',
                    'meta_keyword' => $row->meta_keyword ?? '',
                    'meta_title' => $row->meta_title ?? '',
                    'meta_description' => $row->meta_description ?? '',
                    'operate' => $operate,
                ];
            });
        
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    /**
     * Yeni canlı yayın kaydet
     */
    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('live-streaming-create');
        
        $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|string',
            'url' => 'required|url',
        ]);
        
        // Resim yükleme
        $image = null;
        if ($request->hasFile('file')) {
            $image = $this->uploadImage($request->file('file'));
        }
        
        $data = [
            'language_id' => $request->language ?? $request->language_id ?? 1,
            'title' => $request->title,
            'image' => $image,
            'type' => $request->type,
            'url' => $request->url,
            'meta_title' => $request->meta_title,
            'meta_description' => $request->meta_description,
            'meta_keyword' => $request->meta_keyword,
            'schema_markup' => $request->schema_markup,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        DB::table('tbl_live_streaming')->insert($data);

        return response()->json([
            'error' => false,
            'message' => 'Canlı yayın başarıyla eklendi',
        ]);
    }

    /**
     * Canlı yayın güncelle
     */
    public function update(Request $request, $id)
    {
        ResponseService::noPermissionThenRedirect('live-streaming-edit');
        
        $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|string',
            'url' => 'required|url',
        ]);
        
        // Mevcut kaydı al
        $stream = DB::table('tbl_live_streaming')->where('id', $id)->first();
        if (!$stream) {
            return response()->json([
                'error' => true,
                'message' => 'Kayıt bulunamadı',
            ], 404);
        }
        
        // Resim yükleme
        $image = $stream->image; // Mevcut resmi koru
        if ($request->hasFile('file')) {
            // Eski resmi sil
            if (!empty($stream->image) && !str_starts_with($stream->image, 'http')) {
                $oldPath = $stream->image;
                if (strpos($oldPath, 'liveStreaming/') === false) {
                    $oldPath = 'liveStreaming/' . $oldPath;
                }
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }
            $image = $this->uploadImage($request->file('file'));
        }
        
        $data = [
            'language_id' => $request->language ?? $request->language_id ?? $stream->language_id,
            'title' => $request->title,
            'image' => $image,
            'type' => $request->type,
            'url' => $request->url,
            'meta_title' => $request->meta_title,
            'meta_description' => $request->meta_description,
            'meta_keyword' => $request->meta_keyword,
            'schema_markup' => $request->schema_markup,
            'updated_at' => now(),
        ];

        DB::table('tbl_live_streaming')->where('id', $id)->update($data);

        return response()->json([
            'error' => false,
            'message' => 'Canlı yayın başarıyla güncellendi',
        ]);
    }

    /**
     * Canlı yayın sil
     */
    public function destroy($id)
    {
        ResponseService::noPermissionThenRedirect('live-streaming-delete');
        
        $stream = DB::table('tbl_live_streaming')->where('id', $id)->first();
        
        if ($stream) {
            // Resmi sil
            if (!empty($stream->image) && !str_starts_with($stream->image, 'http')) {
                $imagePath = $stream->image;
                if (strpos($imagePath, 'liveStreaming/') === false) {
                    $imagePath = 'liveStreaming/' . $imagePath;
                }
                if (Storage::disk('public')->exists($imagePath)) {
                    Storage::disk('public')->delete($imagePath);
                }
            }
            
            DB::table('tbl_live_streaming')->where('id', $id)->delete();
        }

        return response()->json([
            'error' => false,
            'message' => 'Canlı yayın başarıyla silindi',
        ]);
    }
    
    /**
     * Resim yükleme helper
     */
    private function uploadImage($file)
    {
        $extension = strtolower($file->getClientOriginalExtension());
        $fileName = uniqid() . '.' . $extension;
        $path = $file->storeAs('liveStreaming', $fileName, 'public');
        return $path;
    }

    /**
     * Flutter uygulaması için API endpoint
     */
    public function getLiveStreamsForApp()
    {
        try {
            $streams = DB::table('tbl_live_streaming')
                ->orderBy('id', 'asc')
                ->get();

            $formattedStreams = $streams->map(function ($stream) {
                // YouTube video ID çıkar
                preg_match('/[?&]v=([^&]+)/', $stream->url ?? '', $matches);
                $videoId = $matches[1] ?? null;
                
                // /live/ formatı için
                if (!$videoId && strpos($stream->url, '/live/') !== false) {
                    preg_match('/\/live\/([^?&]+)/', $stream->url, $liveMatches);
                    $videoId = $liveMatches[1] ?? null;
                }
                
                // youtu.be formatı için
                if (!$videoId && strpos($stream->url, 'youtu.be/') !== false) {
                    preg_match('/youtu\.be\/([^?&]+)/', $stream->url, $shortMatches);
                    $videoId = $shortMatches[1] ?? null;
                }

                // Resim URL'i oluştur
                $imageUrl = null;
                if (!empty($stream->image)) {
                    if (str_starts_with($stream->image, 'http')) {
                        $imageUrl = $stream->image;
                    } else {
                        $imagePath = $stream->image;
                        if (strpos($imagePath, 'liveStreaming/') === false) {
                            $imagePath = 'liveStreaming/' . $imagePath;
                        }
                        if (Storage::disk('public')->exists($imagePath)) {
                            $imageUrl = url(Storage::url($imagePath));
                        }
                    }
                }
                
                // Thumbnail: varsa image, yoksa YouTube'dan otomatik
                $thumbnail = $imageUrl;
                if (empty($thumbnail) && $videoId) {
                    $thumbnail = 'https://img.youtube.com/vi/' . $videoId . '/hqdefault.jpg';
                }

                return [
                    'id' => $stream->id,
                    'title' => $stream->title,
                    'url' => $stream->url,
                    'type' => $stream->type ?? 'youtube',
                    'image' => $thumbnail,
                    'thumbnail' => $thumbnail,
                    'logo' => $imageUrl, // Flutter bu alanı bekliyor
                    'source_name' => $stream->title,
                    'is_active' => true,
                    'status' => 1,
                    'order' => $stream->id,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedStreams,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Canlı yayınlar yüklenemedi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
