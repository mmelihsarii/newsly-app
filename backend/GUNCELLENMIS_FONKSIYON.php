<?php
/**
 * PHP 8.2 UYUMLU - FEATURED SECTIONS API
 * sourceName alanı gerçek kaynak adını döndürür
 * 
 * Bu fonksiyonu FeaturedSectionsController.php dosyasına ekle
 * Son } karakterinden önce yapıştır
 * 
 * Route ekle (api.php):
 * Route::get('get_featured_sections', [FeaturedSectionsController::class, 'getFeaturedSectionsForApp']);
 */

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
                        
                        // Sıralama - sadece created_at kullan
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
                    
                    // sourceName - GERÇEK KAYNAK ADINI BUL
                    // Öncelik: source_name > rss_source_name > source > other_url'den parse
                    $sourceName = '';
                    
                    // 1. Direkt source_name kolonu
                    if (!empty($item->source_name)) {
                        $sourceName = $item->source_name;
                    }
                    // 2. rss_source_name kolonu
                    elseif (!empty($item->rss_source_name)) {
                        $sourceName = $item->rss_source_name;
                    }
                    // 3. source kolonu
                    elseif (!empty($item->source)) {
                        $sourceName = $item->source;
                    }
                    // 4. other_url'den domain adını çıkar
                    elseif (!empty($item->other_url)) {
                        try {
                            $parsed = parse_url($item->other_url);
                            if (isset($parsed['host'])) {
                                $host = str_replace('www.', '', $parsed['host']);
                                // Domain'den kaynak adı çıkar (örn: hurriyet.com.tr -> Hürriyet)
                                $sourceName = $this->getDomainSourceName($host);
                            }
                        } catch (\Exception $e) {
                            $sourceName = '';
                        }
                    }
                    // 5. source_url'den domain adını çıkar
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
    private function getDomainSourceName($host)
    {
        $domainMap = [
            'hurriyet.com.tr' => 'Hürriyet',
            'sozcu.com.tr' => 'Sözcü',
            'sabah.com.tr' => 'Sabah',
            'ntv.com.tr' => 'NTV',
            'cnnturk.com' => 'CNN Türk',
            'haberturk.com' => 'Habertürk',
            'milliyet.com.tr' => 'Milliyet',
            'aksam.com.tr' => 'Akşam',
            'star.com.tr' => 'Star',
            'yenisafak.com' => 'Yeni Şafak',
            'trthaber.com' => 'TRT Haber',
            'ahaber.com.tr' => 'A Haber',
            'aspor.com.tr' => 'A Spor',
            'fotomac.com.tr' => 'Fotomaç',
            'fanatik.com.tr' => 'Fanatik',
            'webtekno.com' => 'Webtekno',
            'donanimhaber.com' => 'Donanım Haber',
            'bloomberght.com' => 'Bloomberg HT',
            't24.com.tr' => 'T24',
            'bbc.com' => 'BBC',
            'dw.com' => 'DW',
            'independent.co.uk' => 'Independent',
            'cumhuriyet.com.tr' => 'Cumhuriyet',
            'birgun.net' => 'BirGün',
            'evrensel.net' => 'Evrensel',
            'gazeteduvar.com.tr' => 'Gazete Duvar',
            'odatv.com' => 'Oda TV',
            'haber7.com' => 'Haber 7',
            'ensonhaber.com' => 'En Son Haber',
            'mynet.com' => 'Mynet',
            'internethaber.com' => 'İnternet Haber',
        ];
        
        // Tam eşleşme
        if (isset($domainMap[$host])) {
            return $domainMap[$host];
        }
        
        // Kısmi eşleşme
        foreach ($domainMap as $domain => $name) {
            if (strpos($host, str_replace('.com.tr', '', str_replace('.com', '', $domain))) !== false) {
                return $name;
            }
        }
        
        // Bulunamazsa domain adını döndür
        return ucfirst(explode('.', $host)[0]);
    }
