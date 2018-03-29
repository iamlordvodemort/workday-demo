//
//  ViewController.swift
//  workday-demo
//
//  Created by Anthony Layne on 3/29/18.
//  Copyright © 2018 Anthony Layne LLC. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class MediaPlayerViewController: UIViewController {

    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    fileprivate var currentMediaItemId: String!
    fileprivate var mediaItems:[String]!
    fileprivate var request: AnyObject?
    fileprivate var playerController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        checkServerStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func play(item: MediaItem) {
        guard let itemURL = URL(string: item.url) else { return }
        let player = AVPlayer(url: itemURL)

        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.status),
                           options: [.new, .initial],
                           context: nil)

        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.currentItem.status),
                           options:[.new, .initial],
                           context: nil)

        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        player.play()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.newErrorLogEntry),
                           name: .AVPlayerItemNewErrorLogEntry,
                           object: player.currentItem)
        center.addObserver(self, selector: #selector(self.failedToPlayToEndTime),
                           name: .AVPlayerItemFailedToPlayToEndTime,
                           object: player.currentItem)
        center.addObserver(self, selector: #selector(self.didfinishplaying),
                           name: .AVPlayerItemDidPlayToEndTime,
                           object: self.playerController.player?.currentItem)
    }

    // Observe If AVPlayerItem.status Changed to Fail
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if let player = object as? AVPlayer,
            keyPath == #keyPath(AVPlayer.currentItem.status) {

            let newStatus: AVPlayerItemStatus
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            if newStatus == .failed {
                print("Error: \(String(describing: player.currentItem?.error?.localizedDescription)), error: \(String(describing: player.currentItem?.error))")
                self.prepareForNextItem()
                self.playNext()
            }
        }
    }

    func prepareForNextItem() {
        NotificationCenter.default.removeObserver(self)
        playerController.player = nil
    }
    
    func playNext() {
        guard let index = mediaItems.index(of: currentMediaItemId) else { return }
        let nextIndex = index + 1
        if mediaItems.indices.contains(nextIndex) {
            let nextItemId = mediaItems[nextIndex]
            currentMediaItemId = nextItemId
            startPlayingMedia(nextItemId)
        } else {
            cleanUp()
        }
    }

    func cleanUp() {
        playerController.removeFromParentViewController()
        playerController.view.removeFromSuperview()
    }
}

//: MARK: - Api Requests

extension MediaPlayerViewController {

    func checkServerStatus() {
        let statusRequest = HealthCheckRequest()
        request = statusRequest
        statusRequest.load { [weak self] (success) in
            if success! {
                self?.fetchItems()
            }
        }
    }

    func fetchItems() {
        let allItemsRequest = FetchAllItemsRequest()
        request = allItemsRequest
        allItemsRequest.load {[weak self]  (items: [String]?) in
            guard let mediaItems = items,
                let firstItem = mediaItems.first else {
                    return
            }
            self?.mediaItems = mediaItems
            self?.currentMediaItemId = firstItem
            self?.startPlayingMedia(firstItem)
        }
    }

    func startPlayingMedia(_ itemId: String) {
        debugPrint("fetching item with id: \(itemId)")
        let resource = MediaResource(id: itemId)
        let mediaItemRequest = ApiRequest(resource: resource)
        request = mediaItemRequest
        mediaItemRequest.load { [weak self] (mediaItems: [MediaItem?]?) in
            guard let items = mediaItems,
                let firstItem = items.first,
                let mediaItem = firstItem else {
                    return
            }
            self?.play(item: mediaItem)
        }
    }
}

//: MARK: - Notification Handlers

extension MediaPlayerViewController {

    // Getting error from Notification payload
    @objc func newErrorLogEntry(_ notification: Notification) {
        guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
            return
        }
        guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
            return
        }
        print("Error: \(errorLog)")
        self.prepareForNextItem()
        self.playNext()
    }

    @objc func failedToPlayToEndTime(_ notification: Notification) {
        let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as! Error
        print("Error: \(error.localizedDescription), error: \(error)")
        self.prepareForNextItem()
        self.playNext()
    }

    @objc func didfinishplaying(_ notification : NSNotification) {
        print("did finish playing media item with id: \(currentMediaItemId)")
        self.prepareForNextItem()
        self.playNext()
    }
}
