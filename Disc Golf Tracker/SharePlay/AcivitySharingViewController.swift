//
//  AcivitySharingViewController.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/10/23.
//
import GroupActivities
import SwiftUI
import UIKit

struct ActivitySharingViewController: UIViewControllerRepresentable {

    let activity: GroupActivity

    func makeUIViewController(context: Context) -> GroupActivitySharingController {
        return try! GroupActivitySharingController(activity)
    }

    func updateUIViewController(_ uiViewController: GroupActivitySharingController, context: Context) { }
}
