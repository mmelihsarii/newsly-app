<?php
/**
 * FEATURED SECTIONS CONTROLLER - GÜNCELLENMİŞ getFeaturedSectionsForApp()
 * 
 * Bu fonksiyonu /home/newslyco/public_html/admin/app/Http/Controllers/FeaturedSectionsController.php
 * dosyasındaki mevcut getFeaturedSectionsForApp() fonksiyonu ile DEĞİŞTİRİN.
 * 
 * DEĞİŞİKLİK: RSS tablosundan category_id → feed_name eşleştirmesi ile sourceName buluyoruz
 */

// ============================================
// FLUTTER API - GÜNCELLENMİŞ FONKSİYON
// ============================================/*
/*
public function getFeaturedSectionsForApp(Request $request)
{
    try {
        $language_id = $request->input('language_id', 2);
        
        $sections = FeaturedSections::where('status', 1)
            ->where('language_id', $language_id)
            ->orderBy('row_order', 'ASC')
            ->get();
        
        if ($sections->isEmpty()) {
            return response()->json([
                'success' => true,
                'data' => [],
            ]);
        }
        
        // RSS KAYNAKLARI - category_id → feed_name eşleştirmesi
        $rssSourcesByCategory = [];
        try {
            $rssSources = \App\Models\RSS::where('status', 1)->get();
            foreach ($rssSources as $rss) {
                // Aynı kategoride birden fazla RSS olabilir, ilkini al
                if (!isset($rssSourcesByCategory[$rss->category_id])) {
                    $rssSourcesByCategory[$rss->category_id] = $rss->feed_name;
                }
            }
        } catch (\Exception $e) {
            \Log::warning('RSS sources could not be loaded: ' . $e->getMessage());
        }
        
        $result = [];
        
        foreach ($sections as $section) {
            // Type belirleme
            $styleApp = $section->style_app ?? 'default';
            if ($styleApp === 'style_1' || $styleApp === 'style_6') {
                $type = 'slider';
            } elseif ($styleApp === 'style_4') {
                $type = 'breaking_news';
            } else {
                $type = 'horizontal_list';
            }
            
            $newsData = [];
            $items = collect();
            
            try {
                $newsType = $section->news_type ?? '';
                
                if ($newsType === 'breaking_news') {
                    if (class_exists('App\Models\BreakingNews')) {
                        $items = \App\Models\BreakingNews::where('language_id', $section->language_id)
                            ->where('status', 1)
                            ->orderBy('created_at', 'DESC')
                            ->take(10)
                            ->get();
                    }
                } else {
                    $query = News::where('status', 1)
                        ->where('language_id', $section->language_id);
                    
                    $filterType = $section->filter_type ?? '';
                    
                    if ($filterType === 'custom' && !empty($section->news_ids)) {
                        $ids = array_filter(explode(',', $section->news_ids));
                        if (!empty($ids)) {
                            $query->whereIn('id', $ids);
                        }
                    }
                    
                    if (!empty($section->category_ids)) {
                        $catIds = array_filter(explode(',', $section->category_ids));
                        if (!empty($catIds)) {
                            $query->whereIn('category_id', $catIds);
                        }
                    }
                    
                    // Sıralama
                    $query->orderBy('created_at', 'DESC');
                    
                    $items = $query->with('category')->take(10)->get();
                }
            } catch (\Exception $e) {
                \Log::error('Section items error: ' . $e->getMessage());
                continue;
            }
            
            foreach ($items as $item) {
                $imageUrl = null;
                $itemImage = $item->image ?? null;
                
                if (!empty($itemImage)) {
                    if (strpos($itemImage, 'http') === 0) {
                        $imageUrl = $itemImage;
                    } else {
                        $imageUrl = url('storage/' . $itemImage);
                    }
                }
                
                $categoryName = 'Gündem';
                if (isset($item->category) && $item->category !== null) {
                    $categoryName = $item->category->category_name ?? 'Gündem';
                }
                
                // ======================================================
                // sourceName - YENİ MANTIK (RSS tablosundan category_id ile eşleştirme)
                // ======================================================
                $sourceName = '';
                
                // 1. Öncelik: Direkt source_name kolonu (eğer doluysa)
                if (!empty($item->source_name)) {
                    $sourceName = $item->source_name;
                }
                // 2. RSS tablosundan category_id → feed_name eşleştirmesi
                elseif (isset($item->category_id) && isset($rssSourcesByCategory[$item->category_id])) {
                    $sourceName = $rssSourcesByCategory[$item->category_id];
                }
                // 3. rss_source_name kolonu
                elseif (!empty($item->rss_source_name)) {
                    $sourceName = $item->rss_source_name;
                }
                // 4. source kolonu
                elseif (!empty($item->source)) {
                    $sourceName = $item->source;
                }
                // 5. other_url'den domain adını çıkar
                elseif (!empty($item->other_url)) {
                    try {
                        $parsed = parse_url($item->other_url);
                        if (isset($parsed['host'])) {
                            $host = str_replace('www.', '', $parsed['host']);
                            $sourceName = $this->getDomainSourceName($host);
                        }
                    } catch (\Exception $e) {
                        $sourceName = '';
                    }
                }
                // 6. source_url'den domain adını çıkar
                elseif (!empty($item->source_url)) {
                    try {
                        $parsed = parse_url($item->source_url);
                        if (isset($parsed['host'])) {
                            $host = str_replace('www.', '', $parsed['host']);
                            $sourceName = $this->getDomainSourceName($host);
                        }
                    } catch (\Exception $e) {
                        $sourceName = '';
                    }
                }
                // 7. Fallback: Kategori adını kullan (son çare)
                if (empty($sourceName) && !empty($categoryName)) {
                    $sourceName = $categoryName;
                }
                
                $dateStr = '';
                if ($item->created_at !== null) {
                    try {
                        $dateStr = $item->created_at->format('d M H:i');
                    } catch (\Exception $e) {
                        $dateStr = '';
                    }
                }
                
                $newsData[] = [
                    'id' => (string) ($item->id ?? ''),
                    'title' => $item->title ?? '',
                    'image' => $imageUrl,
                    'date' => $dateStr,
                    'categoryName' => $categoryName,
                    'description' => $item->short_description ?? $item->description ?? '',
                    'sourceUrl' => $item->source_url ?? $item->other_url ?? '',
                    'sourceName' => $sourceName,
                ];
            }
            
            if (!empty($newsData)) {
                $result[] = [
                    'id' => $section->id,
                    'title' => $section->title ?? '',
                    'type' => $type,
                    'is_active' => true,
                    'order' => $section->row_order ?? 0,
                    'news' => $newsData,
                ];
            }
        }
        
        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
        
    } catch (\Exception $e) {
        \Log::error('getFeaturedSectionsForApp Error: ' . $e->getMessage());
        
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
            'data' => [],
        ], 500);
    }
}

/**
 * Domain adından kaynak adını döndür
 */
/*
private function getDomainSourceName($host)
{
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
        'yenicaggazetesi.com.tr' => 'Yeniçağ',
        'yeniasir.com.tr' => 'Yeni Asır',
        'yeniakit.com.tr' => 'Yeni Akit',
        'milligazete.com.tr' => 'Milli Gazete',
        'dunya.com' => 'Dünya Gazetesi',
        'cumhuriyet.com.tr' => 'Cumhuriyet',
        'birgun.net' => 'BirGün',
        'evrensel.net' => 'Evrensel',

        // TV Kanalları
        'ntv.com.tr' => 'NTV',
        'cnnturk.com' => 'CNN Türk',
        'haberturk.com' => 'Habertürk',
        'trthaber.com' => 'TRT Haber',
        'ahaber.com.tr' => 'A Haber',
        'haberglobal.com.tr' => 'Haber Global',
        'tgrthaber.com.tr' => 'TGRT Haber',

        // Spor
        'aspor.com.tr' => 'A Spor',
        'fotomac.com.tr' => 'Fotomaç',
        'fanatik.com.tr' => 'Fanatik',
        'ntvspor.net' => 'NTV Spor',
        'sporx.com' => 'Sporx',

        // Teknoloji
        'webtekno.com' => 'Webtekno',
        'teknoblog.com' => 'Teknoblog',
        'donanimhaber.com' => 'Donanım Haber',
        'technopat.net' => 'Technopat',
        'webrazzi.com' => 'Webrazzi',

        // Ekonomi
        'bloomberght.com' => 'Bloomberg HT',
        'bigpara.hurriyet.com.tr' => 'BigPara',
        'paraanaliz.com' => 'Para Analiz',

        // Dijital Medya
        't24.com.tr' => 'T24',
        'odatv.com' => 'Oda TV',
        'diken.com.tr' => 'Diken',
        'gazeteduvar.com.tr' => 'Gazete Duvar',
        'medyascope.tv' => 'Medyascope',

        // Uluslararası
        'bbc.com' => 'BBC Türkçe',
        'dw.com' => 'DW Haber',
        'tr.euronews.com' => 'Euronews',
        'tr.sputniknews.com' => 'Sputnik',

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
    foreach ($domainMap as $domain => $name) {
        $domainBase = str_replace(['.com.tr', '.com', '.net', '.org', '.tv'], '', $domain);
        if (strpos($host, $domainBase) !== false) {
            return $name;
        }
    }

    // Bulunamazsa domain adının ilk kısmını döndür
    $parts = explode('.', $host);
    return ucfirst($parts[0] ?? 'Bilinmeyen');
}
