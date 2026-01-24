<?php
/**
 * RSS GÖRSEL ÇEKME FONKSİYONU - MEGA GÜÇLENDİRİLMİŞ
 * 
 * Bu fonksiyonu RSS fetch komutuna ekle veya mevcut görsel çekme mantığını değiştir.
 * 
 * Dosya: /home/newslyco/public_html/admin/app/Console/Commands/FetchRss.php
 * veya helpers.php'ye ekle
 * 
 * 30+ FARKLI GÖRSEL ÇEKME YÖNTEMİ
 */

/**
 * RSS item'dan görsel URL'si çıkar - TÜM YÖNTEMLER
 */
function extractImageFromRssItem($item, $feedUrl = '')
{
    $imageUrl = null;
    
    // Namespace'leri al
    $namespaces = $item->getNamespaces(true);
    
    // ═══════════════════════════════════════════════════════════════════
    // 1. ENCLOSURE - En yaygın RSS 2.0 yöntemi
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->enclosure)) {
        foreach ($item->enclosure as $enclosure) {
            $type = (string) $enclosure['type'];
            $url = (string) $enclosure['url'];
            if ((strpos($type, 'image') !== false || empty($type)) && !empty($url)) {
                $imageUrl = $url;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 2. MEDIA NAMESPACE - YouTube, büyük medya siteleri
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['media'])) {
        $media = $item->children($namespaces['media']);
        
        // media:content
        if (isset($media->content)) {
            foreach ($media->content as $content) {
                $url = (string) $content['url'];
                $medium = (string) $content['medium'];
                $type = (string) $content['type'];
                if (!empty($url) && ($medium === 'image' || strpos($type, 'image') !== false || empty($medium))) {
                    $imageUrl = $url;
                    break;
                }
            }
        }
        
        // media:thumbnail
        if (!$imageUrl && isset($media->thumbnail)) {
            foreach ($media->thumbnail as $thumb) {
                $url = (string) $thumb['url'];
                if (!empty($url)) {
                    $imageUrl = $url;
                    break;
                }
            }
        }
        
        // media:group
        if (!$imageUrl && isset($media->group)) {
            if (isset($media->group->thumbnail)) {
                $imageUrl = (string) $media->group->thumbnail['url'];
            }
            if (!$imageUrl && isset($media->group->content)) {
                $imageUrl = (string) $media->group->content['url'];
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 3. ATOM NAMESPACE
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['atom'])) {
        $atom = $item->children($namespaces['atom']);
        if (isset($atom->link)) {
            foreach ($atom->link as $link) {
                $rel = (string) $link['rel'];
                $type = (string) $link['type'];
                $href = (string) $link['href'];
                if (($rel === 'enclosure' || $rel === 'image') && !empty($href)) {
                    $imageUrl = $href;
                    break;
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 4. ITUNES NAMESPACE - Podcast'ler
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['itunes'])) {
        $itunes = $item->children($namespaces['itunes']);
        if (isset($itunes->image)) {
            $imageUrl = (string) $itunes->image['href'];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 5. DUBLIN CORE (DC) NAMESPACE
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['dc'])) {
        $dc = $item->children($namespaces['dc']);
        $dcTags = ['image', 'thumbnail', 'picture', 'photo', 'visual'];
        foreach ($dcTags as $tag) {
            if (isset($dc->$tag) && !empty((string)$dc->$tag)) {
                $imageUrl = (string) $dc->$tag;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 6. CONTENT NAMESPACE - content:encoded
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['content'])) {
        $content = $item->children($namespaces['content']);
        if (isset($content->encoded)) {
            $imageUrl = extractFirstImageFromHtml((string) $content->encoded);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 7. YAHOO MRSS
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['yahoo'])) {
        $yahoo = $item->children($namespaces['yahoo']);
        if (isset($yahoo->thumbnail)) {
            $imageUrl = (string) $yahoo->thumbnail['url'];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 8. FEEDBURNER
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['feedburner'])) {
        $fb = $item->children($namespaces['feedburner']);
        if (isset($fb->origEnclosureLink)) {
            $imageUrl = (string) $fb->origEnclosureLink;
        }
        if (!$imageUrl && isset($fb->origLink)) {
            // Link'ten görsel çekmeyi dene
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 9. WORDPRESS NAMESPACE
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($namespaces['wp'])) {
        $wp = $item->children($namespaces['wp']);
        $wpTags = ['featuredmedia', 'post_thumbnail', 'attachment_url', 'featured_image'];
        foreach ($wpTags as $tag) {
            if (isset($wp->$tag) && !empty((string)$wp->$tag)) {
                $imageUrl = (string) $wp->$tag;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 10. STANDARD RSS TAGS
    // ═══════════════════════════════════════════════════════════════════
    $standardTags = [
        'image', 'thumbnail', 'thumb', 'picture', 'photo', 'visual',
        'img', 'img_src', 'image_url', 'imageUrl', 'imgSrc', 'imgUrl',
        'featured_image', 'featuredImage', 'post_thumbnail', 'postThumbnail',
        'og_image', 'ogImage', 'twitter_image', 'twitterImage',
        'hero_image', 'heroImage', 'cover', 'cover_image', 'coverImage',
        'banner', 'banner_image', 'bannerImage', 'lead_image', 'leadImage',
        'main_image', 'mainImage', 'primary_image', 'primaryImage',
        'article_image', 'articleImage', 'news_image', 'newsImage',
        'story_image', 'storyImage', 'post_image', 'postImage',
        'media_url', 'mediaUrl', 'media_image', 'mediaImage',
        'preview', 'preview_image', 'previewImage',
        'icon', 'logo', 'avatar',
    ];
    
    if (!$imageUrl) {
        foreach ($standardTags as $tag) {
            if (isset($item->$tag)) {
                $val = $item->$tag;
                // Attribute olarak url varsa
                if (isset($val['url'])) {
                    $imageUrl = (string) $val['url'];
                } elseif (isset($val['href'])) {
                    $imageUrl = (string) $val['href'];
                } elseif (isset($val['src'])) {
                    $imageUrl = (string) $val['src'];
                } else {
                    $imageUrl = (string) $val;
                }
                if (!empty($imageUrl)) break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 11. DESCRIPTION İÇİNDEN IMG TAG
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->description)) {
        $imageUrl = extractFirstImageFromHtml((string) $item->description);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 12. SUMMARY İÇİNDEN (Atom feeds)
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->summary)) {
        $imageUrl = extractFirstImageFromHtml((string) $item->summary);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 13. FULL CONTENT / BODY
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl) {
        $contentTags = ['content', 'body', 'full_text', 'fullText', 'article', 'text'];
        foreach ($contentTags as $tag) {
            if (isset($item->$tag)) {
                $imageUrl = extractFirstImageFromHtml((string) $item->$tag);
                if ($imageUrl) break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 14. LINK'LERDEN GÖRSEL BULMAYA ÇALIŞ
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->link)) {
        foreach ($item->link as $link) {
            $href = '';
            $type = '';
            $rel = '';
            
            // Attribute olarak
            if (isset($link['href'])) {
                $href = (string) $link['href'];
                $type = (string) ($link['type'] ?? '');
                $rel = (string) ($link['rel'] ?? '');
            } else {
                $href = (string) $link;
            }
            
            // Görsel link mi?
            if (strpos($type, 'image') !== false || 
                $rel === 'image' || 
                $rel === 'enclosure' ||
                preg_match('/\.(jpg|jpeg|png|gif|webp|svg)(\?|$)/i', $href)) {
                $imageUrl = $href;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 15. GUID'DEN GÖRSEL (bazı siteler guid'e görsel URL koyuyor)
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->guid)) {
        $guid = (string) $item->guid;
        if (preg_match('/\.(jpg|jpeg|png|gif|webp)(\?|$)/i', $guid)) {
            $imageUrl = $guid;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 16. TÜRK HABER SİTELERİNE ÖZEL PATTERN'LER
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl) {
        // Hürriyet, Sabah, Milliyet gibi sitelerin özel tag'leri
        $turkishTags = [
            'resim', 'gorsel', 'fotograf', 'foto', 'kapak', 'manset',
            'haber_resim', 'haberResim', 'news_photo', 'newsPhoto',
            'ana_gorsel', 'anaGorsel', 'buyuk_resim', 'buyukResim',
            'kucuk_resim', 'kucukResim', 'thumb_url', 'thumbUrl',
        ];
        foreach ($turkishTags as $tag) {
            if (isset($item->$tag) && !empty((string)$item->$tag)) {
                $imageUrl = (string) $item->$tag;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 17. JSON-LD İÇİNDEN (bazı RSS'ler JSON-LD embed ediyor)
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->description)) {
        $desc = (string) $item->description;
        if (preg_match('/"image"\s*:\s*"([^"]+)"/', $desc, $matches)) {
            $imageUrl = $matches[1];
        }
        if (!$imageUrl && preg_match('/"thumbnailUrl"\s*:\s*"([^"]+)"/', $desc, $matches)) {
            $imageUrl = $matches[1];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 18. DATA ATTRIBUTE'LARDAN
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->description)) {
        $desc = (string) $item->description;
        $dataPatterns = [
            '/data-src=["\']([^"\']+)["\']/',
            '/data-lazy-src=["\']([^"\']+)["\']/',
            '/data-original=["\']([^"\']+)["\']/',
            '/data-image=["\']([^"\']+)["\']/',
            '/data-bg=["\']([^"\']+)["\']/',
            '/data-srcset=["\']([^"\']+)["\']/',
        ];
        foreach ($dataPatterns as $pattern) {
            if (preg_match($pattern, $desc, $matches)) {
                $url = $matches[1];
                // srcset ise ilk URL'yi al
                if (strpos($url, ',') !== false) {
                    $url = explode(',', $url)[0];
                    $url = preg_replace('/\s+\d+[wx]$/', '', trim($url));
                }
                if (!empty($url) && strpos($url, 'data:') !== 0) {
                    $imageUrl = $url;
                    break;
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 19. STYLE ATTRIBUTE'DAN BACKGROUND IMAGE
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->description)) {
        $desc = (string) $item->description;
        if (preg_match('/background(?:-image)?\s*:\s*url\(["\']?([^"\')\s]+)["\']?\)/', $desc, $matches)) {
            $imageUrl = $matches[1];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 20. FIGURE/PICTURE TAG İÇİNDEN
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl && isset($item->description)) {
        $desc = (string) $item->description;
        // figure içindeki img
        if (preg_match('/<figure[^>]*>.*?<img[^>]+src=["\']([^"\']+)["\'].*?<\/figure>/is', $desc, $matches)) {
            $imageUrl = $matches[1];
        }
        // picture içindeki source veya img
        if (!$imageUrl && preg_match('/<picture[^>]*>.*?(?:<source[^>]+srcset=["\']([^"\']+)["\']|<img[^>]+src=["\']([^"\']+)["\']).*?<\/picture>/is', $desc, $matches)) {
            $imageUrl = !empty($matches[1]) ? explode(',', $matches[1])[0] : $matches[2];
            $imageUrl = preg_replace('/\s+\d+[wx]$/', '', trim($imageUrl));
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // 21. CDATA İÇİNDEN
    // ═══════════════════════════════════════════════════════════════════
    if (!$imageUrl) {
        // XML'i string olarak al ve CDATA içinden img ara
        $xmlString = $item->asXML();
        if (preg_match('/<!\[CDATA\[(.*?)\]\]>/s', $xmlString, $cdataMatches)) {
            $cdataContent = $cdataMatches[1];
            $imageUrl = extractFirstImageFromHtml($cdataContent);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // URL'Yİ DÜZELT VE DÖNDÜR
    // ═══════════════════════════════════════════════════════════════════
    if ($imageUrl) {
        $imageUrl = fixImageUrl($imageUrl, $feedUrl);
        
        // Geçerli görsel mi kontrol et
        if (!isValidImageUrl($imageUrl)) {
            $imageUrl = null;
        }
    }
    
    return $imageUrl;
}

/**
 * HTML içinden ilk geçerli img tag'inin src'sini çıkar
 */
function extractFirstImageFromHtml($html)
{
    if (empty($html)) return null;
    
    // Önce tüm img tag'lerini bul
    $patterns = [
        // Standart img src
        '/<img[^>]+src=["\']([^"\']+)["\'][^>]*>/i',
        // Tırnaksız src
        '/<img[^>]+src=([^\s>]+)[^>]*>/i',
        // data-src (lazy load)
        '/<img[^>]+data-src=["\']([^"\']+)["\'][^>]*>/i',
        '/<img[^>]+data-lazy-src=["\']([^"\']+)["\'][^>]*>/i',
        '/<img[^>]+data-original=["\']([^"\']+)["\'][^>]*>/i',
        // srcset'ten ilk URL
        '/<img[^>]+srcset=["\']([^"\']+)["\'][^>]*>/i',
        // source tag (picture element)
        '/<source[^>]+srcset=["\']([^"\']+)["\'][^>]*>/i',
        // Direkt görsel URL pattern
        '/https?:\/\/[^\s"\'<>]+\.(jpg|jpeg|png|gif|webp)(\?[^\s"\'<>]*)?/i',
    ];
    
    foreach ($patterns as $pattern) {
        if (preg_match_all($pattern, $html, $matches)) {
            foreach ($matches[1] as $url) {
                // srcset ise ilk URL'yi al
                if (strpos($url, ',') !== false) {
                    $url = explode(',', $url)[0];
                    $url = preg_replace('/\s+\d+[wx]$/', '', trim($url));
                }
                
                $url = trim($url);
                
                // Geçersiz URL'leri atla
                if (empty($url)) continue;
                if (strpos($url, 'data:') === 0) continue;
                if (strpos($url, 'about:') === 0) continue;
                if (strpos($url, 'javascript:') === 0) continue;
                
                // Placeholder/spacer görselleri atla
                $skipPatterns = [
                    '1x1', 'pixel', 'spacer', 'blank', 'empty', 'transparent',
                    'placeholder', 'loading', 'lazy', 'grey', 'gray',
                    'avatar', 'icon', 'logo', 'sprite', 'button',
                    'ad_', 'ads_', 'banner_', 'promo_',
                    '.gif', // Çoğu gif placeholder
                ];
                
                $skip = false;
                foreach ($skipPatterns as $skipPattern) {
                    if (stripos($url, $skipPattern) !== false) {
                        // .gif için istisna - büyük gif'ler olabilir
                        if ($skipPattern === '.gif') {
                            // URL'de boyut bilgisi varsa ve büyükse atla
                            if (!preg_match('/\d{3,}x\d{3,}/', $url)) {
                                $skip = true;
                            }
                        } else {
                            $skip = true;
                        }
                        break;
                    }
                }
                
                if ($skip) continue;
                
                // Minimum boyut kontrolü (URL'de boyut varsa)
                if (preg_match('/(\d+)x(\d+)/', $url, $sizeMatches)) {
                    $width = (int) $sizeMatches[1];
                    $height = (int) $sizeMatches[2];
                    if ($width < 100 || $height < 100) continue;
                }
                
                return $url;
            }
        }
    }
    
    return null;
}

/**
 * Görsel URL'sini düzelt
 */
function fixImageUrl($url, $feedUrl = '')
{
    if (empty($url)) return null;
    
    $url = trim($url);
    
    // HTML entities decode
    $url = html_entity_decode($url, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    
    // Çift encode'u düzelt
    if (strpos($url, '%25') !== false) {
        $url = urldecode($url);
    }
    
    // Zaten tam URL ise
    if (strpos($url, 'http://') === 0 || strpos($url, 'https://') === 0) {
        return cleanImageUrl($url);
    }
    
    // Protocol-relative URL (//example.com/image.jpg)
    if (strpos($url, '//') === 0) {
        return cleanImageUrl('https:' . $url);
    }
    
    // Relative URL ise feed URL'den base al
    if (!empty($feedUrl)) {
        $parsed = parse_url($feedUrl);
        if (isset($parsed['scheme']) && isset($parsed['host'])) {
            $base = $parsed['scheme'] . '://' . $parsed['host'];
            
            if (strpos($url, '/') === 0) {
                return cleanImageUrl($base . $url);
            } else {
                // Path'i de ekle
                $path = isset($parsed['path']) ? dirname($parsed['path']) : '';
                return cleanImageUrl($base . $path . '/' . $url);
            }
        }
    }
    
    return null;
}

/**
 * URL'yi temizle
 */
function cleanImageUrl($url)
{
    // Çift slash düzelt (protocol hariç)
    $url = preg_replace('#(?<!:)//+#', '/', $url);
    $url = str_replace(['http:/', 'https:/'], ['http://', 'https://'], $url);
    
    // Boşlukları encode et
    $url = str_replace(' ', '%20', $url);
    
    // Türkçe karakterleri encode et
    $url = preg_replace_callback('/[ğüşıöçĞÜŞİÖÇ]/u', function($m) {
        return rawurlencode($m[0]);
    }, $url);
    
    return $url;
}

/**
 * Görsel URL'sinin geçerli olup olmadığını kontrol et
 */
function isValidImageUrl($url)
{
    if (empty($url)) return false;
    if (strlen($url) < 10) return false;
    if (strlen($url) > 2000) return false;
    
    // Geçerli protokol
    if (strpos($url, 'http://') !== 0 && strpos($url, 'https://') !== 0) {
        return false;
    }
    
    // Uzantı kontrolü
    $path = parse_url($url, PHP_URL_PATH);
    if ($path) {
        $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        $validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'tiff', 'ico'];
        
        // Uzantı varsa ve geçersizse reddet
        if (!empty($ext) && !in_array($ext, $validExtensions)) {
            // CDN URL'leri uzantısız olabilir
            $cdnPatterns = ['cloudinary', 'imgix', 'cloudfront', 'akamai', 'fastly', 'cdn', 'image', 'photo', 'media', 'static'];
            $isCdn = false;
            foreach ($cdnPatterns as $pattern) {
                if (stripos($url, $pattern) !== false) {
                    $isCdn = true;
                    break;
                }
            }
            if (!$isCdn) return false;
        }
    }
    
    return true;
}
