import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Firebase'i başlat
    FirebaseApp.configure()
    
    // UNUserNotificationCenter delegate'i ayarla
    UNUserNotificationCenter.current().delegate = self
    
    // Push notification izinlerini iste
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions
    ) { granted, error in
      if let error = error {
        print("Push notification izin hatası: \(error.localizedDescription)")
      }
      print("Push notification izni: \(granted)")
    }
    
    // Remote notifications için kayıt ol
    application.registerForRemoteNotifications()
    
    // FCM delegate'i ayarla
    Messaging.messaging().delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // APNS token alındığında FCM'e ilet
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Token'ı hex string olarak logla (debug için)
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("APNS Token: \(tokenString)")
    
    // FCM'e APNS token'ı ilet
    Messaging.messaging().apnsToken = deviceToken
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // APNS kayıt hatası
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNS kayıt hatası: \(error.localizedDescription)")
  }
  
  // Arka planda bildirim alındığında
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Arka plan bildirimi alındı: \(userInfo)")
    
    // Firebase'e bildir
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    completionHandler(.newData)
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
  
  // Uygulama ön plandayken bildirim göster
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("Ön plan bildirimi: \(userInfo)")
    
    // Firebase'e bildir
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // iOS 14+ için banner, ses ve badge göster
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge, .list]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }
  
  // Bildirime tıklandığında
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("Bildirime tıklandı: \(userInfo)")
    
    // Firebase'e bildir
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM Token: \(fcmToken ?? "nil")")
    
    // Token'ı NotificationCenter ile paylaş (Flutter tarafında dinlenebilir)
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
