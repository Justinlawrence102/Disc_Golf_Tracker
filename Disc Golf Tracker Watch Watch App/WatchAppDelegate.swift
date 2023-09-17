//
//  WatchAppDelegate.swift
//  LogRide Watch Watch App
//
//  Created by Mark Lawrence on 6/23/23.
//  Copyright © 2023 Justin Lawrence. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

class WatchAppDelegate: NSObject, WKApplicationDelegate {

    let session = WCSession.default

    func applicationDidBecomeActive() {
        print("Active")
        NotificationCenter.default.post(name: .applicationIsActive, object: nil)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    func applicationWillResignActive() {
        print("Disabed")
        NotificationCenter.default.post(name: .applicationBecameInactive, object: nil)
    }
    
    func applicationDidFinishLaunching() {
        session.delegate = self
        session.activate()
    }
}

extension WatchAppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session did active \(activationState)")
    }
}

extension Notification.Name {
    static var applicationIsActive: Notification.Name {
      Notification.Name("applicationIsActive")
    }
    static var applicationBecameInactive: Notification.Name {
      Notification.Name("applicationBecameInactive")
    }
}
