-- ============================================================================
-- tbl_news tablosundaki source_name kolonunu URL'e göre güncelle
-- Bu SQL'i phpMyAdmin veya MySQL client'ta çalıştır
-- ============================================================================

-- Önce mevcut durumu kontrol et
SELECT COUNT(*) as total_news, 
       SUM(CASE WHEN source_name IS NULL OR source_name = '' THEN 1 ELSE 0 END) as null_source_names
FROM tbl_news;

-- ============================================================================
-- BÜYÜK MEDYA KURULUŞLARI
-- ============================================================================
UPDATE tbl_news SET source_name = 'NTV' WHERE (other_url LIKE '%ntv.com.tr%' OR source_url LIKE '%ntv.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'CNN Türk' WHERE (other_url LIKE '%cnnturk.com%' OR source_url LIKE '%cnnturk.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'BBC Türkçe' WHERE (other_url LIKE '%bbc.com%' OR source_url LIKE '%bbc.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'TRT Haber' WHERE (other_url LIKE '%trthaber.com%' OR source_url LIKE '%trthaber.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'A Haber' WHERE (other_url LIKE '%ahaber.com%' OR source_url LIKE '%ahaber.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Habertürk' WHERE (other_url LIKE '%haberturk.com%' OR source_url LIKE '%haberturk.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Haber Global' WHERE (other_url LIKE '%haberglobal.com%' OR source_url LIKE '%haberglobal.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'TGRT Haber' WHERE (other_url LIKE '%tgrthaber.com%' OR source_url LIKE '%tgrthaber.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- GAZETELER
-- ============================================================================
UPDATE tbl_news SET source_name = 'Hürriyet' WHERE (other_url LIKE '%hurriyet.com.tr%' OR source_url LIKE '%hurriyet.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Sözcü' WHERE (other_url LIKE '%sozcu.com%' OR source_url LIKE '%sozcu.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Sabah' WHERE (other_url LIKE '%sabah.com.tr%' OR source_url LIKE '%sabah.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Akşam' WHERE (other_url LIKE '%aksam.com.tr%' OR source_url LIKE '%aksam.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Star' WHERE (other_url LIKE '%star.com.tr%' OR source_url LIKE '%star.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Türkiye Gazetesi' WHERE (other_url LIKE '%turkiyegazetesi.com%' OR source_url LIKE '%turkiyegazetesi.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Yeni Şafak' WHERE (other_url LIKE '%yenisafak.com%' OR source_url LIKE '%yenisafak.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Yeniçağ Gazetesi' WHERE (other_url LIKE '%yenicaggazetesi.com%' OR source_url LIKE '%yenicaggazetesi.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Yeni Asır' WHERE (other_url LIKE '%yeniasir.com%' OR source_url LIKE '%yeniasir.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Yeni Akit' WHERE (other_url LIKE '%yeniakit.com%' OR source_url LIKE '%yeniakit.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Yurt Gazetesi' WHERE (other_url LIKE '%yurtgazetesi.com%' OR source_url LIKE '%yurtgazetesi.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Milli Gazete' WHERE (other_url LIKE '%milligazete.com%' OR source_url LIKE '%milligazete.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Dünya Gazetesi' WHERE (other_url LIKE '%dunya.com%' OR source_url LIKE '%dunya.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Milliyet' WHERE (other_url LIKE '%milliyet.com.tr%' OR source_url LIKE '%milliyet.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Cumhuriyet' WHERE (other_url LIKE '%cumhuriyet.com.tr%' OR source_url LIKE '%cumhuriyet.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'BirGün' WHERE (other_url LIKE '%birgun.net%' OR source_url LIKE '%birgun.net%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- DİJİTAL MEDYA
-- ============================================================================
UPDATE tbl_news SET source_name = 'T24' WHERE (other_url LIKE '%t24.com.tr%' OR source_url LIKE '%t24.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Oda TV' WHERE (other_url LIKE '%odatv.com%' OR source_url LIKE '%odatv.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Sol Haber' WHERE (other_url LIKE '%sol.org.tr%' OR source_url LIKE '%sol.org.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Diken' WHERE (other_url LIKE '%diken.com.tr%' OR source_url LIKE '%diken.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Gazete Duvar' WHERE (other_url LIKE '%gazeteduvar.com%' OR source_url LIKE '%gazeteduvar.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Independent Türkiye' WHERE (other_url LIKE '%indyturk.com%' OR source_url LIKE '%indyturk.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Teyit.org' WHERE (other_url LIKE '%teyit.org%' OR source_url LIKE '%teyit.org%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Journo' WHERE (other_url LIKE '%journo.com.tr%' OR source_url LIKE '%journo.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'DW Haber' WHERE (other_url LIKE '%dw.com%' OR source_url LIKE '%dw.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Sputnik' WHERE (other_url LIKE '%sputniknews.com%' OR source_url LIKE '%sputniknews.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Halk TV' WHERE (other_url LIKE '%halktv.com%' OR source_url LIKE '%halktv.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Tele1' WHERE (other_url LIKE '%tele1.com.tr%' OR source_url LIKE '%tele1.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Evrensel' WHERE (other_url LIKE '%evrensel.net%' OR source_url LIKE '%evrensel.net%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Karar' WHERE (other_url LIKE '%karar.com%' OR source_url LIKE '%karar.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- HABER PORTALLARI
-- ============================================================================
UPDATE tbl_news SET source_name = 'Haber 7' WHERE (other_url LIKE '%haber7.com%' OR source_url LIKE '%haber7.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Haberler.com' WHERE (other_url LIKE '%haberler.com%' OR source_url LIKE '%haberler.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'İnternet Haber' WHERE (other_url LIKE '%internethaber.com%' OR source_url LIKE '%internethaber.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'En Son Haber' WHERE (other_url LIKE '%ensonhaber.com%' OR source_url LIKE '%ensonhaber.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Mynet' WHERE (other_url LIKE '%mynet.com%' OR source_url LIKE '%mynet.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- SPOR
-- ============================================================================
UPDATE tbl_news SET source_name = 'A Spor' WHERE (other_url LIKE '%aspor.com%' OR source_url LIKE '%aspor.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Fotomaç' WHERE (other_url LIKE '%fotomac.com%' OR source_url LIKE '%fotomac.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Fotospor' WHERE (other_url LIKE '%fotospor.com%' OR source_url LIKE '%fotospor.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Fanatik' WHERE (other_url LIKE '%fanatik.com%' OR source_url LIKE '%fanatik.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Kontraspor' WHERE (other_url LIKE '%kontraspor.com%' OR source_url LIKE '%kontraspor.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Takvim Spor' WHERE (other_url LIKE '%takvim.com.tr/spor%' OR source_url LIKE '%takvim.com.tr/spor%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- EKONOMİ
-- ============================================================================
UPDATE tbl_news SET source_name = 'Bloomberg HT' WHERE (other_url LIKE '%bloomberght.com%' OR source_url LIKE '%bloomberght.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'BigPara' WHERE (other_url LIKE '%bigpara.com%' OR source_url LIKE '%bigpara.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Forbes Türkiye' WHERE (other_url LIKE '%forbes.com.tr%' OR source_url LIKE '%forbes.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Finans Gündem' WHERE (other_url LIKE '%finansgundem.com%' OR source_url LIKE '%finansgundem.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- TEKNOLOJİ
-- ============================================================================
UPDATE tbl_news SET source_name = 'Webtekno' WHERE (other_url LIKE '%webtekno.com%' OR source_url LIKE '%webtekno.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Teknoblog' WHERE (other_url LIKE '%teknoblog.com%' OR source_url LIKE '%teknoblog.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Donanım Haber' WHERE (other_url LIKE '%donanimhaber.com%' OR source_url LIKE '%donanimhaber.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Technopat' WHERE (other_url LIKE '%technopat.net%' OR source_url LIKE '%technopat.net%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Webrazzi' WHERE (other_url LIKE '%webrazzi.com%' OR source_url LIKE '%webrazzi.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- BİLİM
-- ============================================================================
UPDATE tbl_news SET source_name = 'Evrim Ağacı' WHERE (other_url LIKE '%evrimagaci.org%' OR source_url LIKE '%evrimagaci.org%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- HABER AJANSLARI
-- ============================================================================
UPDATE tbl_news SET source_name = 'Anadolu Ajansı' WHERE (other_url LIKE '%aa.com.tr%' OR source_url LIKE '%aa.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'İHA' WHERE (other_url LIKE '%iha.com.tr%' OR source_url LIKE '%iha.com.tr%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'DHA' WHERE (other_url LIKE '%dha.com.tr%' OR source_url LIKE '%dha.com.tr%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- YABANCI KAYNAKLAR
-- ============================================================================
UPDATE tbl_news SET source_name = 'Al Jazeera' WHERE (other_url LIKE '%aljazeera.com%' OR source_url LIKE '%aljazeera.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'Euro News' WHERE (other_url LIKE '%euronews.com%' OR source_url LIKE '%euronews.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'France 24' WHERE (other_url LIKE '%france24.com%' OR source_url LIKE '%france24.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'The Guardian' WHERE (other_url LIKE '%theguardian.com%' OR source_url LIKE '%theguardian.com%') AND (source_name IS NULL OR source_name = '');
UPDATE tbl_news SET source_name = 'The New York Times' WHERE (other_url LIKE '%nytimes.com%' OR source_url LIKE '%nytimes.com%') AND (source_name IS NULL OR source_name = '');

-- ============================================================================
-- Sonucu kontrol et
-- ============================================================================
SELECT source_name, COUNT(*) as count 
FROM tbl_news 
WHERE source_name IS NOT NULL AND source_name != ''
GROUP BY source_name 
ORDER BY count DESC
LIMIT 50;

-- Hala NULL olanları kontrol et
SELECT COUNT(*) as still_null FROM tbl_news WHERE source_name IS NULL OR source_name = '';
