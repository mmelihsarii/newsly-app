# Featured Sections - Laravel Backend Kurulumu

Bu rehber, Flutter uygulamasındaki "Öne Çıkan Haberler" bölümünü admin panelinden yönetmek için gerekli Laravel dosyalarını içerir.

---

## 📁 Dosya Yapısı

```
app/
├── Models/
│   └── FeaturedSection.php
├── Http/Controllers/
│   ├── Api/
│   │   └── FeaturedSectionController.php (API)
│   └── Admin/
│       └── FeaturedSectionController.php (Admin Panel)
database/
└── migrations/
    └── create_featured_sections_table.php
resources/views/admin/featured_sections/
├── index.blade.php
├── create.blade.php
└── edit.blade.php
routes/
├── api.php
└── web.php
```

---

## 1️⃣ Migration Dosyası

**Dosya:** `database/migrations/2025_01_18_create_featured_sections_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('featured_sections', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->enum('type', ['slider', 'breaking_news', 'horizontal_list'])->default('slider');
            $table->boolean('is_active')->default(true);
            $table->integer('order')->default(0);
            $table->json('news_ids')->nullable(); // Seçilen haber ID'leri
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('featured_sections');
    }
};
```

**Çalıştır:**
```bash
php artisan migrate
```

---

## 2️⃣ Model Dosyası

**Dosya:** `app/Models/FeaturedSection.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FeaturedSection extends Model
{
    protected $fillable = [
        'title',
        'type',
        'is_active',
        'order',
        'news_ids',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'news_ids' => 'array',
    ];

    // Aktif section'ları getir
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Sıralı getir
    public function scopeOrdered($query)
    {
        return $query->orderBy('order', 'asc');
    }

    // Section tipinin Türkçe karşılığı
    public function getTypeNameAttribute()
    {
        return match($this->type) {
            'slider' => 'Slider (Kayan)',
            'breaking_news' => 'Son Dakika',
            'horizontal_list' => 'Yatay Liste',
            default => $this->type,
        };
    }
}
```

---

## 3️⃣ API Controller

**Dosya:** `app/Http/Controllers/Api/FeaturedSectionController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FeaturedSection;
use App\Models\News; // Mevcut haber modeliniz
use Illuminate\Http\JsonResponse;

class FeaturedSectionController extends Controller
{
    /**
     * Flutter uygulaması için featured sections API
     * GET /api/get_featured_sections
     */
    public function index(): JsonResponse
    {
        $sections = FeaturedSection::active()
            ->ordered()
            ->get();

        $result = [];

        foreach ($sections as $section) {
            $newsIds = $section->news_ids ?? [];
            
            // Haberleri çek (kendi News modelinize göre düzenleyin)
            $news = [];
            if (!empty($newsIds)) {
                $newsItems = News::whereIn('id', $newsIds)->get();
                
                foreach ($newsItems as $item) {
                    $news[] = [
                        'id' => (string) $item->id,
                        'title' => $item->title,
                        'image' => $item->image ?? $item->featured_image ?? null,
                        'date' => $item->created_at->format('d M H:i'),
                        'categoryName' => $item->category->name ?? 'Gündem',
                        'description' => $item->description ?? $item->excerpt ?? '',
                        'sourceUrl' => $item->source_url ?? $item->url ?? '',
                        'sourceName' => $item->source_name ?? $item->source ?? '',
                    ];
                }
            }

            $result[] = [
                'id' => $section->id,
                'title' => $section->title,
                'type' => $section->type,
                'is_active' => $section->is_active,
                'order' => $section->order,
                'news' => $news,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }
}
```

---

## 4️⃣ Admin Controller

**Dosya:** `app/Http/Controllers/Admin/FeaturedSectionController.php`

```php
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeaturedSection;
use App\Models\News;
use Illuminate\Http\Request;

class FeaturedSectionController extends Controller
{
    public function index()
    {
        $sections = FeaturedSection::ordered()->get();
        return view('admin.featured_sections.index', compact('sections'));
    }

    public function create()
    {
        $news = News::latest()->take(100)->get(); // Son 100 haber
        $types = [
            'slider' => 'Slider (Kayan Kartlar)',
            'breaking_news' => 'Son Dakika Bandı',
            'horizontal_list' => 'Yatay Liste',
        ];
        return view('admin.featured_sections.create', compact('news', 'types'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|in:slider,breaking_news,horizontal_list',
            'is_active' => 'boolean',
            'order' => 'integer',
            'news_ids' => 'array',
        ]);

        $validated['is_active'] = $request->has('is_active');
        $validated['news_ids'] = $request->news_ids ?? [];

        FeaturedSection::create($validated);

        return redirect()->route('admin.featured-sections.index')
            ->with('success', 'Öne çıkan bölüm oluşturuldu.');
    }

    public function edit(FeaturedSection $featuredSection)
    {
        $news = News::latest()->take(100)->get();
        $types = [
            'slider' => 'Slider (Kayan Kartlar)',
            'breaking_news' => 'Son Dakika Bandı',
            'horizontal_list' => 'Yatay Liste',
        ];
        return view('admin.featured_sections.edit', compact('featuredSection', 'news', 'types'));
    }

    public function update(Request $request, FeaturedSection $featuredSection)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'type' => 'required|in:slider,breaking_news,horizontal_list',
            'is_active' => 'boolean',
            'order' => 'integer',
            'news_ids' => 'array',
        ]);

        $validated['is_active'] = $request->has('is_active');
        $validated['news_ids'] = $request->news_ids ?? [];

        $featuredSection->update($validated);

        return redirect()->route('admin.featured-sections.index')
            ->with('success', 'Öne çıkan bölüm güncellendi.');
    }

    public function destroy(FeaturedSection $featuredSection)
    {
        $featuredSection->delete();

        return redirect()->route('admin.featured-sections.index')
            ->with('success', 'Öne çıkan bölüm silindi.');
    }
}
```

---

## 5️⃣ Route Tanımlamaları

**Dosya:** `routes/api.php`

```php
<?php

use App\Http\Controllers\Api\FeaturedSectionController;

// Mevcut route'larınızın altına ekleyin:
Route::get('get_featured_sections', [FeaturedSectionController::class, 'index']);
```

**Dosya:** `routes/web.php`

```php
<?php

use App\Http\Controllers\Admin\FeaturedSectionController;

// Admin route grubu içine ekleyin:
Route::prefix('admin')->middleware(['auth', 'admin'])->group(function () {
    // ... mevcut route'larınız ...
    
    Route::resource('featured-sections', FeaturedSectionController::class);
});
```

---

## 6️⃣ Admin Panel View Dosyaları

### index.blade.php (Liste Sayfası)

**Dosya:** `resources/views/admin/featured_sections/index.blade.php`

```blade
@extends('admin.layouts.app')

@section('title', 'Öne Çıkan Bölümler')

@section('content')
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1>Öne Çıkan Bölümler</h1>
        <a href="{{ route('admin.featured-sections.create') }}" class="btn btn-primary">
            <i class="fas fa-plus"></i> Yeni Bölüm Ekle
        </a>
    </div>

    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <div class="card">
        <div class="card-body">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Sıra</th>
                        <th>Başlık</th>
                        <th>Tip</th>
                        <th>Haber Sayısı</th>
                        <th>Durum</th>
                        <th>İşlemler</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($sections as $section)
                    <tr>
                        <td>{{ $section->order }}</td>
                        <td>{{ $section->title }}</td>
                        <td>
                            @if($section->type == 'slider')
                                <span class="badge bg-primary">Slider</span>
                            @elseif($section->type == 'breaking_news')
                                <span class="badge bg-danger">Son Dakika</span>
                            @else
                                <span class="badge bg-info">Yatay Liste</span>
                            @endif
                        </td>
                        <td>{{ count($section->news_ids ?? []) }} haber</td>
                        <td>
                            @if($section->is_active)
                                <span class="badge bg-success">Aktif</span>
                            @else
                                <span class="badge bg-secondary">Pasif</span>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('admin.featured-sections.edit', $section) }}" 
                               class="btn btn-sm btn-warning">
                                <i class="fas fa-edit"></i>
                            </a>
                            <form action="{{ route('admin.featured-sections.destroy', $section) }}" 
                                  method="POST" class="d-inline"
                                  onsubmit="return confirm('Silmek istediğinize emin misiniz?')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-danger">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center">Henüz öne çıkan bölüm yok.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
```

### create.blade.php (Ekleme Sayfası)

**Dosya:** `resources/views/admin/featured_sections/create.blade.php`

```blade
@extends('admin.layouts.app')

@section('title', 'Yeni Öne Çıkan Bölüm')

@section('content')
<div class="container-fluid">
    <h1 class="mb-4">Yeni Öne Çıkan Bölüm</h1>

    <div class="card">
        <div class="card-body">
            <form action="{{ route('admin.featured-sections.store') }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label class="form-label">Bölüm Başlığı</label>
                    <input type="text" name="title" class="form-control" 
                           placeholder="Örn: Günün Öne Çıkanları" required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Görünüm Tipi</label>
                    <select name="type" class="form-select" required>
                        @foreach($types as $value => $label)
                            <option value="{{ $value }}">{{ $label }}</option>
                        @endforeach
                    </select>
                    <small class="text-muted">
                        <strong>Slider:</strong> Büyük kayan kartlar |
                        <strong>Son Dakika:</strong> Kırmızı etiketli bant |
                        <strong>Yatay Liste:</strong> Küçük kaydırılabilir kartlar
                    </small>
                </div>

                <div class="mb-3">
                    <label class="form-label">Sıra Numarası</label>
                    <input type="number" name="order" class="form-control" value="0">
                    <small class="text-muted">Küçük numara daha üstte görünür</small>
                </div>

                <div class="mb-3">
                    <div class="form-check">
                        <input type="checkbox" name="is_active" class="form-check-input" 
                               id="is_active" checked>
                        <label class="form-check-label" for="is_active">Aktif</label>
                    </div>
                </div>

                <div class="mb-3">
                    <label class="form-label">Haberler</label>
                    <div class="border p-3" style="max-height: 400px; overflow-y: auto;">
                        @foreach($news as $item)
                        <div class="form-check mb-2">
                            <input type="checkbox" name="news_ids[]" value="{{ $item->id }}" 
                                   class="form-check-input" id="news_{{ $item->id }}">
                            <label class="form-check-label" for="news_{{ $item->id }}">
                                <strong>{{ Str::limit($item->title, 80) }}</strong>
                                <br>
                                <small class="text-muted">
                                    {{ $item->created_at->format('d.m.Y H:i') }}
                                </small>
                            </label>
                        </div>
                        @endforeach
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary">Kaydet</button>
                    <a href="{{ route('admin.featured-sections.index') }}" class="btn btn-secondary">
                        İptal
                    </a>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
```

### edit.blade.php (Düzenleme Sayfası)

**Dosya:** `resources/views/admin/featured_sections/edit.blade.php`

```blade
@extends('admin.layouts.app')

@section('title', 'Öne Çıkan Bölüm Düzenle')

@section('content')
<div class="container-fluid">
    <h1 class="mb-4">Öne Çıkan Bölüm Düzenle</h1>

    <div class="card">
        <div class="card-body">
            <form action="{{ route('admin.featured-sections.update', $featuredSection) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="mb-3">
                    <label class="form-label">Bölüm Başlığı</label>
                    <input type="text" name="title" class="form-control" 
                           value="{{ $featuredSection->title }}" required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Görünüm Tipi</label>
                    <select name="type" class="form-select" required>
                        @foreach($types as $value => $label)
                            <option value="{{ $value }}" 
                                {{ $featuredSection->type == $value ? 'selected' : '' }}>
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label">Sıra Numarası</label>
                    <input type="number" name="order" class="form-control" 
                           value="{{ $featuredSection->order }}">
                </div>

                <div class="mb-3">
                    <div class="form-check">
                        <input type="checkbox" name="is_active" class="form-check-input" 
                               id="is_active" {{ $featuredSection->is_active ? 'checked' : '' }}>
                        <label class="form-check-label" for="is_active">Aktif</label>
                    </div>
                </div>

                <div class="mb-3">
                    <label class="form-label">Haberler</label>
                    <div class="border p-3" style="max-height: 400px; overflow-y: auto;">
                        @php $selectedIds = $featuredSection->news_ids ?? []; @endphp
                        @foreach($news as $item)
                        <div class="form-check mb-2">
                            <input type="checkbox" name="news_ids[]" value="{{ $item->id }}" 
                                   class="form-check-input" id="news_{{ $item->id }}"
                                   {{ in_array($item->id, $selectedIds) ? 'checked' : '' }}>
                            <label class="form-check-label" for="news_{{ $item->id }}">
                                <strong>{{ Str::limit($item->title, 80) }}</strong>
                                <br>
                                <small class="text-muted">
                                    {{ $item->created_at->format('d.m.Y H:i') }}
                                </small>
                            </label>
                        </div>
                        @endforeach
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary">Güncelle</button>
                    <a href="{{ route('admin.featured-sections.index') }}" class="btn btn-secondary">
                        İptal
                    </a>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
```

---

## 7️⃣ Admin Menüye Ekleme

Admin panel sidebar'ınıza ekleyin:

```blade
<li class="nav-item">
    <a class="nav-link" href="{{ route('admin.featured-sections.index') }}">
        <i class="fas fa-star"></i>
        <span>Öne Çıkanlar</span>
    </a>
</li>
```

---

## 🧪 Test Etme

1. Migration'ı çalıştırın: `php artisan migrate`
2. Admin panele giriş yapın
3. "Öne Çıkanlar" menüsüne tıklayın
4. "Yeni Bölüm Ekle" ile bir slider oluşturun
5. Flutter uygulamasını açın ve ana sayfada görün

---

## 📱 Flutter API Endpoint

Flutter uygulaması şu endpoint'i çağırıyor:

```
GET https://your-domain.com/api/get_featured_sections
```

**Beklenen Yanıt:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Günün Öne Çıkanları",
      "type": "slider",
      "is_active": true,
      "order": 1,
      "news": [
        {
          "id": "1",
          "title": "Haber Başlığı",
          "image": "https://...",
          "date": "18 Oca 14:30",
          "categoryName": "Gündem",
          "description": "...",
          "sourceUrl": "https://...",
          "sourceName": "Kaynak"
        }
      ]
    }
  ]
}
```

---

## ⚠️ Önemli Notlar

1. **News Model:** API Controller'daki `News` modelini kendi haber modelinize göre düzenleyin
2. **Field İsimleri:** `image`, `source_url` gibi alanları kendi veritabanı yapınıza göre değiştirin
3. **Middleware:** Admin route'larında doğru middleware kullandığınızdan emin olun
4. **Layout:** View dosyalarındaki `@extends('admin.layouts.app')` kısmını kendi layout'unuza göre değiştirin

---

*Son Güncelleme: Ocak 2025*
