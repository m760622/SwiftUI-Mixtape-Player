//
//  MixTapeAdder.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-05.
//  Copyright © 2020 Michael Long. All rights reserved.
//

import Foundation
import SwiftUI
import MobileCoreServices
import AVFoundation
import CoreData

struct MixTapeAdder: UIViewControllerRepresentable {
    
    let moc: NSManagedObjectContext
    let mixTapeToAddTo: MixTape
    @Binding var songs: [Song]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MixTapeAdder>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeAudio)], in: .open)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<MixTapeAdder>) {
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate{
        
        var parent: MixTapeAdder
        
        init (parent_param: MixTapeAdder) {
            self.parent = parent_param
        }
        
        internal func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
            
            let songNames = getArrayOfSongNames(arrayOfSongs: parent.songs)
            var counter = parent.mixTapeToAddTo.numberOfSongs + 1
            
            for url in urls {
                
                if songNames.contains(url.deletingPathExtension().lastPathComponent) {
                    continue // don't add songs that are already in mixtape
                }
                
                let song = Song(context: parent.moc)
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                if didStartAccessing {
                    song.urlData = try! url.bookmarkData()
                    url.stopAccessingSecurityScopedResource()
                } else {
                    print("Could not access url")
                }
                song.name = url.deletingPathExtension().lastPathComponent
                song.positionInTape = counter
                
                parent.mixTapeToAddTo.addToSongs(song)
                parent.songs.append(song)
                
                counter += 1
            }
            
            parent.mixTapeToAddTo.numberOfSongs = counter
            
            do {
               try parent.moc.save()
            } catch {
                print(error)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent_param: self)
    }

    
    typealias UIViewControllerType = UIDocumentPickerViewController

}
