<?php
/**
 * NewsController.php içindeki get_news_by_category fonksiyonunu BU İLE DEĞİŞTİR
 * 
 * Dosya: /home/newslyco/public_html/admin/app/Http/Controllers/NewsController.php
 * 
 * Mevcut fonksiyonu bul ve bu basit versiyonla değiştir.
 * 500 hatası veriyor çünkü show_till veya published_date sorguları sorunlu.
 */

public function get_news_by_category(Request $request)
{
    $category_id = $request->category_id;
    
    // Basit sorgu - sadece category_id ve status kontrol et
    $res = News::where('status', 1)
        ->where('category_id', $category_id)
        ->orderBy('id', 'desc')
        ->limit(100)
        ->get();
    
    $option = '<option value="">' . __('select') . ' ' . __('news') . '</option>';
    
    if (!empty($res)) {
        foreach ($res as $value) {
            $option .= '<option value="' . $value['id'] . '">' . $value['title'] . '</option>';
        }
    }
    
    return $option;
}


/**
 * ALTERNATIF: Eğer yukarıdaki de çalışmazsa, DB facade kullan
 */
/*
public function get_news_by_category(Request $request)
{
    $category_id = $request->category_id;
    
    $res = \DB::table('tbl_news')
        ->where('status', 1)
        ->where('category_id', $category_id)
        ->orderBy('id', 'desc')
        ->limit(100)
        ->get(['id', 'title']);
    
    $option = '<option value="">' . __('select') . ' ' . __('news') . '</option>';
    
    if (!empty($res)) {
        foreach ($res as $value) {
            $option .= '<option value="' . $value->id . '">' . $value->title . '</option>';
        }
    }
    
    return $option;
}
*/
