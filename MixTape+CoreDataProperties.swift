//
//  MixTape+CoreDataProperties.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-05.
//  Copyright © 2020 Michael Long. All rights reserved.
//
//

import Foundation
import CoreData


extension MixTape {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MixTape> {
        return NSFetchRequest<MixTape>(entityName: "MixTape")
    }

    @NSManaged public var title: String?
    @NSManaged public var songs: NSOrderedSet?
    @NSManaged public var numberOfSongs: Int16
    @NSManaged public var urlData: Data?
    
    public var wrappedTitle: String {
        self.title ?? "Unknown MixTape Title"
    }
    
    public var wrappedUrl: URL {
        // return the url that's stored as bookmark data in CoreData db
        
        if let data = self.urlData {
            var isStale = false
            do {
                let url = try URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
                return url
            } catch {
                print(error)
                return URL.init(fileURLWithPath: "No url")
            }
        } else {
            return URL.init(fileURLWithPath: "No url")
        }
        

    }
    
    public var songsArray: [Song] {
        // songsArray property returns Song array sorted by the Song's positionInTape property
        
        if let set = self.songs{
            let array = set.sortedArray { (song1, song2) -> ComparisonResult in
            guard let s1 = song1 as? Song, let s2 = song2 as? Song else {
                return ComparisonResult.orderedSame
                }
                if s1.positionInTape < s2.positionInTape {
                    return ComparisonResult.orderedAscending
                } else if s1.positionInTape == s2.positionInTape {
                    return ComparisonResult.orderedSame
                } else {
                    return ComparisonResult.orderedDescending
                }
            }
            
            return array  as! [Song]
        } else {
            return []
        }
      
    }
    
    func printSongs() {
        print("=================== PRINTING MIXTAPE SONGS")
        for song in self.songsArray{
            print(song.wrappedName)
        }
    }
    
    override public func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        self.objectWillChange.send()
    }
    
    func updateArray(moc: NSManagedObjectContext)  {
        var songsToRemove: [Song] = []
        for song in Array(self.songs!) as! [Song] {
            print(song.wrappedUrl)
            do {
               let goodUrl = try song.wrappedUrl.checkResourceIsReachable()
               if goodUrl {
                   continue
               } else {
                songsToRemove.append(song)
               }
           } catch {
               print(error)
               songsToRemove.append(song)
           }
        }
        
        if !songsToRemove.isEmpty {
            self.willChangeValue(forKey: "songs")
            for song in songsToRemove {
                self.removeFromSongs(song)
            }
            var counter: Int16 = 0
            for song in Array(self.songs!) as! [Song] {
                if song.positionInTape != counter {
                     song.positionInTape = counter
                }
                counter += 1
            }
            try! moc.save()
        }
        
    }

}

// MARK: Generated c for songs
extension MixTape {

    @objc(insertObject:inSongsAtIndex:)
    @NSManaged public func insertIntoSongs(_ value: Song, at idx: Int)

    @objc(removeObjectFromSongsAtIndex:)
    @NSManaged public func removeFromSongs(at idx: Int)

    @objc(insertSongs:atIndexes:)
    @NSManaged public func insertIntoSongs(_ values: [Song], at indexes: NSIndexSet)

    @objc(removeSongsAtIndexes:)
    @NSManaged public func removeFromSongs(at indexes: NSIndexSet)

    @objc(replaceObjectInSongsAtIndex:withObject:)
    @NSManaged public func replaceSongs(at idx: Int, with value: Song)

    @objc(replaceSongsAtIndexes:withSongs:)
    @NSManaged public func replaceSongs(at indexes: NSIndexSet, with values: [Song])

    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: Song)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: Song)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSOrderedSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSOrderedSet)
    
}
