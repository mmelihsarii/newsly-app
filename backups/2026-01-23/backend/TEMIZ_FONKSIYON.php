/**
 * BUNU KOPYALA VE FeaturedSectionsController.php DOSYASININ
 * EN SONUNA, SON } KARAKTERİNDEN ÖNCE YAPIŞTIR
 * 
 * ÖNCEKİ EKLEDİĞİN KODU SİL VE BUNU YAPIŞTIR
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
                switch ($section->style_app) {
                    case 'style_1':
                    case 'style_6':
                        $type = 'slider';
                        break;
                    case 'style_4':
                        $type = 'breaking_news';
                        break;
                    default:
                        $type = 'horizontal_list';
                }
                
                $newsData = [];
                
                if ($section->news_type == 'breaking_news') {
                    $items = BreakingNews::where('language_id', $section->language_id)
                        ->where('status', 1)
                        ->orderBy('created_at', 'DESC')
                        ->take(10)
                        ->get();
                } else {
                    $query = News::where('status', 1)
                        ->where('language_id', $section->language_id);
                    
                    if ($section->filter_type == 'custom' && !empty($section->news_ids)) {
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
                    
                    switch ($section->filter_type) {
                        case 'most_viewed':
                            $query->orderBy('total_views', 'DESC');
                            break;
                        case 'most_favorite':
                        case 'most_like':
                            $query->orderBy('total_like', 'DESC');
                            break;
                        default:
                            $query->orderBy('created_at', 'DESC');
                    }
                    
                    $items = $query->with('category')->take(10)->get();
                }
                
                foreach ($items as $item) {
                    $imageUrl = null;
                    if (!empty($item->image)) {
                        $imageUrl = (substr($item->image, 0, 4) === 'http') 
                            ? $item->image 
                            : url('storage/' . $item->image);
                    }
                    
                    $newsData[] = [
                        'id' => (string) $item->id,
                        'title' => $item->title ?? '',
                        'image' => $imageUrl,
                        'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
                        'categoryName' => $item->category->category_name ?? 'Gündem',
                        'description' => $item->short_description ?? '',
                        'sourceUrl' => $item->source_url ?? '',
                        'sourceName' => $item->source_name ?? '',
                    ];
                }
                
                if (!empty($newsData)) {
                    $result[] = [
                        'id' => $section->id,
                        'title' => $section->title,
                        'type' => $type,
                        'is_active' => true,
                        'order' => $section->row_order,
                        'news' => $newsData,
                    ];
                }
            }
            
            return response()->json([
                'success' => true,
                'data' => $result,
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => [],
            ], 500);
        }
    }
