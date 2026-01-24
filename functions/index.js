/**
 * Newsly - Akıllı Bildirim Cloud Functions
 * 
 * Bundle ve E-Gündem gibi "az ve öz" bildirim sistemi
 * 
 * Kurulum:
 * 1. cd functions
 * 2. npm install
 * 3. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const Parser = require('rss-parser');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const parser = new Parser();

// ============================================
// AYARLAR
// ============================================

// Güvenilir haber kaynakları (sadece bunlardan bildirim atılır)
const MASTER_SOURCES = [
  { name: 'TRT Haber', url: 'https://www.trthaber.com/sondakika.rss' },
  { name: 'Anadolu Ajansı', url: 'https://www.aa.com.tr/tr/rss/default?cat=guncel' },
];

// Aciliyet belirten anahtar kelimeler
const BREAKING_KEYWORDS = [
  'son dakika',
  'flaş',
  'acil',
  'deprem',
  'savaş',
  'patlama',
  'saldırı',
  'ölü',
  'yaralı',
  'seçim sonuçları',
  'cumhurbaşkanı',
  'başbakan',
  'meclis',
  'tsunami',
  'sel felaketi',
];

// Soğuma süresi (dakika)
const COOLDOWN_MINUTES = 15;

// ============================================
// ANA FONKSİYON: Her 5 dakikada RSS kontrol et
// ============================================

exports.checkBreakingNews = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    console.log('🔍 Son dakika haberleri kontrol ediliyor...');
    
    try {
      // 1. Ayarları al
      const configDoc = await db.collection('notification_settings').doc('config').get();
      const config = configDoc.exists ? configDoc.data() : {};
      
      // Bildirimler kapalıysa çık
      if (config.enabled === false) {
        console.log('🔕 Bildirimler devre dışı');
        return null;
      }
      
      // 2. Cooldown kontrolü
      const lastNotificationTime = config.last_notification_time?.toDate() || new Date(0);
      const now = new Date();
      const minutesSinceLast = (now - lastNotificationTime) / (1000 * 60);
      
      if (minutesSinceLast < COOLDOWN_MINUTES) {
        console.log(`⏳ Cooldown aktif: ${Math.round(COOLDOWN_MINUTES - minutesSinceLast)} dakika kaldı`);
        return null;
      }
      
      // 3. Master kaynaklardan haberleri çek
      let breakingNews = null;
      
      for (const source of MASTER_SOURCES) {
        try {
          const feed = await parser.parseURL(source.url);
          
          for (const item of feed.items.slice(0, 10)) {
            const title = item.title || '';
            const titleLower = title.toLowerCase();
            
            // Keyword kontrolü
            const hasKeyword = BREAKING_KEYWORDS.some(keyword => 
              titleLower.includes(keyword.toLowerCase())
            );
            
            if (!hasKeyword) continue;
            
            // Daha önce gönderilmiş mi?
            const hash = hashTitle(title);
            const sentDoc = await db.collection('sent_notifications').doc(hash).get();
            
            if (sentDoc.exists) {
              console.log(`⏭️ Zaten gönderilmiş: ${title.substring(0, 50)}...`);
              continue;
            }
            
            // Bu haberi gönder!
            breakingNews = {
              title: title,
              url: item.link || '',
              source: source.name,
              hash: hash,
              pubDate: item.pubDate,
            };
            break;
          }
          
          if (breakingNews) break;
          
        } catch (e) {
          console.error(`RSS hatası (${source.name}):`, e.message);
        }
      }
      
      // 4. Gönderilecek haber yoksa çık
      if (!breakingNews) {
        console.log('✅ Bildirilecek yeni son dakika haberi yok');
        return null;
      }
      
      // 5. Bildirim gönder
      console.log(`📤 Bildirim gönderiliyor: ${breakingNews.title}`);
      
      const message = {
        notification: {
          title: '🔴 Son Dakika',
          body: breakingNews.title,
        },
        data: {
          type: 'breaking_news',
          url: breakingNews.url,
          source: breakingNews.source,
        },
        topic: 'breaking_news',
        android: {
          priority: 'high',
          notification: {
            channelId: 'breaking_news',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      const response = await messaging.send(message);
      console.log('✅ Bildirim gönderildi:', response);
      
      // 6. Kayıtları güncelle
      await db.collection('notification_settings').doc('config').set({
        last_notification_time: admin.firestore.FieldValue.serverTimestamp(),
        last_notification_title: breakingNews.title,
        enabled: true,
      }, { merge: true });
      
      await db.collection('sent_notifications').doc(breakingNews.hash).set({
        title: breakingNews.title,
        url: breakingNews.url,
        source: breakingNews.source,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // 7. İstatistik güncelle
      await db.collection('notification_stats').doc('daily').set({
        [getDateKey()]: admin.firestore.FieldValue.increment(1),
      }, { merge: true });
      
      return null;
      
    } catch (error) {
      console.error('❌ Bildirim hatası:', error);
      return null;
    }
  });

// ============================================
// YARDIMCI FONKSİYONLAR
// ============================================

// Başlık hash'i oluştur (duplicate kontrolü için)
function hashTitle(title) {
  return crypto
    .createHash('md5')
    .update(title.toLowerCase().trim())
    .digest('hex')
    .substring(0, 16);
}

// Tarih key'i oluştur (istatistik için)
function getDateKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

// ============================================
// MANUEL BİLDİRİM (Admin Panel için)
// ============================================

exports.sendManualNotification = functions.https.onCall(async (data) => {
  const { title, body, url, topic } = data;
  
  if (!title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'title ve body gerekli');
  }
  
  const message = {
    notification: { title, body },
    data: { url: url || '', type: 'manual' },
    topic: topic || 'all_users',
  };
  
  try {
    const response = await messaging.send(message);
    console.log('Manuel bildirim gönderildi:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Manuel bildirim hatası:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================
// ESKİ BİLDİRİMLERİ TEMİZLE (Haftalık)
// ============================================

exports.cleanupOldNotifications = functions.pubsub
  .schedule('every sunday 03:00')
  .timeZone('Europe/Istanbul')
  .onRun(async () => {
    console.log('🧹 Eski bildirimler temizleniyor...');
    
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const oldNotifications = await db.collection('sent_notifications')
        .where('sent_at', '<', thirtyDaysAgo)
        .limit(500)
        .get();
      
      const batch = db.batch();
      oldNotifications.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      
      console.log(`✅ ${oldNotifications.size} eski bildirim silindi`);
      return null;
    } catch (error) {
      console.error('Temizlik hatası:', error);
      return null;
    }
  });
