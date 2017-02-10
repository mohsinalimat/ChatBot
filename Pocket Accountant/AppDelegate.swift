//
//  AppDelegate.swift
//  Pocket Accountant
//
//  Created by Alexandr on 13.01.17.
//  Copyright © 2017 Alexandr. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let storyboard = self.window?.rootViewController?.storyboard
        var root: UIViewController!
        if let _ = UserDefaults.standard.string(forKey: "user") {
            root = storyboard?.instantiateViewController(withIdentifier: "Chat")
        }
        else {
            root = storyboard?.instantiateViewController(withIdentifier: "Login")
        }
        
        window?.rootViewController = root
        window?.makeKeyAndVisible()
        
        return true
    }


}

