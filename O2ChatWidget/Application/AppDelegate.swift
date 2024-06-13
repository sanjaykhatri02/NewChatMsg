//
//  AppDelegate.swift
//  O2ChatWidget
//
//  Created by Sanjay Kumar on 13/05/2024.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit
import UserNotifications
import SwiftEventBus

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate  {
    
    let gcmMessageIDKey = "gcm.message_id"
    var dbChatObj = Singleton.sharedInstance.myLocalChatDB
    
    let notificationDelegate = SampleNotificationDelegate()
    
    // MARK: - Properties
    
    static let shared = AppDelegate()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dbChatObj.CreateChatDatabase()
        self.saveInitialUserData()
        self.registerForPushNotifications(application: application)
        if launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            //other required code
            handleNotificationWhenAppIsKilled(launchOptions)
        }
        
        return true
    }
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

extension AppDelegate{
    
    func saveInitialUserData()
    {
        
        CustomUserDefaultChat.sheard.saveCustomerEmail(CustomerEmail: "testwidget@gmail.com")
        CustomUserDefaultChat.sheard.saveCustomerPhoneNumber(customerPhoneNumber: "929239838389")
        CustomUserDefaultChat.sheard.saveCustomerCnic(customerCnic: "9328984892399")
        CustomUserDefaultChat.sheard.saveCustomerName(customerName: "Test Widget")
        CustomUserDefaultChat.sheard.saveCustomerId(customerId: 1220)
        CustomUserDefaultChat.sheard.saveConversationUuID(conversationUuID: "A653E144-7D6E-4572-98B5-0440DD6131B1")
        CustomUserDefaultChat.sheard.saveChannelId(channelId: "f26a33d9-5b2e-4227-a456-eab45924a1d3")
        
    }
    
    func registerForPushNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *){
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
                if (granted)
                {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                else{
                    //Do stuff if unsuccessful...
                }
            })
        }
        else { //If user is not on iOS 10 use the old methods we've been using
            let notificationSettings = UIUserNotificationSettings(
                types: [.badge, .sound, .alert], categories: nil)
            application.registerUserNotificationSettings(notificationSettings)
            
        }
        
        Messaging.messaging().delegate = self
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        CustomUserDefaultChat.sheard.setFcmToken(token: fcmToken!)
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        //getAppConfigApi()
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    
    //@available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent: UNNotification,
                                withCompletionHandler: @escaping (UNNotificationPresentationOptions)->()) {
        
        let userInfo = willPresent.request.content.userInfo
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // ...
        
        // Print full message.
        print(userInfo)
        
        guard let aps = userInfo[AnyHashable("aps")] as? NSDictionary,
              let alert = aps["alert"] as? NSDictionary,
              let body = alert["body"] as? String,
              let title = alert["title"] as? String
                //              let id = alert["notificationId"] as? String
                
        else{
            
            return
        }
        
        let conversationuid = userInfo[AnyHashable("conversationuid")] as? String ?? ""
        let count = "0"//userInfo[AnyHashable("count")] as? String ?? "0"
        if conversationuid != "" && conversationuid != nil{
            //CustomUserDefaultChat.sheard.saveCustomerUidFromServer(id: conversationuid)
            CustomUserDefaultChat.sheard.saveConversationCountFromServer(count: count)
            CustomUserDefaultChat.sheard.saveConversationUuID(conversationUuID: conversationuid)
            SwiftEventBus.post("refreshChatBadgeCount")
        }
        
        
        
        withCompletionHandler([.alert, .sound, .badge]) //For other notifications
        
    }//TEST
    
    //@available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive: UNNotificationResponse,
                                withCompletionHandler: @escaping ()->()) {
        
        let userInfo = didReceive.notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
        guard let aps = userInfo[AnyHashable("aps")] as? NSDictionary,
              let alert = aps["alert"] as? NSDictionary,
              let body = alert["body"] as? String,
              let title = alert["title"] as? String
                
        else{
            
            return
        }
        
        let conversationuid = userInfo[AnyHashable("conversationuid")] as? String ?? ""
        let count = userInfo[AnyHashable("count")] as? String ?? "0"
        if conversationuid != "" && conversationuid != nil{
            //CustomUserDefaultChat.sheard.saveCustomerUidFromServer(id: conversationuid)
            CustomUserDefaultChat.sheard.saveConversationCountFromServer(count: count)
            CustomUserDefaultChat.sheard.saveConversationUuID(conversationUuID: conversationuid)
            onTapChatNotification(conversationuid: conversationuid)
        }else{
            let notificationId = userInfo[AnyHashable("notificationId")] as? String ?? ""
            let notificationCategoryId = userInfo[AnyHashable("notificationCategoryId")] as? String ?? ""
            let recordId = userInfo[AnyHashable("recordId")] as? String ?? ""
            onTapNotification(notificationCategoryId: notificationCategoryId, notificationId: notificationId, recordId: recordId)
        }
        
        
        
        withCompletionHandler() //For other notifications
        
    }//TEST
    
    
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                     deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM token: \(String(describing: token))")
                //            var fcmRegTokenMessage : String  = "\(token)"
                CustomUserDefaultChat.sheard.setFcmToken(token: token )
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    //self.getAppConfigApi()
                }
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
        print("Error token: \(String(describing: error))")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        
        //        UIApplication.shared.applicationIconBadgeNumber = 1
        
        if let text = userInfo["text"] {
        }
        
        // Print full message.
        print(userInfo)
        
    }
    
    
    /*
     * RECEIVE NOTIFICATION WHEN THE APP RUNNING IN THE BACKGROUND
     */
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        //        UIApplication.shared.applicationIconBadgeNumber = 1
        
        
        if let messageID = userInfo[gcmMessageIDKey] {
            // Utils.printDebug("Message ID: \(messageID)")
        }
        
        if let text = userInfo["text"] {
            //            let icdParser = InComingDataParser(content: text as? String)
            //            icdParser.proccess(pushNotification: true)
            completionHandler(UIBackgroundFetchResult.newData)
            return
            
        }
        
        
        // Utils.printDebug("\(userInfo)")
        
        completionHandler(UIBackgroundFetchResult.newData)
    }//TEST
    
}

extension AppDelegate{
    
    func onTapNotification(notificationCategoryId : String, notificationId : String, recordId : String){
        let payload : [String: String] = ["NotificationCategoryId" : notificationCategoryId, "NotificationId" : notificationId, "recordId" : recordId]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "appPushNotification"), object: nil, userInfo: payload)
        
    }
    
    func onTapChatNotification(conversationuid : String){
        let payload : [String: String] = ["conversationuid" : conversationuid]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "chatAppPushNotification"), object: nil, userInfo: payload)
        
    }
}

extension AppDelegate{
    func configureNotification() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            center.delegate = notificationDelegate
            let openAction = UNNotificationAction(identifier: "OpenNotification", title: NSLocalizedString("Abrir", comment: ""), options: UNNotificationActionOptions.foreground)
            let deafultCategory = UNNotificationCategory(identifier: "CustomSamplePush", actions: [openAction], intentIdentifiers: [], options: [])
            center.setNotificationCategories(Set([deafultCategory]))
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
}

extension AppDelegate{
    func handleNotificationWhenAppIsKilled(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Check if launched from the remote notification and application is close
        if let remoteNotification = launchOptions?[.remoteNotification] as?  [AnyHashable : Any] {
            //UserDefaults.standard.set(true, forKey: "From")
            let info = remoteNotification
            
            let conversationuid = info[AnyHashable("conversationuid")] as? String ?? ""
            let count = info[AnyHashable("count")] as? String ?? "0"
            if conversationuid != "" && conversationuid != nil{
                //CustomUserDefaultChat.sheard.saveCustomerUidFromServer(id: conversationuid)
                CustomUserDefaultChat.sheard.saveConversationCountFromServer(count: count)
                CustomUserDefaultChat.sheard.saveConversationUuID(conversationUuID: conversationuid)
                CustomUserDefaultChat.sheard.setChatNotificationBool(value: true)
                
            }else{
                var notificationData : NotificationData!
                let notificationCategoryId = info[AnyHashable("notificationCategoryId")] as? String ?? ""
                let notificationId = info[AnyHashable("notificationId")] as? String ?? ""
                let recordId = info[AnyHashable("recordId")] as? String ?? "0"
                let urlImageString = info[AnyHashable("imageUrl")] as? String ?? ""
                
                notificationData = NotificationData(notificationId: notificationId, notificationCategoryId: notificationCategoryId, recordId: recordId, urlImageString: urlImageString)
                CustomUserDefaultChat.sheard.setNotificationBool(value: true)
                CustomUserDefaultChat.sheard.setNotificationData(notificationData: notificationData)
                
            }
            
            
            
        }
    }
}
