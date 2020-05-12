//
//  ContentView.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-05.
//  Copyright © 2020 Michael Long. All rights reserved.
//

import SwiftUI
import CoreData
import AVKit

struct ContentView: View {
    // View that shows list of mixtapes and where user can add a new mixtape
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: MixTape.entity(), sortDescriptors: []) var mixTapes: FetchedResults<MixTape>
    @State private var showingDocsPicker: Bool = false
    @State private var showingNowPlayingSheet: Bool = false
    @State var currentMixTapeImage: URL = URL.init(fileURLWithPath: "")
    @State var currentMixTapeName: String  = ""
    let queuePlayer: AVQueuePlayer
    let playerItemObserver: PlayerItemObserver
    let playerStatusObserver: PlayerStatusObserver
    @ObservedObject var currentPlayerItems: CurrentPlayerItems
    @ObservedObject var currentSongName: CurrentSongName
    @ObservedObject var isPlaying: IsPlaying
    
    var body: some View {
        VStack {
            NavigationView {
                List {ForEach(mixTapes, id:\.wrappedTitle)
                    { tape in
                        NavigationLink(destination:
                            MixTapeView(songs: tape.songsArray, mixTape: tape, currentMixTapeName: self.$currentMixTapeName, currentMixTapeImage: self.$currentMixTapeImage, queuePlayer: self.queuePlayer, currentStatusObserver: self.playerStatusObserver, currentItemObserver: self.playerItemObserver, currentPlayerItems: self.currentPlayerItems, currentSongName: self.currentSongName, isPlaying: self.isPlaying).environment(\.managedObjectContext, self.moc)
                            ){
                                Text(tape.wrappedTitle)
                            }
                     }
                    .onDelete(perform: deleteMixTape)
                }
                .navigationBarTitle("Mixtapes")
                .navigationBarItems(
                    trailing:
                        Button(action: { self.showingDocsPicker.toggle() }) {
                            Image(systemName: "plus").imageScale(.large)
                        }
                        .sheet(isPresented: self.$showingDocsPicker) {
                            NewMixTapeView(isPresented: self.$showingDocsPicker).environment(\.managedObjectContext, self.moc)
                        }
                )
            }
            NowPlayingButtonView(showingNowPlayingSheet: $showingNowPlayingSheet, queuePlayer: self.queuePlayer, currentItemObserver: self.playerItemObserver, currentSongName: self.currentSongName, isPlaying: self.isPlaying)
                .padding([.vertical])
                .sheet(isPresented: self.$showingNowPlayingSheet) {
                
                    PlayerView(currentMixTapeName: self.$currentMixTapeName, currentMixTapeImage: self.$currentMixTapeImage, queuePlayer: self.queuePlayer, playerItemObserver: self.playerItemObserver, playerStatusObserver: self.playerStatusObserver, currentPlayerItems: self.currentPlayerItems, currentSongName: self.currentSongName, isPlaying: self.isPlaying)
                }
        }
    }
    
    func deleteMixTape(offsets: IndexSet) {
        
        for index in offsets {
            let tape = mixTapes[index]
            moc.delete(tape)
        }
        do {
            try moc.save()
        } catch {
            print(error)
        }
    }
}

// MARK: NewMixTapeView

struct NewMixTapeView: View {
    // View that holds a form for user to add a new MixTape
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: MixTape.entity(), sortDescriptors: []) var mixTapes: FetchedResults<MixTape>
    @State var tapeTitle: String = ""
    @State private var showingDocsPicker: Bool = false
    @State private var showingImagePicker: Bool = false
    @State var mixTapePicked: Bool = false
    @State var imagePicked: Bool = false
    @Binding var isPresented: Bool
        
    var inValidName: Bool {
        // mixtape names must be unique to preserve NavigationView functionality
        let bool = mixTapes.contains{ $0.title == tapeTitle }
        return bool
    }

    var body: some View {
        Form {
            Section {
                TextField("Enter Mixtape Name: ", text: $tapeTitle)
            }
            .disabled(mixTapePicked)
            
            
            Section {
                Button(action: { self.showingDocsPicker.toggle() }) {
                     Image(systemName: "folder.badge.plus").imageScale(.large)
                 }
                 .sheet(isPresented: self.$showingDocsPicker) {
                  MixTapePicker(nameofTape: self.tapeTitle, mixTapePicked: self.$mixTapePicked, moc: self.moc)
                 }
            }
            .disabled(tapeTitle.isEmpty || inValidName || mixTapePicked)
            
            Section {
                Button(action: { self.showingImagePicker.toggle() }) {
//                     Image(systemName: "folder.badge.plus").imageScale(.large)
                    Text("Add image")
                 }
                 .sheet(isPresented: self.$showingImagePicker) {
                    ImagePickerView(mixTapes: self.mixTapes, moc: self.moc, imagePicked: self.$imagePicked)
                 }
            }
            .disabled(imagePicked || !mixTapePicked)
            
            Section {
                Button(action: { self.isPresented.toggle() }) {
                    Text("Add Mixtape")
                }
            }
            .disabled(!mixTapePicked)
        }
    }
}

// MARK: NowPlayingButtonView

struct NowPlayingButtonView: View {
    // This View is the button that always stays at the bottom of the screen, displaying the current song's
    // name and a play/pause button. Touching this button opens PlayerView in a sheet.
    
    @Binding var showingNowPlayingSheet: Bool
    let queuePlayer: AVQueuePlayer
    let currentItemObserver: PlayerItemObserver
    @ObservedObject var currentSongName: CurrentSongName
    @ObservedObject var isPlaying: IsPlaying
    
    var body: some View {
        HStack {
            Button(action: {self.showingNowPlayingSheet.toggle()}) {
                HStack() {
                    Button(action: {
                        if self.isPlaying.value{
                        self.queuePlayer.pause()
                        
                    } else {
                        self.queuePlayer.play()
                    }
                    }) {
                        Image(systemName: self.isPlaying.value ? "pause.fill" : "play.fill").imageScale(.large)
                    }
                    Spacer()
                    Text(self.currentSongName.name)
                        .onReceive(currentItemObserver.$currentItem) { item in
                            self.currentSongName.name = getItemName(playerItem: item)
                    }
               }
               .padding()
               .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]), startPoint: .leading, endPoint: .trailing))
               .foregroundColor(Color.white)
           }
        }
    }
}

// MARK: MixTapeView

struct MixTapeView: View {
    // View where user can play songs, edit songs order, and add/delete new songs in the selected mixtape.
    
    @Environment(\.managedObjectContext) var moc
    @State var songs: [Song]
    @State var mixTape: MixTape
    @Binding var currentMixTapeName: String
    @Binding var currentMixTapeImage: URL
    let queuePlayer: AVQueuePlayer
    let currentStatusObserver: PlayerStatusObserver
    let currentItemObserver: PlayerItemObserver
    @ObservedObject var currentPlayerItems: CurrentPlayerItems
    @ObservedObject var currentSongName: CurrentSongName
    @ObservedObject var isPlaying: IsPlaying
    
    @State private var showingDocsPicker = false
    
    
    var body: some View {
        List { ForEach(self.songs, id: \.positionInTape)
                { song in
                                   
                    Button(action: {
                        if self.currentMixTapeName != self.mixTape.wrappedTitle { //update currentMixTapeName
                            self.currentMixTapeName = self.mixTape.wrappedTitle
                            self.currentMixTapeImage = self.mixTape.wrappedUrl
                        }
                        
                        let newPlayerItems = createArrayOfPlayerItems(songs: self.songs) //update currentPlayerItems array
                        if self.currentPlayerItems.items != newPlayerItems {
                            self.currentPlayerItems.items = newPlayerItems
                        }
                        
                        if song == self.songs[0] && self.currentSongName.name == "Not Playing" {
                            loadPlayer(arrayOfPlayerItems: self.currentPlayerItems.items, player: self.queuePlayer)
                            
                        } else if song != self.songs[0] && self.currentSongName.name == "Not Playing" {
                            let index = Int(song.positionInTape)
                            let slicedArray =  self.currentPlayerItems.items[index...self.songs.count - 1]
                            
                            loadPlayer(arrayOfPlayerItems: Array(slicedArray), player: self.queuePlayer)
                            
                        } else if song == self.songs[0] && self.currentSongName.name != "Not Playing" {
                            self.queuePlayer.pause()
                            self.queuePlayer.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
                            
                            loadPlayer(arrayOfPlayerItems: self.currentPlayerItems.items, player: self.queuePlayer)
                            
                        } else if song != self.songs[0] && self.currentSongName.name != "Not Playing" {
                            self.queuePlayer.pause()
                            self.queuePlayer.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
                            
                            let index = Int(song.positionInTape)
                            let slicedArray =  self.currentPlayerItems.items[index...self.songs.count - 1]
                            loadPlayer(arrayOfPlayerItems: Array(slicedArray), player: self.queuePlayer)
                        }
                        self.queuePlayer.play()

                    }) {
                        Text(song.wrappedName)
                            .onReceive(self.currentStatusObserver.$playerStatus)
                                { status in
                                    self.isPlaying.value = getIsPlaying(status: status)
                                }
                        }
                        .disabled(!checkSongUrlIsReachable(song: song))
                        
            }
            .onDelete(perform: deleteSong)
            .onMove(perform: move)
                
            }
            .navigationBarTitle(self.mixTape.wrappedTitle)
            .navigationBarItems(
                trailing:
                    HStack {
                        Button(action: {
                            self.showingDocsPicker.toggle()
                        }) {
                        Image(systemName: "plus").imageScale(.large)
                        }
                        .sheet(isPresented: self.$showingDocsPicker) {
                            MixTapeAdder(moc: self.moc, mixTapeToAddTo: self.mixTape, songs: self.$songs)
                        }
                        Button(action: {}) {
                            EditButton()
                        }
                    }
            )
    }
    
    func move(from source: IndexSet, to destination: Int) {
    // rearange order of songs in mixtape
        
        self.songs.move(fromOffsets: source, toOffset: destination)
        
        // update song's positionInTape property
        var counter: Int16 = 0
        for song in self.songs {
            if song.positionInTape != counter {
                 song.positionInTape = counter
            }
            counter += 1
        }
        
        // notify mixtape of changes to songs
        self.mixTape.willChangeValue(forKey: "songs")
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
    }
    
    func deleteSong(offsets: IndexSet) {
    // Deletes song from a MixTape
        
        for index in offsets {
            let song = self.songs[index]
            moc.delete(song)
            self.songs.remove(at: index)
        }
        
        self.mixTape.numberOfSongs = Int16(self.songs.count)
        
        // update song's positionInTape property
        var counter: Int16 = 0
        for song in self.songs {
            if song.positionInTape != counter {
                   song.positionInTape = counter
            }
            counter += 1
        }
        
        // notify mixtape of changes to songs
        self.mixTape.willChangeValue(forKey: "songs")
        
        do {
            try moc.save()
        } catch {
            print(error)
        }
    }
}

// MARK: PlayerView

struct PlayerView: View {
    // This view appears in a sheet triggerd by the NowPlayingButtonView, it displays name of current song and its mixtape,
    // and controlls for play/pause and skip forward/backward.
    
    @Binding var currentMixTapeName: String
    @Binding var currentMixTapeImage: URL
    let queuePlayer: AVQueuePlayer
    let playerItemObserver: PlayerItemObserver
    let playerStatusObserver: PlayerStatusObserver
    @ObservedObject var currentPlayerItems: CurrentPlayerItems
    @ObservedObject var currentSongName: CurrentSongName
    @ObservedObject var isPlaying: IsPlaying
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                if self.currentMixTapeName != "" {
                    Image(uiImage: getCoverArtImage(url: self.currentMixTapeImage))
                         .resizable()
                         .frame(width: geometry.size.width - 24, height: geometry.size.width - 24)
                         .shadow(radius: 10)

                } else {
                    Image(systemName: "hifispeaker.fill")
                        .resizable()
                        .frame(width: geometry.size.width - 24, height: geometry.size.width - 24)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }

                
                VStack {
                    Text(self.currentSongName.name)
                            .font(Font.system(.title).bold())
                    Text(self.currentMixTapeName)
                        .font(Font.system(.title))
                }
               
                HStack(spacing: 40) {
                    Button(action: { skipBack(currentPlayerItems: self.currentPlayerItems.items, currentSongName: self.currentSongName.name, queuePlayer: self.queuePlayer, isPlaying: self.isPlaying.value) }) {
                        ZStack {
                            Circle()
                                .frame(width: 80, height: 80)
                                .accentColor(.pink)
                                .shadow(radius: 10)
                            Image(systemName: "backward.fill")
                                .foregroundColor(.white)
                                .font(.system(.title))
                        }
                    }

                    Button(action: {
                        if self.isPlaying.value {
                            self.queuePlayer.pause()
                        } else {
                            self.queuePlayer.play()
                        }
                        
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 80, height: 80)
                                .accentColor(.pink)
                                .shadow(radius: 10)
                            Image(systemName: self.isPlaying.value ? "pause.fill" : "play.fill").imageScale(.large)
                                .foregroundColor(.white)
                                .font(.system(.title))
                        }
                    }

                    Button(action: {
                        self.queuePlayer.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
                        self.queuePlayer.advanceToNextItem()
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 80, height: 80)
                                .accentColor(.pink)
                                .shadow(radius: 10)
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .font(.system(.title))
                        }
                    }
                }
            }
        }
    }
}



