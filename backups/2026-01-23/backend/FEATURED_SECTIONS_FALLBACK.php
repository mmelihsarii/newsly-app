<?php
/**
 * FeaturedSectionsController için source_name Fallback Fonksiyonları
 * 
 * Bu dosyadaki fonksiyonları FeaturedSectionsController.php içine ekle
 * veya trait olarak kullan.
 * 
 * Tarih: 19 Ocak 2026
 */

// ============================================================================
// 1. KATEGORİ ID → KAYNAK ADI EŞLEŞTİRMESİ
// ============================================================================

/**
 * Kategori ID'sine göre varsayılan kaynak adı döndür
 * 
 * ÖNEMLİ: Bu map'i kendi admin panelindeki kategori ID'lerine göre güncelle!
 * Admin Panel > Kategoriler bölümünden ID'leri kontrol et.
 * 
 * @param int|null $categoryId
 * @return string
 *//*
private function getDefaultSourceName($categoryId) {
  // ⚠️ KENDİ KATEGORİ ID'LERİNLE DEĞİŞTİR!
  $categorySourceMap = [
      // GÜNDEM
      1 => 'NTV',
      2 => 'CNN Türk',
      3 => 'Habertürk',
      4 => 'TRT Haber',
      5 => 'A Haber',
      6 => 'Hürriyet',
      7 => 'Sözcü',
      8 => 'Sabah',
      9 => 'Haber Global',

      // SPOR
      10 => 'A Spor',
      11 => 'Fotomaç',
      12 => 'Kontraspor',
      13 => 'Fotospor',

      // EKONOMİ
      20 => 'Bloomberg HT',
      21 => 'BigPara',
      22 => 'Forbes Türkiye',

      // TEKNOLOJİ
      30 => 'Webtekno',
      31 => 'Teknoblog',
      32 => 'Donanım Haber',
      33 => 'Technopat',

      // BİLİM
      40 => 'Evrim Ağacı',

      // HABER AJANSLARI
      50 => 'Anadolu Ajansı',
      51 => 'İHA',
      52 => 'DHA',
  ];

  return $categorySourceMap[$categoryId] ?? 'Bilinmeyen Kaynak';
}

// ============================================================================
// 2. URL'DEN KAYNAK ADI ÇIKARMA
// ============================================================================

/**
* URL'den kaynak adı çıkar
* 
* @param string|null $url
* @return string|null
*/
/*
private function extractSourceFromUrl($url) {
    if (empty($url)) {
        return null;
    }

    // Domain → Kaynak Adı eşleştirmesi
    $urlSourceMap = [
        // BÜYÜK MEDYA
        'ntv.com.tr' => 'NTV',
        'cnnturk.com' => 'CNN Türk',
        'haberturk.com' => 'Habertürk',
        'trthaber.com' => 'TRT Haber',
        'ahaber.com' => 'A Haber',
        'haberglobal.com' => 'Haber Global',
        'tgrthaber.com' => 'TGRT Haber',
        'bbc.com' => 'BBC Türkçe',

        // GAZETELER
        'hurriyet.com.tr' => 'Hürriyet',
        'sozcu.com' => 'Sözcü',
        'sabah.com.tr' => 'Sabah',
        'milliyet.com.tr' => 'Milliyet',
        'aksam.com.tr' => 'Akşam',
        'star.com.tr' => 'Star',
        'yenisafak.com' => 'Yeni Şafak',
        'yeniakit.com' => 'Yeni Akit',
        'cumhuriyet.com.tr' => 'Cumhuriyet',
        'turkiyegazetesi.com' => 'Türkiye Gazetesi',

        // DİJİTAL MEDYA
        't24.com.tr' => 'T24',
        'odatv.com' => 'Oda TV',
        'diken.com.tr' => 'Diken',
        'gazeteduvar.com' => 'Gazete Duvar',
        'indyturk.com' => 'Independent Türkiye',
        'halktv.com' => 'Halk TV',
        'tele1.com.tr' => 'Tele1',
        'karar.com' => 'Karar',

        // SPOR
        'aspor.com' => 'A Spor',
        'fotomac.com' => 'Fotomaç',
        'fanatik.com' => 'Fanatik',
        'kontraspor.com' => 'Kontraspor',

        // EKONOMİ
        'bloomberght.com' => 'Bloomberg HT',
        'bigpara.com' => 'BigPara',
        'forbes.com.tr' => 'Forbes Türkiye',

        // TEKNOLOJİ
        'webtekno.com' => 'Webtekno',
        'teknoblog.com' => 'Teknoblog',
        'donanimhaber.com' => 'Donanım Haber',
        'technopat.net' => 'Technopat',
        'webrazzi.com' => 'Webrazzi',

        // BİLİM
        'evrimagaci.org' => 'Evrim Ağacı',

        // HABER AJANSLARI
        'aa.com.tr' => 'Anadolu Ajansı',
        'iha.com.tr' => 'İHA',
        'dha.com.tr' => 'DHA',

        // HABER PORTALLARI
        'haber7.com' => 'Haber 7',
        'haberler.com' => 'Haberler.com',
        'ensonhaber.com' => 'En Son Haber',
        'internethaber.com' => 'İnternet Haber',
        'mynet.com' => 'Mynet',
    ];

    // URL'de domain'i ara
    foreach ($urlSourceMap as $domain => $sourceName) {
        if (strpos($url, $domain) !== false) {
            return $sourceName;
        }
    }

    return null;
}

// ============================================================================
// 3. HABER VERİSİNİ FORMATLA (ANA FONKSİYON)
// ============================================================================

/**
 * Haber verisini JSON'a çevirirken source_name fallback uygula
 * 
 * @param object $news Veritabanından gelen haber objesi
 * @return array
 */
/*
private function formatNewsItem($news) {
    // source_name kontrolü
    $sourceName = $news->source_name ?? null;

    // Eğer source_name boşsa, fallback uygula
    if (empty($sourceName)) {
        // 1. Önce URL'den çıkarmayı dene
        if (!empty($news->other_url)) {
            $sourceName = $this->extractSourceFromUrl($news->other_url);
        }

        // 2. source_url'den dene
        if (empty($sourceName) && !empty($news->source_url)) {
            $sourceName = $this->extractSourceFromUrl($news->source_url);
        }

        // 3. Hala boşsa kategori ID'sine göre varsayılan ata
        if (empty($sourceName) && !empty($news->category_id)) {
            $sourceName = $this->getDefaultSourceName($news->category_id);
        }

        // 4. Son çare: Bilinmeyen Kaynak
        if (empty($sourceName)) {
            $sourceName = 'Bilinmeyen Kaynak';
        }
    }

    // Tarih formatla
    $date = null;
    if (!empty($news->created_at)) {
        $date = date('d M H:i', strtotime($news->created_at));
    }

    return [
        'id' => (int) $news->id,
        'title' => $news->title ?? '',
        'description' => $news->description ?? '',
        'image' => $news->image ?? '',
        'date' => $date,
        'published_at' => $news->created_at ?? null,
        'category_name' => $news->category_name ?? '',
        'content_type' => $news->content_type ?? 'standard_post',
        'content_value' => $news->content_value ?? '',
        'source_url' => $news->other_url ?? $news->source_url ?? '',
        'source_name' => $sourceName,  // ← Artık asla NULL olmayacak
    ];
}

// ============================================================================
// 4. KULLANIM ÖRNEĞİ
// ============================================================================

/**
 * get_featured_sections endpoint'inde kullanım örneği
 */
/*
public function get_featured_sections() {
    try {
        $sections = FeaturedSection::where('is_active', 1)
            ->orderBy('sort_order', 'ASC')
            ->get();

        $result = [];

        foreach ($sections as $section) {
            // Section'a ait haberleri çek
            $newsItems = $this->getNewsForSection($section);

            // Her haberi formatla (source_name fallback dahil)
            $formattedNews = [];
            foreach ($newsItems as $news) {
                $formattedNews[] = $this->formatNewsItem($news);
            }

            // Section type belirle
            $styleApp = $section->style_app ?? 'default';
            if ($styleApp === 'style_1' || $styleApp === 'style_6') {
                $type = 'slider';
            } elseif ($styleApp === 'style_4') {
                $type = 'breaking_news';
            } else {
                $type = 'horizontal_list';
            }

            $result[] = [
                'id' => (int) $section->id,
                'title' => $section->title ?? '',
                'type' => $type,
                'order' => (int) ($section->sort_order ?? 0),
                'is_active' => true,
                'news' => $formattedNews,
            ];
        }

        return response()->json($result);

    } catch (\Exception $e) {
        // Hata logla
        \Log::error('Featured Sections Error: ' . $e->getMessage());

        return response()->json([
            'error' => 'Bir hata oluştu',
            'message' => $e->getMessage()
        ], 500);
    }
}
