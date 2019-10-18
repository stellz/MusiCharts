//
//  Notifications.swift
//  MusiChart
//
//  Created by Stella on 10.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

enum LastFMNotifications {
    
    static let didScrobbleTrack = "didScrobbleTrack"
}

enum AudioNotifications {
    
    static let audioFailedToPlay = "audioFailedToPlay"
    static let currentSongChanged = "currentSongChanged"
}

enum SongNotification {
    
    static let currentSongChanged = "currentSongChanged"
}

enum TimerNotifications {
    
    static let sleepTimeElapsed = "sleepTimeElapsed"
}

enum StationNotifications {
    
    static let stationDidPlayPause = "stationDidPlayPause"
    static let stationDidChange = "stationDidChange"
}

enum SystemVolumeNotification {
    
    static let didChangeNotification = "AVSystemController_SystemVolumeDidChangeNotification"
    
    static let parameter = "AVSystemController_AudioVolumeNotificationParameter"
}
