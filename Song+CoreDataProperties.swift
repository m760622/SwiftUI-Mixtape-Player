//
//  Song+CoreDataProperties.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-07.
//  Copyright © 2020 Michael Long. All rights reserved.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var name: String?
    @NSManaged public var urlData: Data?
    @NSManaged public var positionInTape: Int16
    @NSManaged public var mixTape: MixTape?
    
    public var wrappedName: String {
        self.name ?? "Unknown Song Name"
    }
    
    public var wrappedUrl: URL {
        // return the url that's stored as bookmark data in CoreData db
        
        var isStale = false
        do {
            let url = try URL.init(resolvingBookmarkData: self.urlData!, bookmarkDataIsStale: &isStale)
            return url
        } catch {
            print(error)
            return URL.init(fileURLWithPath: "No url")
        }
    }
}
