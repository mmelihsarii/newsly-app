-- ============================================================================
-- tbl_news.source_name'i category_id'ye göre güncelle
-- 
-- ÖNEMLİ: Bu SQL'i çalıştırmadan önce:
-- 1. Backup al: CREATE TABLE tbl_news_backup AS SELECT * FROM tbl_news;
-- 2. Kendi category_id değerlerini kontrol et (Admin Panel > Kategoriler)
-- 3. Aşağıdaki CASE WHEN'deki ID'leri kendi ID'lerinle değiştir
-- 
-- Tarih: 19 Ocak 2026
-- ============================================================================

-- ============================================================================
-- ADIM 1: MEVCUT DURUMU KONTROL ET
-- ============================================================================

-- Toplam haber ve NULL source_name sayısı
SELECT 
    COUNT(*) as toplam_haber, 
    SUM(CASE WHEN source_name IS NULL OR source_name = '' THEN 1 ELSE 0 END) as null_source_name,
    ROUND(SUM(CASE WHEN source_name IS NULL OR source_name = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as null_yuzde
FROM tbl_news;

-- Kategori dağılımı
SELECT 
    c.id as category_id,
    c.category_name,
    COUNT(n.id) as haber_sayisi
FROM tbl_category c
LEFT JOIN tbl_news n ON n.category_id = c.id
GROUP BY c.id, c.category_name
ORDER BY haber_sayisi DESC;

-- ============================================================================
-- ADIM 2: BACKUP AL (ÇOK ÖNEMLİ!)
-- ============================================================================

-- Backup tablosu oluştur
CREATE TABLE IF NOT EXISTS tbl_news_backup_20260119 AS SELECT * FROM tbl_news;

-- Backup kontrolü
SELECT COUNT(*) as backup_satir_sayisi FROM tbl_news_backup_20260119;

-- ============================================================================
-- ADIM 3: CASE WHEN İLE TOPLU GÜNCELLEME
-- ============================================================================

-- ⚠️ AŞAĞIDAKİ ID'LERİ KENDİ KATEGORİ ID'LERİNLE DEĞİŞTİR!
-- Admin Panel > Kategoriler bölümünden kontrol et

UPDATE tbl_news 
SET source_name = CASE category_id
    -- ═══════════════════════════════════════════════════════════════════════
    -- GÜNDEM KATEGORİSİ (Örnek ID'ler)
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 1 THEN 'NTV'
    WHEN 2 THEN 'CNN Türk'
    WHEN 3 THEN 'Habertürk'
    WHEN 4 THEN 'TRT Haber'
    WHEN 5 THEN 'A Haber'
    WHEN 6 THEN 'Hürriyet'
    WHEN 7 THEN 'Sözcü'
    WHEN 8 THEN 'Sabah'
    WHEN 9 THEN 'Haber Global'
    WHEN 10 THEN 'Milliyet'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- SPOR KATEGORİSİ
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 20 THEN 'A Spor'
    WHEN 21 THEN 'Fotomaç'
    WHEN 22 THEN 'Kontraspor'
    WHEN 23 THEN 'Fotospor'
    WHEN 24 THEN 'Fanatik'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- EKONOMİ KATEGORİSİ
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 30 THEN 'Bloomberg HT'
    WHEN 31 THEN 'BigPara'
    WHEN 32 THEN 'Forbes Türkiye'
    WHEN 33 THEN 'Finans Gündem'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- TEKNOLOJİ KATEGORİSİ
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 40 THEN 'Webtekno'
    WHEN 41 THEN 'Teknoblog'
    WHEN 42 THEN 'Donanım Haber'
    WHEN 43 THEN 'Technopat'
    WHEN 44 THEN 'Webrazzi'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BİLİM KATEGORİSİ
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 50 THEN 'Evrim Ağacı'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- HABER AJANSLARI
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 60 THEN 'Anadolu Ajansı'
    WHEN 61 THEN 'İHA'
    WHEN 62 THEN 'DHA'
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- DİJİTAL MEDYA
    -- ═══════════════════════════════════════════════════════════════════════
    WHEN 70 THEN 'T24'
    WHEN 71 THEN 'Oda TV'
    WHEN 72 THEN 'Diken'
    WHEN 73 THEN 'Gazete Duvar'
    WHEN 74 THEN 'Independent Türkiye'
    WHEN 75 THEN 'Halk TV'
    WHEN 76 THEN 'Tele1'
    
    -- Eşleşmeyen kategoriler için mevcut değeri koru
    ELSE source_name
END
WHERE source_name IS NULL OR source_name = '';

-- ============================================================================
-- ADIM 4: SONUCU KONTROL ET
-- ============================================================================

-- Güncelleme sonrası NULL sayısı
SELECT 
    COUNT(*) as toplam_haber, 
    SUM(CASE WHEN source_name IS NULL OR source_name = '' THEN 1 ELSE 0 END) as hala_null,
    SUM(CASE WHEN source_name IS NOT NULL AND source_name != '' THEN 1 ELSE 0 END) as dolu
FROM tbl_news;

-- Kaynak dağılımı
SELECT 
    source_name, 
    COUNT(*) as haber_sayisi 
FROM tbl_news 
WHERE source_name IS NOT NULL AND source_name != ''
GROUP BY source_name 
ORDER BY haber_sayisi DESC
LIMIT 30;

-- Hala NULL olanları kontrol et (hangi kategoriler?)
SELECT 
    n.category_id,
    c.category_name,
    COUNT(*) as null_sayisi
FROM tbl_news n
LEFT JOIN tbl_category c ON c.id = n.category_id
WHERE n.source_name IS NULL OR n.source_name = ''
GROUP BY n.category_id, c.category_name
ORDER BY null_sayisi DESC;

-- ============================================================================
-- ADIM 5: GERİ ALMA (SORUN OLURSA)
-- ============================================================================

-- Eğer bir şeyler ters giderse, backup'tan geri yükle:
-- UPDATE tbl_news n
-- INNER JOIN tbl_news_backup_20260119 b ON n.id = b.id
-- SET n.source_name = b.source_name;

-- Veya tamamen geri al:
-- DROP TABLE tbl_news;
-- RENAME TABLE tbl_news_backup_20260119 TO tbl_news;

-- ============================================================================
-- ADIM 6: YENİ HABERLER İÇİN TRİGGER (OPSİYONEL)
-- ============================================================================

-- Yeni haber eklendiğinde otomatik source_name ataması için trigger
-- (Admin panelde haber ekleme formuna source_name alanı eklemek daha iyi)

/*
DELIMITER //
CREATE TRIGGER set_source_name_before_insert
BEFORE INSERT ON tbl_news
FOR EACH ROW
BEGIN
    IF NEW.source_name IS NULL OR NEW.source_name = '' THEN
        SET NEW.source_name = CASE NEW.category_id
            WHEN 1 THEN 'NTV'
            WHEN 2 THEN 'CNN Türk'
            -- ... diğer kategoriler
            ELSE 'Bilinmeyen Kaynak'
        END;
    END IF;
END //
DELIMITER ;
*/
