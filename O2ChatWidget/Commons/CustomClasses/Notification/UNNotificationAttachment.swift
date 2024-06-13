//
//  UNNotificationAttachment.swift
//  Befiler
//
//  Created by Sanjay on 22/11/2022.
//  Copyright © 2022 Haseeb. All rights reserved.
//

import Foundation

//extension UNNotificationAttachment {
//    
//    static func saveImageToDisk(fileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
//        let fileManager = FileManager.default
//        let folderName = ProcessInfo.processInfo.globallyUniqueString
//        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
//        
//        do {
//            try fileManager.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
//            let fileURL = folderURL?.appendingPathComponent(fileIdentifier)
//            try data.write(to: fileURL!, options: [])
//            let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL!, options: options)
//            return attachment
//        } catch let error {
//            print("error \(error)")
//        }
//        
//        return nil
//    }
//}
