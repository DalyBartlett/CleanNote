//
//  AppDelegate.swift
//  SimpleMemo
//
//  Created by  李俊 on 2017/2/25.
//  Copyright © 2017年 Lijun. All rights reserved.
//

import UIKit
import CoreData
import EvernoteSDK
import SMKit

enum ShortcutItemType: String {
  case newMemo = "com.likumb.Memo.newMemo"
  case paste = "com.likumb.Memo.paste"
}

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var navigationController: UINavigationController?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    let mainController = MemoListViewController()
    navigationController = UINavigationController(rootViewController: mainController)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.backgroundColor = UIColor.white
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()

    loadDefaultMemos()
    loadOldMemos()

    // Need a `EvernoteKey.swift` file, and init `evernoteKey` and `evernoteSecret`.
    ENSession.setSharedSessionConsumerKey(evernoteKey, consumerSecret: evernoteSecret, optionalHost: nil)
    ENSession.shared.fetchSimpleMemoNoteBook()

    UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: SMColor.title]

    return true
  }

  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    let didHandle = ENSession.shared.handleOpenURL(url)
    return didHandle
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    if #available(iOS 10.0, *) {
        CoreDataStack.default.saveContext()
    } else {
        // Fallback on earlier versions
    }
  }

  func applicationWillTerminate(_ application: UIApplication) {
    if #available(iOS 10.0, *) {
        CoreDataStack.default.saveContext()
    } else {
        // Fallback on earlier versions
    }
  }

  func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    var handle = false
    guard let shortcutItemType = ShortcutItemType(rawValue: shortcutItem.type) else {
      completionHandler(handle)
      return
    }
    handle = true
    var text: String? = nil
    switch shortcutItemType {
    case .newMemo:
      break
    case .paste:
      text = UIPasteboard.general.string
    }
    let memoVC =  MemoViewController(text: text)
    navigationController?.pushViewController(memoVC, animated: true)
    completionHandler(handle)
  }

}

private extension AppDelegate {

  func loadDefaultMemos() {
    let oldVersion = UserDefaults.standard.object(forKey: "MemoVersion") as? String
    if oldVersion != nil {
      return
    }

    let dict = Bundle.main.infoDictionary!
    if let version = dict["CFBundleShortVersionString"] as? String {
      UserDefaults.standard.set(version, forKey: "MemoVersion")
    }
    guard let path = Bundle.main.path(forResource: "DefaultMemos", ofType: "plist"),
      let memos = NSArray(contentsOfFile: path) as? [String] else {
      return
    }

    for memoText in memos {
        if #available(iOS 10.0, *) {
            let memo = Memo.newMemo()
            memo.text = memoText
            CoreDataStack.default.saveContext()
        } else {
            // Fallback on earlier versions
        }

    }
  }

  func loadOldMemos() {
    let oldMemos = UserDefaults.standard.object(forKey: "OldMemos") as? String
    if oldMemos != nil { return }

    let memos = OldCoreDataStack.sharded.fetchOldMemos()
    for memo in memos {
        if #available(iOS 10.0, *) {
            let newMemo = Memo.newMemo()
            newMemo.createDate = memo.changeDate
            newMemo.updateDate = Date()
            newMemo.isUpload = memo.isUpload
            newMemo.text = memo.text
            newMemo.noteRef = memo.noteRef
        } else {
            // Fallback on earlier versions
        }

    }

    if #available(iOS 10.0, *) {
        CoreDataStack.default.saveContext()
    } else {
        // Fallback on earlier versions
    }
    UserDefaults.standard.set("OldMemos", forKey: "OldMemos")
  }
}
