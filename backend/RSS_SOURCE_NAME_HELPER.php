<?php
/**
 * RSS HABER KAYNAK ADI DÜZELTME SCRİPTİ
 * 
 * Bu dosya Laravel projenizde RSS'ten haber çekerken source_name alanını 
 * otomatik olarak doldurmak için kullanılabilir.
 * 
 * KULLANIM:
 * 1. Bu fonksiyonu RssController veya NewsController'a ekleyin
 * 2. RSS'ten haber çekilirken saveNewsWithSource() fonksiyonunu kullanın
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\News;
use Exception;

trait RssSourceTrait
{
    /**
     * RSS URL'inden kaynak adını belirle
     * 
     * @param string $rssUrl RSS feed URL'si
     * @return string Kaynak adı
     */
    protected function getSourceNameFromRssUrl(string $rssUrl): string
    {
        // URL parse et
        try {
            $parsed = parse_url($rssUrl);
            $host = $parsed['host'] ?? '';
            $host = str_replace('www.', '', $host);
        } catch (Exception $e) {
            return '';
        }

        // Domain -> Kaynak adı eşleştirmesi
        $domainMap = [
            // Ana Akım Medya
            'hurriyet.com.tr' => 'Hürriyet',
            'sozcu.com.tr' => 'Sözcü',
            'sabah.com.tr' => 'Sabah',
            'milliyet.com.tr' => 'Milliyet',
            'aksam.com.tr' => 'Akşam',
            'star.com.tr' => 'Star',
            'turkiyegazetesi.com.tr' => 'Türkiye Gazetesi',
            'yenisafak.com' => 'Yeni Şafak',
            'yenicaggazetesi.com.tr' => 'Yeniçağ Gazetesi',
            'yeniasir.com.tr' => 'Yeni Asır',
            'yeniakit.com.tr' => 'Yeni Akit',
            'milligazete.com.tr' => 'Milli Gazete',
            'dunya.com' => 'Dünya Gazetesi',
            
            // TV Kanalları
            'ntv.com.tr' => 'NTV',
            'cnnturk.com' => 'CNN Türk',
            'haberturk.com' => 'Habertürk',
            'trthaber.com' => 'TRT Haber',
            'ahaber.com.tr' => 'A Haber',
            'haberglobal.com.tr' => 'Haber Global',
            'tgrthaber.com.tr' => 'TGRT Haber',
            
            // Dijital Medya
            't24.com.tr' => 'T24',
            'odatv.com' => 'Oda TV',
            'diken.com.tr' => 'Diken',
            'gazeteduvar.com.tr' => 'Gazete Duvar',
            'tr.sputniknews.com' => 'Sputnik',
            
            // Uluslararası
            'bbc.com' => 'BBC Türkçe',
            'dw.com' => 'DW Haber',
            'tr.euronews.com' => 'Euro News',
            
            // Spor
            'aspor.com.tr' => 'A Spor',
            'fotomac.com.tr' => 'Fotomaç',
            'fanatik.com.tr' => 'Fanatik',
            'kontraspor.com' => 'Kontraspor',
            
            // Ekonomi
            'bloomberght.com' => 'Bloomberg HT',
            'bigpara.hurriyet.com.tr' => 'BigPara',
            
            // Teknoloji
            'webtekno.com' => 'Webtekno',
            'teknoblog.com' => 'Teknoblog',
            'donanimhaber.com' => 'Donanım Haber',
            'technopat.net' => 'Technopat',
            'webrazzi.com' => 'Webrazzi',
            
            // Bilim
            'evrimagaci.org' => 'Evrim Ağacı',
            
            // Haber Portalları
            'haber7.com' => 'Haber 7',
            'haberler.com' => 'Haberler.com',
            'internethaber.com' => 'İnternet Haber',
            'ensonhaber.com' => 'En Son Haber',
            'mynet.com' => 'Mynet',
            
            // Ajanslar
            'aa.com.tr' => 'Anadolu Ajansı',
            'iha.com.tr' => 'İHA',
            'dha.com.tr' => 'DHA',
        ];

        // Tam eşleşme
        if (isset($domainMap[$host])) {
            return $domainMap[$host];
        }

        // Kısmi eşleşme (subdomain'ler için)
        foreach ($domainMap as $domain => $sourceName) {
            if (strpos($host, str_replace('.com.tr', '', str_replace('.com', '', $domain))) !== false) {
                return $sourceName;
            }
        }

        // Bulunamazsa domain adını kullan
        $parts = explode('.', $host);
        return ucfirst($parts[0] ?? 'Bilinmeyen');
    }

    /**
     * RSS'ten gelen haberi source_name ile birlikte kaydet
     * 
     * @param array $newsData Haber verisi
     * @param string $rssUrl RSS kaynağının URL'si
     * @return News|null
     */
    protected function saveNewsWithSource(array $newsData, string $rssUrl): ?News
    {
        try {
            // Kaynak adını belirle
            $sourceName = $this->getSourceNameFromRssUrl($rssUrl);
            
            // Haber verisine ekle
            $newsData['source_name'] = $sourceName;
            
            // Kaydet veya güncelle
            $news = News::updateOrCreate(
                ['slug' => $newsData['slug'] ?? \Str::slug($newsData['title'])],
                $newsData
            );
            
            \Log::info("RSS Haber kaydedildi: {$news->title} - Kaynak: {$sourceName}");
            
            return $news;
        } catch (Exception $e) {
            \Log::error("RSS Haber kaydetme hatası: " . $e->getMessage());
            return null;
        }
    }
}

/**
 * MEVCUT HABERLERİ GÜNCELLEME - BİR KERELİK ÇALIŞTIRIN
 * 
 * Eğer RSS_URL bilgisi başka bir tabloda tutuluyorsa:
 * Bu scripti çalıştırarak mevcut haberlere source_name ekleyebilirsiniz.
 */
class UpdateExistingNewsSourceNames
{
    /**
     * Admin panelden çalıştırılabilir route:
     * Route::get('/admin/update-source-names', [UpdateExistingNewsSourceNames::class, 'handle']);
     */
    public function handle()
    {
        // Eğer RSS source bilgisi başka bir tabloda (örn: rss_sources) varsa:
        /*
        $rssSources = \DB::table('rss_sources')->get();
        
        foreach ($rssSources as $rssSource) {
            $sourceName = $this->getSourceNameFromRssUrl($rssSource->url);
            
            // Bu RSS kaynağından gelen haberleri güncelle
            \DB::table('tbl_news')
                ->where('category_id', $rssSource->category_id)
                ->whereNull('source_name')
                ->update(['source_name' => $sourceName]);
        }
        */
        
        // Eğer kategori bazlı varsayılan kaynak atamak istiyorsanız:
        // Bu map'i kendi kategori ID'lerinize göre düzenleyin
        $categorySourceMap = [
            // Kategori ID => Varsayılan Kaynak Adı
            // 1 => 'NTV',
            // 2 => 'CNN Türk',
            // ... vs
        ];
        
        foreach ($categorySourceMap as $categoryId => $sourceName) {
            \DB::table('tbl_news')
                ->where('category_id', $categoryId)
                ->whereNull('source_name')
                ->orWhere('source_name', '')
                ->update(['source_name' => $sourceName]);
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Kaynak adları güncellendi',
        ]);
    }
}
