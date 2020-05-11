//
//  ImagePicker.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-10.
//  Copyright © 2020 Michael Long. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import MobileCoreServices
import AVFoundation
import CoreData

struct ImagePickerView: UIViewControllerRepresentable {

    let mixTapes: FetchedResults<MixTape>
    let moc: NSManagedObjectContext
    @Binding var imagePicked: Bool

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeImage)], in: .open)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<ImagePickerView>) {
        
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate{
        
        var parent: ImagePickerView
        
        
        init (parent_param: ImagePickerView) {
            self.parent = parent_param
            

        }
        
        internal func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
            // urls of picked files wil be in array urls
            let tape = parent.mixTapes.last!
            let url = urls[0]
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            if didStartAccessing {
                tape.urlData = try! url.bookmarkData()
                url.stopAccessingSecurityScopedResource()
            } else {
                print("Could not access url")
            }
            
            do {
               try parent.moc.save()
            } catch {
                print(error)
            }
            parent.imagePicked.toggle()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent_param: self)
    }
    


    
    typealias UIViewControllerType = UIDocumentPickerViewController

}


