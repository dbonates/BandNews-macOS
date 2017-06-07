//
//  AppDelegate.swift
//  BandNews
//
//  Created by Daniel Bonates on 06/06/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Cocoa

import MediaPlayer
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var isRadioOn = false {
        didSet {
            if isRadioOn {
                player.play()
            } else {
                player.pause()
            }
        }
    }
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let player = AVPlayer()
    
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    var currentStream: Stream?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let icon = NSImage(named: "radio")
        statusItem.image = icon
        statusItem.highlightMode = false
        statusItem.toolTip = "• click to turn on/off\n• alt+click to quit ;)"
        statusItem.action = #selector(printQuote(sender:))
        
        eventMonitor = EventMonitor(mask: .leftMouseDown) { [unowned self] event in
            if self.popover.isShown {
                self.closePopup()
            }
        }
        eventMonitor?.start()
        
        getStreamInfo(for: 3)
    }

    func printQuote(sender: AnyObject) {
        
        
        if let wannaQuit = NSApplication.shared().currentEvent?.modifierFlags.contains(.option), wannaQuit {
            player.pause()
            NSApplication.shared().terminate(self)
            return
        }
        
        if let wannaRadioList = NSApplication.shared().currentEvent?.modifierFlags.contains(.control), wannaRadioList {
            openStationsList()
            return
        }
        
        
        isRadioOn = !isRadioOn
        statusItem.image = isRadioOn ? NSImage(named: "radio-on") : NSImage(named: "radio")
        
    }
    
    func closePopup() {
        popover.close()
        eventMonitor?.stop()
    }

    func openStationsList() {
        
        let url = URL(string: "http://webservice.bandradios.onebrasilmedia.com.br:8087/bandradios-api/retrieve-radio-list")!
        
        DataCache().getRadioList(from: url, completion: { stations in
            guard let stations = stations else { return }
            DispatchQueue.main.async {
                self.showStationsList(with: stations)
            }
        })
    }
    
    func showStationsList(with stations: [Station]) {
        if popover.isShown {
            closePopup()
            return
        }
        
        let sb = NSStoryboard(name: "Main", bundle: nil)
        let stationsViewController = sb.instantiateController(withIdentifier: "RadioListViewController") as! RadioListViewController
//        if let cs = currentStream {
//            stationsViewController.currentStreamId = cs.id
//        }
        stationsViewController.stations = stations
        stationsViewController.delegate = self
        
        if let button = statusItem.button {
            popover.contentViewController = stationsViewController
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    
    func selectRadio(_ station: Station) {
        print("loadURL for id: \(station.id)")
        getStreamInfo(for: station.id)
        closePopup()
        
        
    }
    
    func getStreamInfo(for id: Int) {
        let streamUrlPath = "http://webservice.bandradios.onebrasilmedia.com.br:8087/bandradios-api/retrieve-radio?1=1&rid=\(id)&auc=29E2A48D-BDD2-4589-9710-18A446A19B83"
        
        guard let streamUrl = URL(string: streamUrlPath) else { return }
        
        DataCache().getStreamInfo(for: streamUrl, id: id) { streamInfo in
            guard let streamInfo = streamInfo else { return }
            DispatchQueue.main.async {
                self.setupStream(streamInfo)
            }
        }
    }
    
    func setupStream(_ streamInfo: Stream) {
        
        self.currentStream = streamInfo
        guard let streamUrl = URL(string: streamInfo.path) else { return }
        let newStreamItem = AVPlayerItem(url: streamUrl)
        player.replaceCurrentItem(with: newStreamItem)
        
        if let cs = self.currentStream {
            statusItem.toolTip = "• click to turn on/off\n• alt+click to quit\n• Playing \(cs.name)"
        }
    }
}


