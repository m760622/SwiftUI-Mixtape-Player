//
//  Utils.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-09.
//  Copyright © 2020 Michael Long. All rights reserved.
//

import Foundation
import AVKit
import CoreData

func getColorFor(song: Song, player: AVQueuePlayer) -> UIColor {
    if song.wrappedName == getItemName(playerItem: player.currentItem) {
        return .red
    } else {
        return .white
    }
}

func checkSongUrlIsReachable(song: Song) -> Bool {
    // Checks is url stored in song is still reachable, song at url could be renamed or deleted
    
    do {
        let goodUrl = try song.wrappedUrl.checkResourceIsReachable()
       return goodUrl
    } catch {
        print(error)
        return false
    }
   
}

func checkItemUrlIsReachable(playerItem: AVPlayerItem) -> Bool {
    // Checks is url stored in song is still reachable, song at url could be renamed or deleted
    
    if let url = getUrlFromPlayerItem(playerItem: playerItem) {
        do {
            let goodUrl = try url.checkResourceIsReachable()
            return goodUrl
        } catch {
            print(error)
            return false
        }
    } else {
        return false
    }
   
}

func getArrayOfSongNames(arrayOfPlayerItems: [AVPlayerItem]) -> [String] {
    // returns an array of all song names given an array of AVPlayerItems
    
    var arrayOfSongNames: [String] = []
    for item in arrayOfPlayerItems {
        arrayOfSongNames.append(getItemName(playerItem: item))
    }
    return arrayOfSongNames
}


func getArrayOfSongNames(arrayOfSongs: [Song]) -> [String] {
    // returns an array of all song names given an array of Song
    
    var arrayOfSongNames: [String] = []
    for song in arrayOfSongs {
        arrayOfSongNames.append(song.wrappedName)
    }
    return arrayOfSongNames
}


func loadPlayer(arrayOfPlayerItems: [AVPlayerItem], player: AVQueuePlayer) {
    // Removes all item from an AVQueuePlayer then loads an it with an array of AVPlayerItem
    
    player.removeAllItems()
    for item in arrayOfPlayerItems{
        player.insert(item, after: nil)
    }
}


func createArrayOfPlayerItems(songs: [Song]) -> [AVPlayerItem] {
    // Given an array of Song return an array of AVPlayerItem
    
    var arrayOfPlayerItems: [AVPlayerItem] = []
    for song in songs {
        let songUrl = song.wrappedUrl
        arrayOfPlayerItems.append(AVPlayerItem(url: songUrl))
    }
    return arrayOfPlayerItems
}


func getItemName(playerItem: AVPlayerItem?) -> String {
    // Returns the name of song in AVPlayerItem
    
    if let item = playerItem {
        if let url  = getUrlFromPlayerItem(playerItem: item){
            return url.deletingPathExtension().lastPathComponent
        } else {
            return "Not Playing"
        }
    } else {
        return "Not Playing"
    }
}

func getIsPlaying(status: AVPlayer.TimeControlStatus?) -> Bool {
    // Returns the true if the AVQueuePlayer is currently playing
    
    if let arg = status {
        if arg.rawValue == 2 {
            return true
        } else {
            return false
        }
    } else {
        return false
    }
        
}

func getUrlFromPlayerItem(playerItem: AVPlayerItem) -> URL? {
    
     if let url  = (((playerItem.asset) as? AVURLAsset)?.url) {
        return url
     } else {
        return nil
    }
       
    
    
}



