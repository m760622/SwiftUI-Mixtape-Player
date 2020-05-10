//
//  PlayerItemOberver.swift
//  Mixtapes
//
//  Created by Michael on 2020-05-05.
//  Copyright © 2020 Michael Long. All rights reserved.
//

import Foundation
import Combine
import AVKit

class PlayerItemObserver {

    @Published var currentItem: AVPlayerItem?
    private var itemObservation: AnyCancellable?

    init(player: AVPlayer) {
    // publishes the current AVPlayerItem in the AVPlayer so it can be updated in the views when the current song changes
        
        itemObservation = player.publisher(for: \.currentItem).sink { item in
            self.currentItem = item
        }
    }
}
