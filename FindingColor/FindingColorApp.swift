//
//  FindingColorApp.swift
//  FindingColor
//
//  Created by NohJaisung on 5/27/25.
//

import SwiftUI
import AVFoundation
@main
struct FindingColorApp: App {
    init () {
       

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }

      }
      
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
